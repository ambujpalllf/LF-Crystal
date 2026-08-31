import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/api_urls.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/constants/workmanager_task_key.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/model/image_entity_model.dart';
import 'package:lf_crystal/model/location_model.dart';
import 'package:lf_crystal/services/base_client.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Executing task: $task");
    debugPrint("Executing Input Data: $inputData");

    try {
      if (inputData == null) {
        debugPrint("No input data received for the task.");
        debugPrint("No input data received for the $task $inputData");
        return Future.value(false);
      }

      switch (task) {
        case WorkmanagerTaskKey.selfieSync:
          {
            final DateTime timestamp = DateTime.parse(inputData['timestamp']);
            final int userId = int.parse(inputData['user_id']);

            final imageData = ImageEntity(
              imagePath: inputData['imagePath'],
              valueEmpId: inputData['valueEmpId'],
              siteId: inputData['siteId'],
              selectedCategoryTitle: inputData['selectedCategoryTitle'],
              selectedSubCategoryTitle: inputData['selectedSubCategoryTitle'],
              photoId: inputData['photoId'],
              serialOrder: inputData['serialOrder'],
              sync: inputData['sync'],
              syncSerialOrder: inputData['syncSerialOrder'],
              moDateTime: DateTime.parse(inputData['moDateTime']),
              imgLatitude: inputData['imgLatitude'],
              imgLongitude: inputData['imgLongitude'],
              imgAccuracy: inputData['imgAccuracy'],
            );
            final SendPort? sendF = IsolateNameServer.lookupPortByName('selfie_sync_port');
            sendF?.send(imageData.siteId);
            await singleImageSync(imageData: imageData, timestamp: timestamp, userId: userId);
            final SendPort? send = IsolateNameServer.lookupPortByName('selfie_sync_port');
            send?.send(imageData.siteId);
            final imageListPort = IsolateNameServer.lookupPortByName('image_list_sync_port');
            imageListPort?.send(imageData.siteId);
            break;
          }

        case WorkmanagerTaskKey.multiImageSync:
          {
            final int siteId = int.parse(inputData['user_id']);
            await multiImageSync(siteId: siteId);
            final SendPort? send = IsolateNameServer.lookupPortByName('selfie_sync_port');
            send?.send(siteId);
            final imageListPort = IsolateNameServer.lookupPortByName('image_list_sync_port');
            imageListPort?.send(siteId);
            break;
          }
        case WorkmanagerTaskKey.syncDataToServer:
          {
            final String? surveyDetailString = inputData["surveydetails"];
            if (surveyDetailString != null) {
              final Map<String, dynamic> surveyJson = jsonDecode(surveyDetailString);
              final surveyDetail = SurveyDetail.fromJson(surveyJson);
              await syncDataToServerMehod(surveyDetail);
              break;
            }
          }
        case WorkmanagerTaskKey.syncLocation:
          await syncLocation();
          break;

        default:
          debugPrint("Unknown task: $task");
          return Future.value(false);
      }

      return Future.value(true);
    } catch (e) {
      debugPrint("WorkManager Error: $e");
      debugPrint("WorkManager InputData: $inputData");
      return Future.value(false);
    }
  });
}

Future<void> singleImageSync({required ImageEntity imageData, required DateTime timestamp, required int userId}) async {
  try {
    final String url = "${ApiUrls.baseUrl}/PostUserImage";

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

    debugPrint("Submitting image with data: $bodyData");

    final response = await ApiServices.postSingleMultipartRequestWithAuth(
      fields: bodyData,
      imageFieldName: "file",
      url: url,
      imagesFile: File(imageData.imagePath),
    );

    debugPrint("Server response: $response");

    if (response["resultCode"] == 1) {
      final int photoId =
          response["photoId"] is int ? response["photoId"] : int.tryParse(response["photoId"].toString()) ?? 0;
      final int serialOrder =
          response["serialOrder"] is int
              ? response["serialOrder"]
              : int.tryParse(response["serialOrder"].toString()) ?? 0;
      await DBHelper.updateImage(
        ImageEntity(
          imagePath: imageData.imagePath,
          valueEmpId: userId,
          siteId: imageData.siteId,
          selectedCategoryTitle: imageData.selectedCategoryTitle,
          selectedSubCategoryTitle: imageData.selectedSubCategoryTitle,
          photoId: photoId,
          serialOrder: serialOrder,
          sync: 1,
          syncSerialOrder: serialOrder,
          moDateTime: timestamp,
          imgLatitude: imageData.imgLatitude,
          imgLongitude: imageData.imgLongitude,
          imgAccuracy: imageData.imgAccuracy,
        ),
      );
      // SelfieCubit().fetchData(imageData.siteId);
    }
  } catch (e) {
    e.toString().split(":")[1].trim();
  }
}

