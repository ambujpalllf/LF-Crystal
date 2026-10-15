import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/api_urls.dart';
import 'package:lf_crystal/constants/dialogue_helper.dart';
import 'package:lf_crystal/constants/check_location_permission.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/constants/utils.dart';
import 'package:lf_crystal/cubit/photo/photo_state.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/model/image_entity_model.dart';
import 'package:lf_crystal/model/photo_category_model.dart';
import 'package:lf_crystal/services/base_client.dart';
import 'package:lf_crystal/services/work_manager_task_register.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';

class PhotoCubit extends Cubit<PhotoState> {
  PhotoCubit() : super(PhotoInitState());
  bool _isPicking = false;

  Future<void> fetchCategoryData() async {
    emit(PhotoLoadingState());

    try {
      bool? isDownloaded = await StorageFunction.readBoolData(StorageKey.isCategoryDownload) ?? false;

      if (isDownloaded == true) {
        final localData = await DBHelper.getCategories();
        if (localData.isNotEmpty) {
          final localModel = PhotoCategoryResponse(data: localData);
          emit(PhotoLoadedState(photoCategoryResponse: localModel, subcategory: []));
        }
      } else {
        String url = "${ApiUrls.baseUrl}/GetPhotoCategory";
        final response = await ApiServices.getRequestWithAuth(url);
        final responseJson = PhotoCategoryResponse.fromJson(response);
        await DBHelper.insertCategory(responseJson.data!);
        await StorageFunction.writeBoolData(StorageKey.isCategoryDownload, true);
        emit(PhotoLoadedState(photoCategoryResponse: responseJson, subcategory: []));
      }
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(PhotoErrorState(errorMsg));
      emit(StopLoadingState());
    }
  }

  bool categoryValidation(String category) {
    if (category.isEmpty) {
      emit(PhotoCategoryErrorState("Category Requred"));
      return false;
    }
    return true;
  }

  void addCategory({required String category, required List<String> categoryList}) async {
    try {
      emit(PhotoLoadingState());
      if (categoryList.contains(category)) {
        emit(PhotoErrorState("This category already exists."));
        return;
      }
      await DBHelper.insertCategory([
        CategoryDatum(categoryType: category, subCategory: [SubCategory(subCategoryType: category)]),
      ]);
      final localData = await DBHelper.getCategories();
      if (localData.isNotEmpty) {
        final localModel = PhotoCategoryResponse(data: localData);
        emit(PhotoLoadedState(photoCategoryResponse: localModel, subcategory: []));
        // When the user adds a new category, select it automatically.
        selectDropdown(category);
      }
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(PhotoErrorState(errorMsg));
    }
  }

  void selectDropdown(String categoryType) async {
    final localData = await DBHelper.getCategories();

    if (localData.isNotEmpty) {
      final matchedCategory = localData.firstWhere(
        (element) => element.categoryType == categoryType,
        orElse: () => CategoryDatum(categoryType: categoryType, subCategory: []),
      );
      final localModel = PhotoCategoryResponse(data: localData);

      final subcategories = matchedCategory.subCategory ?? [];
      emit(PhotoLoadedState(photoCategoryResponse: localModel, subcategory: subcategories, initialValue: categoryType));
    }
  }

