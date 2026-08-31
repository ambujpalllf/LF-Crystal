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

  void takePicture({
    required int siteId,
    required String imageSubTitle,
    required int index,
    required BuildContext context,
  }) async {
    emit(SelfieRefreshState(index: index));
    if (_isPicking) return; // prevent multiple calls
    _isPicking = true;
    try {
      // bool locationPemission = await Utils.checkLoactionPermission();
      // if (!locationPemission) {
      //   if (!context.mounted) return;
      //   Utils.showPermissionDialog(context: context);
      //   return;
      // }
      // bool gpsPemission = await Utils.checkGpsPermission();
      // if (!gpsPemission) {
      //   return;
      // }
      final permission = await CheckLocationPermission.checkPermissionGps(context: context);
      if (!permission) return;

      File? imagePath = await Utils.pickImage(source: ImageSource.camera);
      if (imagePath == null) {
        return;
      }
      final userId = await StorageFunction.readIntData(StorageKey.userId);
      DateTime now = DateTime.now();
      // Position? position = await Utils.getCurrentLocation();
      LocationData position = await CheckLocationPermission.getCurrentLocation();

      // if (position == null) {
      //   return;
      // }
      ImageEntity imageData = ImageEntity(
        imagePath: imagePath.path,
        valueEmpId: userId!,
        siteId: siteId,
        selectedCategoryTitle: "Selfie",
        selectedSubCategoryTitle: imageSubTitle,
        // photoId: now.millisecond,
        photoId: 0,
        serialOrder: 0,
        sync: 0,
        syncSerialOrder: 0,
        moDateTime: now,
        imgLatitude: position.latitude.toString(),
        imgLongitude: position.longitude.toString(),
        imgAccuracy: position.accuracy.toString(),
      );
      emit(SelfiePickedState(selfie: imageData, isProcessed: false, index: index));
      File? newImg = await Utils.compressImageToTargetSize(imagePath, 400);
      if (newImg == null) return;

      // final appDir = await getApplicationDocumentsDirectory();

      // // Compress picked image
      // final cImage = await Utils.compressImageToTargetSize(newImg, 400);
      // if (cImage == null) return;

      // // Parameters sent to isolate for metadata processing
      // final params = {
      //   'imagePath': cImage.path,
      //   'latitude': position.latitude,
      //   'longitude': position.longitude,
      //   'accuracy': position.accuracy,
      //   'imageTitle': "Selfie",
      //   'imageSubTitle': imageSubTitle,
      //   'timestampMillis': now.millisecondsSinceEpoch,
      //   'appDirPath': appDir.path,
      // };

      // // Process metadata in isolate
      // final newPath = await Isolate.run(() => Utils.addMetadataIsolate(params));
      final newPath = await Utils.addMetadataWithCanvas(
        imageFile: imagePath,
        latitude: position.latitude ?? 0.0,
        longitude: position.longitude ?? 0.0,
        accuracy: position.accuracy ?? 0.0,
        timestamp: now,
        imageTitle: "Selfie",
        imageSubTitle: imageSubTitle,
      );

      ImageEntity newImageData = imageData.copyWith(imagePath: newPath.path);
      emit(SelfiePickedState(selfie: newImageData, isProcessed: false, index: index));
      await DBHelper.insertImage(newImageData);
      fetchData(siteId);
      // WorkManagerTaskRegister.selfieSync(imageData: newImageData, timestamp: now, userId: userId);
      WorkManagerTaskRegister.multiImageSync(siteId: siteId);
    } catch (e) {
      String result = e.toString().split(":")[1].trim();
      debugPrint(result);
      emit(SelfieErrorState(result));
    } finally {
      _isPicking = false;
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