Future<void> multiImageSync({required int siteId}) async {
  try {
    List<ImageEntity> imageList = [];
    int? userId = await StorageFunction.readIntData(StorageKey.userId);
    final String url = "${ApiUrls.baseUrl}/PostUserImage";
    if (siteId != 0) {
      final response = await DBHelper.getUnsyncImgBySiteId(siteId);
      imageList.clear();
      imageList = response;
    } else {
      final response = await DBHelper.getAllUnsyncImages();
      imageList.clear();
      imageList = response;
    }
    // List<ImageEntity> unsyncedImages = imageList.where((item) => item.sync == 0).toList();
    String lastSuccessMessage = "";
    for (var item in imageList) {
      final Map<String, String> bodyData = {
        'SITE_ID': "${item.siteId}",
        'CATEGORY_TYPE': item.selectedCategoryTitle,
        'SubCategory': item.selectedSubCategoryTitle,
        'mob_datetime': DateFormat("yyyy-MMM-dd HH:mm:ss.SSS").format(item.moDateTime),
        'image_lat': item.imgLatitude,
        'image_lng': item.imgLongitude,
        'lat_lng_accuracy': item.imgAccuracy,
        'VALUER_EMP_ID': "$userId",
      };

      debugPrint("Submitting image with data: $bodyData");

      final response = await ApiServices.postSingleMultipartRequestWithAuth(
        fields: bodyData,
        imageFieldName: "file",
        url: url,
        imagesFile: File(item.imagePath),
      );
      debugPrint("Server response: $response");

      if (response["resultCode"] == 1) {
        final int photoId =
            response["photoId"] is int ? response["photoId"] : int.tryParse(response["photoId"].toString()) ?? 0;

        final int serialOrder =
            response["serialOrder"] is int
                ? response["serialOrder"]
                : int.tryParse(response["serialOrder"].toString()) ?? 0;
        await DBHelper.updateImage(
          ImageEntity(
            id: item.id,
            imagePath: item.imagePath,
            valueEmpId: userId!,
            siteId: item.siteId,
            selectedCategoryTitle: item.selectedCategoryTitle,
            selectedSubCategoryTitle: item.selectedSubCategoryTitle,
            photoId: photoId,
            serialOrder: serialOrder,
            sync: 1,
            syncSerialOrder: serialOrder,
            moDateTime: item.moDateTime,
            imgLatitude: item.imgLatitude,
            imgLongitude: item.imgLongitude,
            imgAccuracy: item.imgAccuracy,
          ),
        );
        lastSuccessMessage = response["message"];
        debugPrint(lastSuccessMessage);
      }
    }
  } catch (e) {
    e.toString().split(":")[1].trim();
  }
}

Future<void> syncDataToServerMehod(SurveyDetail updatedSurveyDetail) async {
  try {
    String url = "${ApiUrls.baseUrl}/UpdateSiteVisit";
    final Map<String, dynamic> requestBody = {
      "SurveyDetails": [
        {
          "BasicDetails": {
            "address_as_per_site": updatedSurveyDetail.basicDetails?.addressAsPerSite,
            "applicant_name_site": updatedSurveyDetail.basicDetails?.applicantNameSite,
            "appointment_datetime": updatedSurveyDetail.basicDetails?.appointmentDatetime,
            "appointment_remarks": updatedSurveyDetail.basicDetails?.appointmentRemarks,
            "appointment_status": updatedSurveyDetail.basicDetails?.appointmentStatus,
            "bank_id": updatedSurveyDetail.basicDetails?.bankId,
            "bank_name": updatedSurveyDetail.basicDetails?.bankName,
            "case_id": updatedSurveyDetail.basicDetails?.caseId,
            "contact_name": updatedSurveyDetail.basicDetails?.contactName,
            "contact_no": updatedSurveyDetail.basicDetails?.contactNo,
            "init_id": updatedSurveyDetail.basicDetails?.initId,
            "site_eng_accepted": updatedSurveyDetail.basicDetails?.siteEngAccepted,
            "site_engineer_id": updatedSurveyDetail.basicDetails?.siteEngineerId,
            "site_id": updatedSurveyDetail.basicDetails?.siteId,
            "site_reject_reason": updatedSurveyDetail.basicDetails?.siteRejectReason,
            "site_submitted": updatedSurveyDetail.basicDetails?.siteSubmitted,
            "visit_date": updatedSurveyDetail.basicDetails?.visitDate,
          },
          "SiteDetails": {
            "Fields":
                updatedSurveyDetail.siteDetails?.fields
                    ?.map(
                      (field) => {
                        "Label": field.label,
                        "Name": field.name,
                        "Type": field.type,
                        "Value": field.value,
                        "data_type": field.dataType,
                      },
                    )
                    .toList(),
          },
        },
      ],
    };

    final response = await ApiServices.postRequestWithAuth(url, requestBody);
    debugPrint("Url: $url");
    debugPrint("Response data update opencaseform: $response");
  } catch (e) {
    String errorMsg = e.toString().split(":").last;
    throw Exception(errorMsg);
  }
}

Future<void> syncLocation() async {
  try {
    debugPrint("Workmanager: Starting location sync.");
    List<LocationModel>? resultLocation = await DBHelper.getAllLocations();
    debugPrint("********************");
    List<Map<String, dynamic>> locationMaps = resultLocation.map((loc) => loc.toMap()).toList();
    Map<String, dynamic> payload = {"GPSTRACKLIST": locationMaps};
    final response = await ApiServices.postRequestWithAuth(ApiUrls.locationUrl, payload);
    if (response != null) {
      List<dynamic> syncData = response["gpssyncstatuslist"] ?? [];
      if (syncData.isNotEmpty) {
        for (var item in syncData) {
          if (item["resultcode"] == 1) {
            int gpsTrackerId = item["gps_tracker_id"];
            LocationModel? localItem = resultLocation.where((e) => e.gpsTrackerId == gpsTrackerId).firstOrNull;
            if (localItem != null) {
              await DBHelper.deleteLocation(gpsTrackerId: localItem.gpsTrackerId ?? 0);
            }
          }
        }
      }
    }
    debugPrint("work maanger get location: $locationMaps");
    debugPrint("#######################");
  } catch (e) {
    debugPrint("work maanger get location error: $e");
  }
}