  void takePicture({
    required int siteId,
    required String imageTitle,
    required String imageSubTitle,
    required BuildContext context,
    required int bankId,
    required String applicantName,
  }) async {
    if (_isPicking) return; // Prevent multiple requests while the current image is being processed.
    _isPicking = true;
    try {
      if (!context.mounted) return;
      final permission = await CheckLocationPermission.checkPermissionGps(context: context);
      if (!permission) return;
      String imgType = imageTitle.trim().toLowerCase();
      File? imagePath = await Utils.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: imgType == "selfie" ? CameraDevice.front : CameraDevice.rear,
      );
      if (imagePath == null) {
        return;
      }
      String notes = "";
      if (bankId == 32) {
        if (!context.mounted) return;
        String? result = await DialogueHelper.showAddDialog(
          context: context,
          applicantName: applicantName,
          imageSubtitle: imageSubTitle,
        );
        if (result != null) {
          notes = result;
        }
      }
      final userId = await StorageFunction.readIntData(StorageKey.userId);
      DateTime now = DateTime.now();
      ImageEntity imageData = ImageEntity(
        imagePath: imagePath.path,
        valueEmpId: userId!,
        siteId: siteId,
        selectedCategoryTitle: imageTitle,
        selectedSubCategoryTitle: imageSubTitle,
        // photoId: now.millisecond,
        photoId: 0,
        serialOrder: 0,
        sync: 0,
        syncSerialOrder: 0,
        moDateTime: now,
        imgLatitude: "",
        imgLongitude: "",
        imgAccuracy: "",
      );
      await DBHelper.insertImage(imageData);
      final imageListPortFirst = IsolateNameServer.lookupPortByName('image_list_sync_port');
      imageListPortFirst?.send(imageData.siteId);

      // Position? position = await Utils.getCurrentLocation();
      LocationData position = await CheckLocationPermission.getCurrentLocation();
      // if (position == null) return;
      ImageEntity? oldImgData = await DBHelper.getImgByPath(siteId: siteId, imgPath: imagePath.path);
      if (oldImgData == null) return;
      // final metaImg = await Utils.addMetadataToImage(
      //   imageFile: imagePath,
      //   latitude: position.latitude ?? 0.0,
      //   longitude: position.longitude ?? 0.0,
      //   accuracy: position.accuracy ?? 0.0,
      //   timestamp: now,
      //   imageTitle: imageTitle,
      //   imageSubTitle: imageSubTitle,
      //   notes: notes,
      // );

      final metaImg = await Utils.addMetadataWithCanvas(
        imageFile: imagePath,
        latitude: position.latitude ?? 0.0,
        longitude: position.longitude ?? 0.0,
        accuracy: position.accuracy ?? 0.0,
        timestamp: now,
        imageTitle: imageTitle,
        imageSubTitle: imageSubTitle,
        notes: notes,
      );
      // final appDir = await getApplicationDocumentsDirectory();
      // final params = {
      //   'imagePath': imagePath.path,
      //   'latitude': position.latitude,
      //   'longitude': position.longitude,
      //   'accuracy': position.accuracy,
      //   'imageTitle': imageTitle,
      //   'imageSubTitle': imageSubTitle,
      //   'timestampMillis': now.millisecondsSinceEpoch,
      //   'appDirPath': appDir.path,
      //   'notes': notes,
      // };
      // final metaImg = await Isolate.run(() => Utils.addMetadataIsolate(params));
      _isPicking = false;
      oldImgData.imagePath = metaImg.path;
      // oldImgData.imagePath = metaImg;
      oldImgData.imgLatitude = "${position.latitude}";
      oldImgData.imgLongitude = "${position.longitude}";
      oldImgData.imgAccuracy = "${position.accuracy}";
      await DBHelper.updateImage(oldImgData);
      final imageListPortS = IsolateNameServer.lookupPortByName('image_list_sync_port');
      imageListPortS?.send(imageData.siteId);
      WorkManagerTaskRegister.multiImageSync(siteId: siteId);
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      debugPrint("Error $imageSubTitle : $e");
      emit(PhotoErrorState(errorMsg));
    } finally {
      _isPicking = false;
    }
  }

  String _safeFileName(String input) {
    return input.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_').toLowerCase();
  }

  Future<void> takePictureFromGallery(int siteId, String imageTitle, String imageSubTitle) async {
    if (_isPicking) return; // prevent multiple calls
    _isPicking = true;
    try {
      final List<File> response = await Utils.pickImagesFromGallery();
      if (response.isEmpty) {
        return;
      }
      final userId = await StorageFunction.readIntData(StorageKey.userId);
      if (userId == null) {
        return;
      }
      // Get application directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      // Sanitize directory names
      final String safeTitle = _safeFileName(imageTitle);
      final String safeSubTitle = _safeFileName(imageSubTitle);
      // Create destination directory
      final String newDirPath = '${appDir.path}/images/$safeTitle/$safeSubTitle';
      final Directory newDir = Directory(newDirPath);
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
      }
      // Process every selected image individually
      for (int i = 0; i < response.length; i++) {
        try {
          final File originalImage = response[i];
          // Compress the current image
          final File compressedImage = await Utils.compressIfNeeded(originalImage);

          // Generate a unique filename for this image
          final DateTime imageTime = DateTime.now();
          final String formattedTime = DateFormat('yyyy-MM-dd hh_mm_ss_SSS a').format(imageTime);
          final String fileName = '${safeTitle}_${safeSubTitle}_$formattedTime.jpg';
          final String destinationPath = '$newDirPath/$fileName';
          // Copy the current image to its permanent location
          final File newImage = await compressedImage.copy(destinationPath);
          // Create database entity
          final ImageEntity imageData = ImageEntity(
            imagePath: newImage.path,
            valueEmpId: userId,
            siteId: siteId,
            selectedCategoryTitle: imageTitle,
            selectedSubCategoryTitle: imageSubTitle,
            photoId: imageTime.microsecondsSinceEpoch,
            serialOrder: i,
            sync: 0,
            syncSerialOrder: 0,
            moDateTime: imageTime,
            imgLatitude: "",
            imgLongitude: "",
            imgAccuracy: "",
          );
          // Insert image into database
          await DBHelper.insertImage(imageData);
        } catch (e, stackTrace) {
          debugPrintStack(stackTrace: stackTrace);
        }
      } // Schedule synchronization after processing all images
      WorkManagerTaskRegister.multiImageSync(siteId: siteId);
    } catch (e, stackTrace) {
      debugPrint("Gallery image error: $e");
      debugPrintStack(stackTrace: stackTrace);
      final String errorMsg = e.toString().split(":").last.trim();
      emit(PhotoErrorState(errorMsg));
    } finally {
      _isPicking = false;
    }
  }

  void finalSubmitMethod({required int siteId, required int initId, required int siteEngId}) async {
    try {
      final String msg = await Utils.finalSubmitMethod(siteId: siteId, initId: initId, siteEngId: siteEngId);
      emit(PhotoSuccessState(msg));
    } on Exception catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(PhotoErrorState(errorMsg));
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(PhotoErrorState(errorMsg));
    }
  }
}
