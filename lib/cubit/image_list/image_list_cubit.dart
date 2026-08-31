import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/api_urls.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/cubit/image_list/image_list_state.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/model/image_entity_model.dart';
import 'package:lf_crystal/services/base_client.dart';
import 'package:lf_crystal/services/work_manager_task_register.dart';

class ImageListCubit extends Cubit<ImageListState> {
  ImageListCubit() : super(ImageListInitState());

  List<ImageEntity> imageList = [];

  void fetchData(int siteId) async {
    emit(ImageListLoadingState());
    try {
      if (siteId != 0) {
        final response = await DBHelper.getImagesBySiteId(siteId);
        imageList = response;
        emit(ImageListLoadedState(response));
      } else {
        final response = await DBHelper.getAllImages();
        imageList = response;
        emit(ImageListLoadedState(response));
      }
    } catch (e) {
      emit(ImageListErrorState("$e"));
    }
  }

  void deleteImage({required int siteId, required int imgId}) async {
    try {
      await DBHelper.deleteImageById(imgId);
      fetchData(siteId);
    } catch (e) {
      emit(ImageListErrorState("Error $e"));
    }
  }

  Future<void> refreshImageSync(int siteId, ImageEntity imageData) async {
    try {
      DateTime timestamp = DateTime.now();
      int? userId = await StorageFunction.readIntData(StorageKey.userId);
      final String url = "${ApiUrls.baseUrl}/PostUserImage";
      emit(ImageListSuccesState("Image is syncing..."));
      final Map<String, String> bodyData = {
        'SITE_ID': imageData.siteId.toString(),
        'CATEGORY_TYPE': imageData.selectedCategoryTitle,
        'SubCategory': imageData.selectedSubCategoryTitle,
        'mob_datetime': DateFormat("yyyy-MMM-dd HH:mm:ss.SSS").format(timestamp),
        'image_lat': imageData.imgLatitude,
        'image_lng': imageData.imgLongitude,
        'lat_lng_accuracy': imageData.imgAccuracy,
        'VALUER_EMP_ID': userId.toString(),
      };

      final response = await ApiServices.postSingleMultipartRequestWithAuth(
        fields: bodyData,
        imageFieldName: "file",
        url: url,
        imagesFile: File(imageData.imagePath),
      );

      debugPrint("Server response: $response");

      if (response["resultCode"] == 1) {
        await DBHelper.updateImage(
          ImageEntity(
            imagePath: imageData.imagePath,
            valueEmpId: userId!,
            siteId: imageData.siteId,
            selectedCategoryTitle: imageData.selectedCategoryTitle,
            selectedSubCategoryTitle: imageData.selectedSubCategoryTitle,
            photoId: timestamp.millisecond,
            serialOrder: 0,
            sync: 1,
            syncSerialOrder: 0,
            moDateTime: timestamp,
            imgLatitude: imageData.imgLatitude,
            imgLongitude: imageData.imgLongitude,
            imgAccuracy: imageData.imgAccuracy,
          ),
        );
        emit(ImageListSuccesState(response["message"]));
        fetchData(siteId);
      }
    } catch (e) {
      String result = e.toString().split(":")[1].trim();
      emit(ImageListErrorState(result));
    }
  }

  Future<void> submitMultiImage(int siteId) async {
    try {
      // fetchData(siteId);
      WorkManagerTaskRegister.multiImageSync(siteId: siteId);
      emit(ImageListSuccesState("Images are syncing..."));
    } catch (e) {
      String result = e.toString().split(":")[1].trim();
      emit(ImageListErrorState(result));
    }
  }

  Future<void> updateSerialOrder({required ImageEntity imgData, required String serialOrder}) async {
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
          final index = imageList.indexWhere((e) => e.photoId == imgData.photoId);

          if (index != -1) {
            imageList[index] = imgData;
          }

          emit(ImageListLoadedState(List.from(imageList)));
        } else {
          emit(ImageListErrorState("Failed to update serial order."));
        }
      } else {
        emit(ImageListErrorState(response['message'] ?? "Something went wrong."));
      }
    } catch (e) {
      emit(ImageListErrorState(e.toString()));
    }
  }
}
