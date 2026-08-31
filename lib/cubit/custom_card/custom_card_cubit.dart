import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/api_urls.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/cubit/custom_card/custom_card_state.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/model/image_entity_model.dart';
import 'package:lf_crystal/services/base_client.dart';

class CustomCardCubit extends Cubit<CustomCardState> {
  CustomCardCubit() : super(CustomCardInitState());
  List<ImageEntity> imageDataList = [];
  List<BasicDetails> basicDetailsList = [];

  Future<void> fetchDataWithDB() async {
    emit(CustomCardLoadingState());

    try {
      final responseData = await DBHelper.getAllHomeData();
      if (responseData.isEmpty) {
        // emit(CustomCardErrorState("No local data available."));
        emit(CustomCardStopLoadingState());
        return;
      }
      List<BasicDetails> basicDetails = [];
      for (var homeData in responseData) {
        for (var item in homeData.surveyDetails!) {
          basicDetails.add(item.basicDetails!);
        }
      }
      final response = await DBHelper.getAllImages();
      basicDetailsList = basicDetails;
      imageDataList = response;
      emit(CustomCardDownloadedState(basicDetails, response));
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(CustomCardErrorState(errorMsg));
      emit(CustomCardStopLoadingState());
    }
  }

  void deleteData(int siteId) async {
    try {
      final storedSiteId = await StorageFunction.readStringData(StorageKey.siteIds) ?? "";
      List<int> siteIdList =
          storedSiteId
              .split(',')
              .where((id) => id.trim().isNotEmpty)
              .map((id) => int.tryParse(id) ?? -1)
              .where((id) => id != -1 && id != siteId)
              .toList();
      final updatedSiteIds = siteIdList.join(',');
      await StorageFunction.writeStringData(StorageKey.siteIds, updatedSiteIds);
      await DBHelper.deleteBasicDetailsBySiteId(siteId);
      await DBHelper.deleteImageBySiteId(siteId);
      fetchDataWithDB();
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(CustomCardErrorState(errorMsg));
    }
  }

