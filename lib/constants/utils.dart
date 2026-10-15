import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/api_urls.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/services/base_client.dart';
// import 'package:location/location.dart' show Location;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Utils {
  static final ImagePicker _picker = ImagePicker();
  // check location permission
  // static Future<bool> checkLoactionPermission() async {
  //   LocationPermission permission;
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     return false;
  //   }
  //   if (permission == LocationPermission.deniedForever) {
  //     debugPrint('Location permissions are permanently denied');
  //     return false;
  //   }
  //   return true;
  // }

  // // check gps permission
  // static Future<bool> checkGpsPermission() async {
  //   bool serviceEnabled;
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     await Location().requestService();

  //     debugPrint('Location services are disabled.');
  //     return false;
  //   }
  //   return true;
  // }

  // // check permission and request
  // static Future<bool> checkLGpsRequestPermission() async {
  //   bool locationPermission = await Utils.checkLoactionPermission();
  //   if (!locationPermission) {
  //     await Geolocator.requestPermission();
  //     locationPermission = await Utils.checkLoactionPermission();
  //     if (!locationPermission) return false;
  //   }
  //   bool gpsPermission = await Utils.checkGpsPermission();
  //   if (!gpsPermission) {
  //     await Location().requestService();
  //     gpsPermission = await Utils.checkGpsPermission();
  //     if (!gpsPermission) return false;
  //   }
  //   return true;
  // }

  // // capture current location
  // static Future<Position?> getCurrentLocation() async {
  //   try {
  //     Position position = await Geolocator.getCurrentPosition(
  //       // ignore: deprecated_member_use
  //       desiredAccuracy: LocationAccuracy.high,
  //     );
  //     return position;
  //   } catch (e) {
  //     debugPrint('Error getting location: $e');
  //     return null;
  //   }
  // }

  // date pick function
  static Future<DateTime?> showCustomDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    DateTime tempSelectedDate = initialDate;

    return showModalBottomSheet<DateTime>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select a Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CalendarDatePicker(
                initialDate: initialDate,
                firstDate: firstDate ?? DateTime(2000),
                lastDate: lastDate ?? DateTime(2100),
                onDateChanged: (newDate) {
                  tempSelectedDate = newDate;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, tempSelectedDate);
                },
                child: const Text("Select"),
              ),
            ],
          ),
        );
      },
    );
  }

  // image picker from gallery or camera
  static Future<File?> pickImage({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      Permission permission;

      if (source == ImageSource.camera) {
        permission = Permission.camera;
      } else {
        permission = Platform.isAndroid ? Permission.storage : Permission.photos;
      }

      var status = await permission.status;
      if (!status.isGranted) {
        status = await permission.request();
        if (!status.isGranted) {
          return null; // user denied permission
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxHeight: 1280,
        maxWidth: 1280,
        imageQuality: 80,
        preferredCameraDevice: preferredCameraDevice,
      );

      //  USER CANCELS → NOT AN ERROR
      if (image == null) {
        return null;
      }

      return File(image.path);
    } on PlatformException catch (e) {
      throw Exception("Failed to access camera or gallery: ${e.message}");
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<List<File>> pickImagesFromGallery() async {
    try {
      //  ANDROID 13+: DO NOT REQUEST PHOTOS PERMISSION
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 33) {
          // REQUEST PHOTOS PERMISSION ANDROID 13--
          final storagePermission = await Permission.storage.request();
          if (!storagePermission.isGranted) {
            return [];
          }
        }
      }

      // iOS still needs permission
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return [];
        }

        if (!status.isGranted && !status.isLimited) {
          return [];
        }
      }

      //  Open picker ONCE
      final List<XFile> images = await _picker.pickMultiImage(limit: 50);

      if (images.isEmpty) return [];

      final tempDir = await getTemporaryDirectory();
      final List<File> files = [];

      for (final xfile in images) {
        final bytes = await xfile.readAsBytes();
        final file = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${xfile.name}');
        await file.writeAsBytes(bytes);
        files.add(file);
      }

      return files;
    } catch (e) {
      return [];
    }
  }

  static Future<File?> compressImageToTargetSize(File file, int targetSizeInBytes) async {
    final tempDir = await getTemporaryDirectory();
    final cleanName = _cleanFileName(file.path);
    final formattedTime = DateFormat('yyyy-MM-dd hh_mm_ss_SSS a').format(DateTime.now());
    final targetPath = p.join(tempDir.path, "${formattedTime}_$cleanName.jpg");

    int quality = 95;
    int compressedSized = targetSizeInBytes * 1024;
    File? result;

    while (quality > 10) {
      var compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minHeight: 1280,
        minWidth: 1280,
      );

      if (compressedFile == null) return null;

      int size = await compressedFile.length();
      debugPrint("Compressed size at quality=$quality: ${(compressedSized / 1024).toStringAsFixed(2)} KB");

      if (size <= compressedSized) {
        result = File(compressedFile.path);
        break;
      }

      // Reduce quality for next iteration
      quality -= 5;
    }

    return result ?? file;
  }

  static String _cleanFileName(String path) {
    final name = p.basenameWithoutExtension(path);

    return name.replaceAll(RegExp(r'(\.(jpe?g|png))+$', caseSensitive: false), '');
  }

  // static Future<File> compressIfNeeded(
  //   File file, {
  //   int maxSizeKB = 400,
  //   int maxWidth = 1280,
  //   int maxHeight = 1280,
  // }) async {
  //   int quality = 90;
  //   Uint8List? result;

  //   while (file.lengthSync() > maxSizeKB * 1024 && quality >= 30) {
  //     result = await FlutterImageCompress.compressWithFile(
  //       file.absolute.path,
  //       quality: quality,
  //       minWidth: maxWidth,
  //       minHeight: maxHeight,
  //       format: CompressFormat.jpeg,
  //     );

  //     if (result == null) break;

  //     file = await file.writeAsBytes(result, flush: true);
  //     quality -= 10;
  //   }

  //   return file;
  // }
  static Future<File> compressIfNeeded(
    File file, {
    int maxSizeKB = 400,
    int maxWidth = 1280,
    int maxHeight = 1280,
  }) async {
    try {
      final originalPath = file.path;

      int quality = 90;
      Uint8List? compressed;

      // Try compressing until size is acceptable
      while (quality >= 30) {
        compressed = await FlutterImageCompress.compressWithFile(
          originalPath,
          quality: quality,
          minWidth: maxWidth,
          minHeight: maxHeight,
          format: CompressFormat.jpeg,
        );

        if (compressed == null) break;

        // check size without writing to disk repeatedly
        final sizeKB = compressed.lengthInBytes / 1024;

        if (sizeKB <= maxSizeKB) {
          break;
        }

        quality -= 10;
      }

      if (compressed == null) return file;

      // Write ONLY ONCE (final output)
      final resultFile = await file.writeAsBytes(compressed, flush: true);

      return resultFile;
    } catch (e) {
      return file;
    }
  }

  static Future<File> addMetadataToImage({
    required File imageFile,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    required String imageTitle,
    required String imageSubTitle,
    String notes = "",
  }) async {
    ///  Read image
    final originalBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(originalBytes);
    if (originalImage == null) return imageFile;

    ///  Prepare metadata text
    // final notesText = (notes != null && notes.trim().isNotEmpty) ? '\n${notes.trim()}' : '';
    final notesText = wrapText(notes);

    final text =
        'Info:\n'
        'Image: $imageSubTitle\n'
        'Lat: ${latitude.toStringAsFixed(5)}\n'
        'Lng: ${longitude.toStringAsFixed(5)}\n'
        'Acc: ${accuracy.toStringAsFixed(1)}m\n'
        'Time: ${DateFormat("dd-MM-yyyy HH:mm a").format(timestamp)}'
        '\n$notesText';

    ///  Font + layout
    final font = img.arial48;
    final textLines = text.split('\n');
    final lineHeight = font.lineHeight;
    final totalTextHeight = lineHeight * textLines.length;
    const leftPadding = 20;
    const bottomPadding = 6;
    final yStart = originalImage.height - totalTextHeight - bottomPadding;

    ///  Calculate background width
    int maxLineWidth = 0;
    for (final line in textLines) {
      int lineWidth = 0;
      for (final codeUnit in line.codeUnits) {
        final ch = font.characters[codeUnit];
        if (ch != null) lineWidth += ch.xAdvance;
      }
      maxLineWidth = maxLineWidth < lineWidth ? lineWidth : maxLineWidth;
    }

    ///  Draw background
    const paddingX = 10;
    const paddingY = 6;
    img.fillRect(
      originalImage,
      x1: leftPadding - paddingX,
      y1: yStart - paddingY,
      x2: leftPadding + maxLineWidth + paddingX,
      y2: yStart + totalTextHeight + paddingY,
      color: img.ColorRgba8(0, 0, 0, 30),
    );

    ///  Draw text
    img.drawString(originalImage, text, font: font, x: leftPadding, y: yStart, color: img.ColorRgb8(255, 255, 255));

    ///  Save image
    final appDir = await getApplicationDocumentsDirectory();
    final safeTitle = imageTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final datePath = DateFormat("dd-MM-yyyy").format(timestamp);
    final folderPath = p.join(appDir.path, safeTitle, datePath);
    await Directory(folderPath).create(recursive: true);
    final formattedTime = DateFormat('yyyy-MM-dd hh_mm_ss_SSS_a').format(timestamp);
    // final fileName = '$imageTitle-$imageSubTitle-${timestamp.millisecondsSinceEpoch}.jpg';
    final fileName = '$imageTitle-$imageSubTitle-$formattedTime.jpg';

    final newPath = p.join(folderPath, fileName);
    File newImageFile = await File(newPath).writeAsBytes(img.encodeJpg(originalImage, quality: 95));

    /// Final size check & compress again if needed
    newImageFile = await compressIfNeeded(newImageFile);

    return newImageFile;
  }

  // static Future<File> addMetadataWithCanvas({
  //   required File imageFile,
  //   required double latitude,
  //   required double longitude,
  //   required double accuracy,
  //   required DateTime timestamp,
  //   required String imageTitle,
  //   required String imageSubTitle,
  //   String notes = "",
  // }) async {
  //   try {
  //     /// 1. Decode + RESIZE to 1280 max
  //     final bytes = await imageFile.readAsBytes();

  //     final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1280, targetHeight: 1280);

  //     final frame = await codec.getNextFrame();
  //     final uiImage = frame.image;

  //     final width = uiImage.width;
  //     final height = uiImage.height;

  //     /// 2. TEXT
  //     final text =
  //         'Info:\n'
  //         'Image: $imageSubTitle\n'
  //         'Lat: ${latitude.toStringAsFixed(5)}\n'
  //         'Lng: ${longitude.toStringAsFixed(5)}\n'
  //         'Acc: ${accuracy.toStringAsFixed(1)}m\n'
  //         'Time: ${DateFormat("dd-MM-yyyy HH:mm a").format(timestamp)}'
  //         '${notes.isNotEmpty ? "\nNotes: $notes" : ""}';

  //     final paragraph =
  //         (ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 36, textAlign: TextAlign.left))
  //               ..pushStyle(ui.TextStyle(color: ui.Color(0xFFFFFFFF)))
  //               ..addText(text))
  //             .build();

  //     paragraph.layout(ui.ParagraphConstraints(width: width - 40));

  //     /// 3. CANVAS
  //     final recorder = ui.PictureRecorder();
  //     final canvas = Canvas(recorder);

  //     canvas.drawImage(uiImage, Offset.zero, Paint());

  //     const paddingX = 20.0;
  //     const paddingY = 10.0;

  //     final rectHeight = paragraph.height + paddingY * 2;

  //     final rect = Rect.fromLTWH(paddingX - 10, height - rectHeight - 20, paragraph.width + 20, rectHeight);

  //     canvas.drawRect(rect, Paint()..color = const Color.fromARGB(45, 0, 0, 0));

  //     canvas.drawParagraph(paragraph, Offset(paddingX, height - paragraph.height - paddingY - 20));

  //     /// 4. RENDER IMAGE
  //     final picture = recorder.endRecording();
  //     final img = await picture.toImage(width, height);

  //     final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

  //     if (pngBytes == null) {
  //       throw Exception("PNG encoding failed");
  //     }

  //     Uint8List imageBytes = pngBytes.buffer.asUint8List();

  //     /// 5. SAVE TEMP FILE
  //     final tempDir = await getTemporaryDirectory();
  //     final tempFile = File(p.join(tempDir.path, "temp_${DateTime.now().millisecondsSinceEpoch}.png"));

  //     await tempFile.writeAsBytes(imageBytes, flush: true);

  //     /// 6. COMPRESS TO ≤ 400KB (IMPORTANT LOOP)
  //     int quality = 90;
  //     Uint8List? compressed;

  //     while (quality >= 40) {
  //       compressed = await FlutterImageCompress.compressWithFile(
  //         tempFile.path,
  //         quality: quality,
  //         minWidth: 1280,
  //         minHeight: 1280,
  //         format: CompressFormat.jpeg,
  //       );

  //       if (compressed == null) break;

  //       final sizeKB = compressed.lengthInBytes / 1024;

  //       if (sizeKB <= 400) {
  //         break;
  //       }

  //       quality -= 10;
  //     }

  //     if (compressed == null) {
  //       throw Exception("Compression failed");
  //     }

  //     /// 7. SAVE FINAL FILE
  //     final appDir = await getApplicationDocumentsDirectory();

  //     final safeTitle = imageTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  //     final datePath = DateFormat("dd-MM-yyyy").format(timestamp);

  //     final folderPath = p.join(appDir.path, safeTitle, datePath);

  //     await Directory(folderPath).create(recursive: true);

  //     final fileName = '$imageTitle-$imageSubTitle-${DateTime.now().millisecondsSinceEpoch}.jpg';

  //     final finalPath = p.join(folderPath, fileName);

  //     final file = File(finalPath);
  //     await file.writeAsBytes(compressed, flush: true);

  //     return file;
  //   } catch (e) {
  //     throw Exception("Error adding metadata: $e");
  //   }
  // }

  static Future<File> addMetadataWithCanvas({
    required File imageFile,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    required String imageTitle,
    required String imageSubTitle,
    String notes = "",
  }) async {
    try {
      /// 1. Decode + resize to max 1280
      final bytes = await imageFile.readAsBytes();

      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1280, targetHeight: 1280);

      final frame = await codec.getNextFrame();
      final uiImage = frame.image;

      final width = uiImage.width;
      final height = uiImage.height;

      /// 2. Build text
      final text =
          'Info:\n'
          'Image: $imageSubTitle\n'
          'Lat: ${latitude.toStringAsFixed(5)}\n'
          'Lng: ${longitude.toStringAsFixed(5)}\n'
          'Acc: ${accuracy.toStringAsFixed(1)}m\n'
          'Time: ${DateFormat("dd-MM-yyyy HH:mm a").format(timestamp)}'
          '${notes.isNotEmpty ? "\nNotes: $notes" : ""}';

      /// 3. Measure real text width (IMPORTANT FIX)
      final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

      double maxLineWidth = 0;

      for (final line in text.split('\n')) {
        textPainter.text = TextSpan(text: line, style: const TextStyle(fontSize: 36, color: Colors.white));

        textPainter.layout();
        if (textPainter.width > maxLineWidth) {
          maxLineWidth = textPainter.width;
        }
      }

      /// 4. Paragraph for rendering
      final paragraph =
          (ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 36, textAlign: TextAlign.left))
                ..pushStyle(ui.TextStyle(color: ui.Color(0xFFFFFFFF)))
                ..addText(text))
              .build();

      paragraph.layout(ui.ParagraphConstraints(width: width - 40));

      /// 5. Canvas setup
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawImage(uiImage, Offset.zero, Paint());

      const paddingX = 20.0;
      const paddingY = 10.0;

      final rectHeight = paragraph.height + paddingY * 2;

      final rect = Rect.fromLTWH(
        paddingX - 10,
        height - rectHeight - 20,
        maxLineWidth + 40, // ✔ FIXED WIDTH BASED ON TEXT
        rectHeight,
      );

      /// 6. Draw background
      canvas.drawRect(rect, Paint()..color = const Color.fromARGB(45, 0, 0, 0));

      /// 7. Draw text
      canvas.drawParagraph(paragraph, Offset(paddingX, height - paragraph.height - paddingY - 20));

      /// 8. Render image
      final picture = recorder.endRecording();
      final img = await picture.toImage(width, height);

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to encode image");
      }

      Uint8List imageBytes = byteData.buffer.asUint8List();

      /// 9. Save temp file (required for compression)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, "temp_${DateTime.now().millisecondsSinceEpoch}.png"));

      await tempFile.writeAsBytes(imageBytes, flush: true);

      /// 10. Compress to ≤ 400 KB
      int quality = 90;
      Uint8List? compressed;

      while (quality >= 40) {
        compressed = await FlutterImageCompress.compressWithFile(
          tempFile.path,
          quality: quality,
          minWidth: 1280,
          minHeight: 1280,
          format: CompressFormat.jpeg,
        );

        if (compressed == null) break;

        final sizeKB = compressed.lengthInBytes / 1024;

        if (sizeKB <= 400) break;

        quality -= 10;
      }

      if (compressed == null) {
        throw Exception("Compression failed");
      }

      /// 11. Save final file
      final appDir = await getApplicationDocumentsDirectory();

      final safeTitle = imageTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final datePath = DateFormat("dd-MM-yyyy").format(timestamp);

      final folderPath = p.join(appDir.path, safeTitle, datePath);

      await Directory(folderPath).create(recursive: true);

      final fileName = '$imageTitle-$imageSubTitle-${DateTime.now().millisecondsSinceEpoch}.jpg';

      final finalPath = p.join(folderPath, fileName);

      final file = File(finalPath);
      await file.writeAsBytes(compressed, flush: true);

      return file;
    } catch (e) {
      throw Exception("Error adding metadata: $e");
    }
  }

  static String wrapText(String text, {int maxCharsPerLine = 30}) {
    final words = text.split(' ');
    final buffer = StringBuffer();
    int lineLength = 0;
    for (var word in words) {
      if (lineLength + word.length + (lineLength > 0 ? 1 : 0) > maxCharsPerLine) {
        buffer.write('\n'); // new line
        lineLength = 0;
      } else if (lineLength > 0) {
        buffer.write(' ');
        lineLength += 1;
      }

      buffer.write(word);
      lineLength += word.length;
    }

    return buffer.toString();
  }

  static Future<String> addMetadataIsolate(Map<String, dynamic> params) async {
    final imagePath = params['imagePath'] as String;
    final latitude = params['latitude'] as double;
    final longitude = params['longitude'] as double;
    final accuracy = params['accuracy'] as double;
    final imageTitle = params['imageTitle'] as String;
    final imageSubTitle = params['imageSubTitle'] as String;
    final timestampMillis = params['timestampMillis'] as int;
    final appDirPath = params['appDirPath'] as String;
    final notes = params['notes'] as String?;
    final file = File(imagePath);
    final originalBytes = await file.readAsBytes();
    final originalImage = img.decodeImage(originalBytes);
    if (originalImage == null) return imagePath;

    final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final bool hasNotes = notes != null && notes.trim().isNotEmpty;

    final String notesText = hasNotes ? '\n${wrapText(notes)}' : '';
    // Prepare metadata text
    final text =
        'Info:\n'
        'Image: $imageSubTitle\n'
        'Lat: ${latitude.toStringAsFixed(5)}\n'
        'Lng: ${longitude.toStringAsFixed(5)}\n'
        'Acc: ${accuracy.toStringAsFixed(1)}m\n'
        'Time: ${DateFormat("dd-MM-yyyy HH:mm a").format(timestamp)}'
        '$notesText';

    final font = img.arial48;
    final textLines = text.split('\n');
    final lineHeight = font.lineHeight;
    final totalTextHeight = lineHeight * textLines.length;

    const leftPadding = 20;
    // const bottomPadding = 10;
    const bottomPadding = 2;
    // const borderThickness = 2;
    final yStart = originalImage.height - totalTextHeight - bottomPadding;

    // final borderColor = img.ColorRgb8(0, 0, 0);
    final textColor = img.ColorRgb8(255, 255, 255);

    int maxLineWidth = 0;
    for (final line in textLines) {
      int currentLineWidth = 0;
      // Iterate through the character code units in the line
      for (final codeUnit in line.codeUnits) {
        // Get the glyph/character information from the font
        final ch = font.characters[codeUnit];
        if (ch != null) {
          // Add the advance distance for the character
          currentLineWidth += ch.xAdvance;
        }
      }
      // Keep track of the longest line
      if (currentLineWidth > maxLineWidth) {
        maxLineWidth = currentLineWidth;
      }
    }

    // Add padding around text
    const paddingX = 10;
    const paddingY = 6;

    // Draw semi-transparent black rectangle behind text
    final rectX = leftPadding - paddingX;
    final rectY = yStart - paddingY;
    // final rectWidth = maxLineWidth + (paddingX * 2);
    final rectWidth = maxLineWidth + (paddingX);
    final rectHeight = totalTextHeight + (paddingY);

    final watermarkColor = img.ColorRgba8(0, 0, 0, 25); // black  opacity
    img.fillRect(
      originalImage,
      x1: rectX,
      y1: rectY,
      x2: (rectX + rectWidth).toInt(),
      y2: rectY + rectHeight,
      color: watermarkColor,
    );

    // Draw the white text on top of the background
    img.drawString(originalImage, text, font: font, x: leftPadding, y: yStart, color: textColor);

    // Use passed directory path instead of calling path_provider
    final safeTitle = imageTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final datePath = DateFormat("dd-MM-yyyy").format(timestamp);
    final folderPath = p.join(appDirPath, safeTitle, datePath);
    await Directory(folderPath).create(recursive: true);
    final formattedTime = DateFormat('yyyy-MM-dd hh_mm_ss_SSS_a').format(timestamp);
    // final fileName = '$imageTitle-$imageSubTitle-$timestampMillis.jpg';
    final fileName = '$imageTitle-$imageSubTitle-$formattedTime.jpg';
    final newPath = p.join(folderPath, fileName);

    // Compression
    int quality = 95;
    List<int> compressedBytes = img.encodeJpg(originalImage, quality: quality);
    const int targetSize = 400 * 1024;
    while (compressedBytes.length > targetSize && quality > 10) {
      quality -= 5;
      compressedBytes = img.encodeJpg(originalImage, quality: quality);
    }
    final newImageFile = File(newPath)..writeAsBytesSync(compressedBytes);
    return newImageFile.path;
  }

  static Future<String> finalSubmitMethod({required int siteId, required int initId, required int siteEngId}) async {
    try {
      final String url = "${ApiUrls.baseUrl}/UpdateStatus";
      final userId = await StorageFunction.readIntData(StorageKey.userId);
      final selfieData = await DBHelper.getImagesBySiteId(siteId);
      final selfieImages = selfieData.where((item) => item.selectedCategoryTitle == "Selfie").toList();
      final unSyncImg = selfieData.where((i) => i.sync == 0).toList();
      if (selfieImages.isEmpty) {
        throw Exception("At least one selfie is required.");
      } else if (unSyncImg.isNotEmpty) {
        throw Exception("Please sync all images, before Final Submit.");
      }
      bool foundSurvey = false;
      bool hasUnfilledMandatory = false;
      Map<String, dynamic>? updatedFieldJsonStr;
      dynamic updatedHomeData;
      final resultData = await DBHelper.getAllHomeData();
      for (var homeData in resultData) {
        for (var survey in homeData.surveyDetails!) {
          if (survey.basicDetails?.siteId == siteId) {
            foundSurvey = true;

            for (var field in survey.siteDetails!.fields!) {
              if (field.isMandatory == true && (field.value == null || field.value.toString().trim().isEmpty)) {
                hasUnfilledMandatory = true;
                break;
              }
            }

            if (hasUnfilledMandatory) {
              throw Exception("Please Enter all the (*) mark required details, before Final Submit.");
            }

            // Update values in memory only
            survey.basicDetails?.siteEngAccepted = 3;
            survey.basicDetails?.siteSubmitted = 1;
            survey.basicDetails?.visitDate = DateFormat('d MMM yyyy hh:mm:ss').format(DateTime.now());

            updatedFieldJsonStr = survey.toJson();
            updatedHomeData = homeData;
            break;
          }
        }
        if (foundSurvey) break;
      }
      if (!foundSurvey) {
        throw Exception("Survey data not found for site ID $siteId");
      }
      final Map<String, dynamic> jsonStrPayload = {
        "site_id": siteId,
        "init_id": initId,
        "site_engineer_id": siteEngId,
        "created_by": userId,
        "fieldJsonStr": updatedFieldJsonStr,
      };
      final Map<String, dynamic> bodyData = {"lookup": "SITE_ENG_FINAL_SUBMIT", "json_str": jsonEncode(jsonStrPayload)};
      final response = await ApiServices.postRequestWithAuth(url, bodyData);
      Utils.logFullText("Response data: $response");
      Utils.logFullText("Body submitted data: ${jsonEncode(bodyData)}");
      if (response["status"] == "OK") {
        // Update local database only after successful API response
        await DBHelper.updateHomeData(updatedHomeData);
        return response["data"][0]["message"];
      } else {
        throw Exception(response["message"] ?? "Survey submission failed");
      }
    } catch (e) {
      String errorMsg = e.toString().split(":").last.trim();
      throw Exception(errorMsg);
    }
  }

  static void logFullText(String text) {
    const int chunkSize = 800;
    for (var i = 0; i < text.length; i += chunkSize) {
      if (kDebugMode) {
        print(text.substring(i, i + chunkSize > text.length ? text.length : i + chunkSize));
      }
    }
  }
}
