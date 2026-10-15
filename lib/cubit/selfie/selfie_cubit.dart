import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lf_crystal/constants/api_urls.dart';
import 'package:lf_crystal/constants/check_location_permission.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/constants/utils.dart';
import 'package:lf_crystal/cubit/selfie/selfie_state.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/model/image_entity_model.dart';
import 'package:lf_crystal/services/base_client.dart';
import 'package:lf_crystal/services/work_manager_task_register.dart';
import 'package:location/location.dart';

class SelfieCubit extends Cubit<SelfieState> {
  SelfieCubit() : super(SelfieInitState());

  bool _isPicking = false;

  void fetchData(int siteId) async {
    try {
      final response = await DBHelper.getSelfie(siteId);
      emit(SelfieLoadedState(response));
    } catch (e) {
      String result = e.toString().split(":")[1].trim();
      emit(SelfieErrorState(result));
    }
  }

  Future<void> takePicture({
    required int siteId,
    required String imageSubTitle,
    required int index,
    required BuildContext context,
  }) async {
    // Prevent multiple simultaneous calls
    if (_isPicking) {
      debugPrint("Selfie process is already running.");
      return;
    }

    _isPicking = true;

    emit(SelfieRefreshState(index: index));

    try {
      // Check GPS and location permissions
      final permission = await CheckLocationPermission.checkPermissionGps(
        context: context,
      ).timeout(const Duration(seconds: 20));

      if (!permission) {
        debugPrint("Location permission or GPS check failed.");
        return;
      }

      if (!context.mounted) return;

      // Capture selfie
      final File? imagePath = await Utils.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (imagePath == null) {
        debugPrint("Image capture cancelled.");
        return;
      }

      // Get user ID
      final userId = await StorageFunction.readIntData(StorageKey.userId);

      if (userId == null) {
        emit(SelfieErrorState("User ID not found. Please log in again."));
        return;
      }

      final DateTime now = DateTime.now();

      // Get current location with timeout
      final LocationData position = await CheckLocationPermission.getCurrentLocation().timeout(
        const Duration(seconds: 20),
      );

      if (position.latitude == null || position.longitude == null) {
        emit(SelfieErrorState("Unable to get your location. Please enable GPS and try again."));
        return;
      }

      // Compress image
      final File? compressedImage = await Utils.compressImageToTargetSize(imagePath, 400);

      if (compressedImage == null) {
        emit(SelfieErrorState("Unable to compress selfie. Please try again."));
        return;
      }

      // Prepare image entity
      final ImageEntity imageData = ImageEntity(
        imagePath: compressedImage.path,
        valueEmpId: userId,
        siteId: siteId,
        selectedCategoryTitle: "Selfie",
        selectedSubCategoryTitle: imageSubTitle,
        photoId: now.microsecondsSinceEpoch,
        serialOrder: 0,
        sync: 0,
        syncSerialOrder: 0,
        moDateTime: now,
        imgLatitude: position.latitude.toString(),
        imgLongitude: position.longitude.toString(),
        imgAccuracy: position.accuracy?.toString() ?? "",
      );

      emit(SelfiePickedState(selfie: imageData, isProcessed: false, index: index));

      // Add location metadata to the compressed image
      final File newPath = await Utils.addMetadataWithCanvas(
        imageFile: compressedImage,
        latitude: position.latitude!,
        longitude: position.longitude!,
        accuracy: position.accuracy ?? 0.0,
        timestamp: now,
        imageTitle: "Selfie",
        imageSubTitle: imageSubTitle,
      );

      // Update saved image path
      final ImageEntity newImageData = imageData.copyWith(imagePath: newPath.path);

      emit(SelfiePickedState(selfie: newImageData, isProcessed: true, index: index));

      // Save image to database
      await DBHelper.insertImage(newImageData);

      // Refresh data
      fetchData(siteId);

      // Schedule synchronization
      WorkManagerTaskRegister.multiImageSync(siteId: siteId);

      debugPrint("Selfie saved successfully.");
    } catch (e, stackTrace) {
      debugPrint("Selfie error: $e");
      debugPrintStack(stackTrace: stackTrace);

      emit(SelfieErrorState(e.toString()));
    } finally {
      // Always allow the user to retry
      _isPicking = false;
      debugPrint("Selfie process finished. _isPicking = false");
    }
  }

  void deleteImage(int siteId, String imagePath) async {
    try {
      await DBHelper.deleteImageBySiteIdAndPath(siteId, imagePath);
      fetchData(siteId);
    } catch (e) {
      String result = e.toString().split(":")[1].trim();
      emit(SelfieErrorState(result));
    }
  }

  void finalSubmitMethod({required int siteId, required int initId, required int siteEngId}) async {
    try {
      final String msg = await Utils.finalSubmitMethod(siteId: siteId, initId: initId, siteEngId: siteEngId);
      emit(SelfieSuccessState(msg));
    } on Exception catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(SelfieErrorState(errorMsg));
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(SelfieErrorState(errorMsg));
    }
  }

  Future<void> updateSerialOrder({
    required ImageEntity imgData,
    required List<ImageEntity> images,
    required String serialOrder,
  }) async {
    try {
      final url = "${ApiUrls.baseUrl}/${ApiUrls.updateSerialOrder}";
      final int? serialNumber = int.tryParse(serialOrder);

      final payload = {'photoId': imgData.photoId, 'serialNo': serialNumber};

      final response = await ApiServices.postRequestWithAuth(url, payload);

      debugPrint("Response: $response");

      if (response['status']?.toString().toUpperCase() == "OK") {
        final data = response['data'];

        if (data is List && data.isNotEmpty && data.first['ERRSTATUS'] == "Record Updated Successfully") {
          imgData.syncSerialOrder = serialNumber ?? 0;
          imgData.serialOrder = serialNumber ?? 0;
          await DBHelper.updateImage(imgData);
          final index = images.indexWhere((e) => e.photoId == imgData.photoId);

          if (index != -1) {
            images[index] = imgData;
          }

          emit(SelfieLoadedState(List.from(images)));
        } else {
          emit(SelfieErrorState("Failed to update serial order."));
        }
      } else {
        emit(SelfieErrorState(response['message'] ?? "Something went wrong."));
      }
    } catch (e) {
      emit(SelfieErrorState(e.toString()));
    }
  }
}