  Future<void> imageSync(List<ImageEntity> imageDataList) async {
    emit(CustomCardSyncState("Images are syncing..."));
    fetchDataWithDB();
    try {
      DateTime timestamp = DateTime.now();
      final userId = await StorageFunction.readIntData(StorageKey.userId);

      final String url = "${ApiUrls.baseUrl}/PostUserImage";
      for (int i = 0; i < imageDataList.length; i++) {
        var imageData = imageDataList[i];
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
        }
      }
      emit(CustomCardSuccessState("Images synced successfully."));
      fetchDataWithDB();
    } catch (e) {
      fetchDataWithDB();
      String errorMsg = e.toString().split(":").last;
      emit(CustomCardErrorState(errorMsg));
    }
  }

  String normalize(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' '); // normalize spaces
  }

  void searchData(String searchText) {
    final query = normalize(searchText);

    if (query.isEmpty) {
      fetchDataWithDB();
      return;
    }

    final filtered =
        basicDetailsList.where((item) {
          final bankName = normalize(item.bankName ?? "");
          final applicantName = normalize(item.applicantNameSite ?? "");
          final siteAddress = normalize(item.addressAsPerSite ?? "");

          final isBankMatch = bankName.contains(query);
          final isApplicantMatch = applicantName.contains(query);
          final isAddressMatch = siteAddress.contains(query);

          return isBankMatch || isApplicantMatch || isAddressMatch;
        }).toList();

    emit(CustomCardDownloadedState(filtered, imageDataList));
  }

  void applyFilter(Map<String, dynamic> filterData, int tabIndex) {
    String filterBank = (filterData["bankName"] ?? "").toLowerCase().trim();

    final filteredList =
        basicDetailsList.where((item) {
          final itemBank = item.bankName?.toLowerCase().trim();

          // Filter by Bank Name
          if (filterBank.isNotEmpty && !(itemBank?.contains(filterBank) ?? false)) {
            return false;
          }

          // Filter by Today's Appointment
          if (filterData["appointment"] == true) {
            final appointmentDate = _parseDate(item.appointmentDatetime);
            final now = DateTime.now();
            if (appointmentDate == null ||
                appointmentDate.year != now.year ||
                appointmentDate.month != now.month ||
                appointmentDate.day != now.day) {
              return false;
            }
          }

          // Filter by Visit Date Range
          final visitDate = _parseDate(item.visitDate);
          if (visitDate != null) {
            if (filterData["fromDate"] != null && visitDate.isBefore(filterData["fromDate"])) {
              return false;
            }
            if (filterData["toDate"] != null && visitDate.isAfter(filterData["toDate"])) {
              return false;
            }
          }

          return true;
        }).toList();

    // Sort the filtered list
    filteredList.sort((a, b) {
      DateTime? dateA = _parseDate(a.appointmentDatetime);
      DateTime? dateB = _parseDate(b.appointmentDatetime);
      DateTime? visitDateA = _parseDate(a.visitDate);
      DateTime? visitDateB = _parseDate(b.visitDate);
      switch (filterData["sortBy"]) {
        case 'Appointment DateWise Old to Latest':
          if (dateA != null && dateB != null) {
            return dateA.compareTo(dateB);
          }
          break;
        case 'Appointment DateWise Latest to Old':
          if (dateA != null && dateB != null) {
            return dateB.compareTo(dateA);
          }
          break;
        case 'Assign Case DateWise Old to Latest':
          return (a.siteId ?? 0).compareTo(b.siteId ?? 0); // Ascending
        case 'Assign Case DateWise Latest to Old':
          return (b.siteId ?? 0).compareTo(a.siteId ?? 0); // Descending
        case 'Completed Case DateWise Old to Latest':
          if (visitDateA != null && visitDateB != null && tabIndex != 0) {
            debugPrint("KKKKKKKKKKKKKKKKKKKKKKKKKKKK: $tabIndex");
            return visitDateB.compareTo(visitDateA);
          }
          break;
        case 'Completed Case DateWise Latest to Old':
          if (visitDateA != null && visitDateB != null && tabIndex != 0) {
            return visitDateA.compareTo(visitDateB);
          }
          break;
      }

      if (filterData["sortBy"].contains('Completed Case') && tabIndex == 0) {
        return 0; // No sorting applied
      }

      final dA = dateA ?? DateTime(1900);
      final dB = dateB ?? DateTime(1900);

      if (filterData["sortBy"].contains('Latest to Old') == true) {
        return dB.compareTo(dA); // Descending
      } else {
        return dA.compareTo(dB); // Ascending
      }
    });
    emit(CustomCardDownloadedState(filteredList, imageDataList));
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    final formats = [
      'yyyy-MM-ddTHH:mm:ss',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'yyyy-MMM-dd hh:mm:ss:a',
      'yyyy-MMMM-dd hh:mm:ss:a',
      'dd MMM yyyy',
    ];

    for (var pattern in formats) {
      try {
        return DateFormat(pattern).parseStrict(dateStr);
      } catch (e) {
        // Continue to next format
      }
    }
    return null;
  }

  void rejectMethod({
    required int siteId,
    required int initId,
    required int siteEngineerId,
    required String reason,
  }) async {
    try {
      String url = "${ApiUrls.baseUrl}/UpdateStatus";
      final userId = await StorageFunction.readIntData(StorageKey.userId);
      final Map<String, dynamic> jsonStrPayload = {
        "site_id": siteId,
        "init_id": initId,
        "site_engineer_id": siteEngineerId,
        "created_by": userId,
        "reject_reason": reason,
      };

      final Map<String, dynamic> bodyData = {"lookup": "SITE_ENG_REJECT", "json_str": jsonEncode(jsonStrPayload)};
      final response = await ApiServices.postRequestWithAuth(url, bodyData);
      if (response["status"] == "OK") {
        emit(CustomCardSuccessState("${response["data"][0]["message"]}"));
        deleteData(siteId);
      } else {
        emit(CustomCardErrorState(response["message"]));
        fetchDataWithDB();
      }
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(CustomCardErrorState(errorMsg));
      fetchDataWithDB();
    }
  }

  void acceptMethod({
    required int siteId,
    required int initId,
    required int siteEngId,
    required BasicDetails basicDetails,
  }) async {
    try {
      String url = "${ApiUrls.baseUrl}/UpdateStatus";
      final userId = await StorageFunction.readIntData(StorageKey.userId);
      final Map<String, dynamic> jsonStrPayload = {
        "site_id": siteId,
        "init_id": initId,
        "site_engineer_id": siteEngId,
        "created_by": userId,
        "fieldJsonStr": basicDetails.toJson(),
      };

      final Map<String, dynamic> bodyData = {"lookup": "SITE_ENG_ACCEPT", "json_str": jsonEncode(jsonStrPayload)};

      final response = await ApiServices.postRequestWithAuth(url, bodyData);

      if (response["status"] == "OK") {
        basicDetails.siteEngAccepted = 2;
        await DBHelper.updateBasicDetailsBySiteId(siteId, basicDetails);
        emit(CustomCardSuccessState("${response["data"][0]["message"]}"));
        final index = basicDetailsList.indexWhere((e) => e.siteId == siteId);

        if (index != -1) {
          basicDetailsList[index] = basicDetails;
        }
        emit(
          CustomCardDownloadedState(List<BasicDetails>.from(basicDetailsList), List<ImageEntity>.from(imageDataList)),
        );

        // fetchDataWithDB();
      } else {
        emit(CustomCardErrorState(response["message"]));
      }
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(CustomCardErrorState(errorMsg));
    }
  }

  void fixAppointmentMethod({
    required String date,
    required String time,
    required int siteId,
    required int initId,
    required int siteEngineerId,
    required BasicDetails basicDetails,
  }) async {
    try {
      final userId = await StorageFunction.readIntData(StorageKey.userId);
      if (userId == null) {
        emit(CustomCardErrorState("User ID not found."));
        return;
      }
      String dateTimeInput = "$date $time";
      DateTime parsedDateTime = DateFormat("yyyy-MM-dd hh:mm a").parse(dateTimeInput);
      String formattedDateTime = DateFormat("yyyy-MMM-dd HH:mm:ss.SSS").format(parsedDateTime);
      debugPrint("Formatted DateTime: $formattedDateTime");
      final Map<String, dynamic> jsonStrPayload = {
        "site_id": siteId,
        "init_id": initId,
        "site_engineer_id": siteEngineerId,
        "created_by": userId,
        "appointment_remarks": "",
        "appointment_datetime": formattedDateTime,
        "appointment_status": 6,
      };

      final Map<String, dynamic> bodyData = {"lookup": "FIX_APPOINTMENT", "json_str": jsonEncode(jsonStrPayload)};

      debugPrint("Final Payload: $bodyData");
      final response = await ApiServices.postRequestWithAuth("${ApiUrls.baseUrl}/UpdateStatus", bodyData);
      if (response["status"] == "OK") {
        basicDetails.appointmentStatus = 6;
        await DBHelper.updateBasicDetailsBySiteId(siteId, basicDetails);
        final message = response["data"]?[0]["message"];
        emit(CustomCardSuccessState(message));
        final index = basicDetailsList.indexWhere((e) => e.siteId == siteId);

        if (index != -1) {
          basicDetailsList[index] = basicDetails;
        }
        emit(
          CustomCardDownloadedState(List<BasicDetails>.from(basicDetailsList), List<ImageEntity>.from(imageDataList)),
        );
        // fetchDataWithDB();
      } else {
        emit(CustomCardErrorState(response["message"]));
        fetchDataWithDB();
      }
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(CustomCardErrorState(errorMsg));
    }
  }

  void changeAppointment({
    required String dates,
    required String times,
    required int siteId,
    required int initId,
    required int siteEngId,
    required String remarks,
    required BasicDetails basicDetails,
  }) async {
    try {
      String url = "${ApiUrls.baseUrl}/UpdateStatus";
      final userId = await StorageFunction.readIntData(StorageKey.userId);
      String dateTime = "$dates $times";
      DateTime parsedDateTime = DateFormat("yyyy-MM-dd hh:mm a").parse(dateTime);
      String formatted = DateFormat("yyyy-MMM-dd HH:mm:ss.SSS").format(parsedDateTime);
      final Map<String, dynamic> jsonStrPayload = {
        "site_id": siteId,
        "init_id": initId,
        "site_engineer_id": siteEngId,
        "created_by": userId,
        "appointment_remarks": remarks.trim(),
        "appointment_datetime": formatted,
        "appointment_status": 7,
      };
      final Map<String, dynamic> bodyData = {"lookup": "CHANGE_APPOINTMENT", "json_str": jsonEncode(jsonStrPayload)};
      debugPrint("Body Data: $bodyData");
      final response = await ApiServices.postRequestWithAuth(url, bodyData);
      if (response["status"] == "OK") {
        basicDetails.appointmentRemarks = remarks.trim();
        basicDetails.appointmentDatetime = formatted;
        await DBHelper.updateBasicDetailsBySiteId(siteId, basicDetails);
        debugPrint("Response: $response");
        emit(CustomCardSuccessState("${response["data"][0]["message"]}"));
        final index = basicDetailsList.indexWhere((e) => e.siteId == siteId);

        if (index != -1) {
          basicDetailsList[index] = basicDetails;
        }
        emit(
          CustomCardDownloadedState(List<BasicDetails>.from(basicDetailsList), List<ImageEntity>.from(imageDataList)),
        );
        // fetchDataWithDB();
      } else {
        emit(CustomCardErrorState(response["message"]));
      }
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(CustomCardErrorState(errorMsg));
    }
  }

  void finalSubmitMethod({required int siteId, required int initId, required int siteEngId}) async {
    try {
      final String url = "${ApiUrls.baseUrl}/UpdateStatus";
      final userId = await StorageFunction.readIntData(StorageKey.userId);
      final selfieData = await DBHelper.getImagesBySiteId(siteId);
      final selfieImages = selfieData.where((item) => item.selectedCategoryTitle == "Selfie").toList();
      final unSyncImg = selfieData.where((i) => i.sync == 0).toList();

      if (selfieImages.isEmpty) {
        emit(CustomCardErrorState("At least one selfie is required."));
        return;
      } else if (unSyncImg.isNotEmpty) {
        emit(CustomCardErrorState("Please sync all images, before Final Submit."));
        return;
      }

      bool foundSurvey = false;
      bool hasUnfilledMandatory = false;
      Map<String, dynamic>? updatedFieldJsonStr;

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
              emit(CustomCardErrorState("Please fill survey details and Save it."));
              return;
            }
            // Update siteEngAccepted
            survey.basicDetails?.siteEngAccepted = 3;
            survey.basicDetails?.siteSubmitted = 1;
            survey.basicDetails?.visitDate = DateFormat('d MMM yyyy hh:mm:ss').format(DateTime.now());
            // Prepare JSON and update local DB
            updatedFieldJsonStr = survey.toJson();
            await DBHelper.updateHomeData(homeData);
            break;
          }
        }
      }
      fetchDataWithDB();
      // final HomeData updatedHomeData = HomeData.fromJson(updatedFieldJsonStr!);
      // await DBHelper.updateHomeData(updatedHomeData);

      if (!foundSurvey) {
        emit(CustomCardErrorState("Survey data not found for site ID $siteId"));
        return;
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

      if (response["status"] == "OK") {
        emit(CustomCardSuccessState(response["data"][0]["message"]));
      } else {
        emit(CustomCardErrorState(response["message"] ?? "Survey submission failed"));
      }
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      debugPrint("Error: $e");
      emit(CustomCardErrorState(errorMsg));
    }
  }
}
