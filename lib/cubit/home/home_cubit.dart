import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:lf_crystal/constants/api_urls.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/cubit/home/home_state.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/services/base_client.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitState());

  Future<void> downloadData() async {
    emit(DownLoadingState());

    try {
      final userId = await StorageFunction.readIntData(StorageKey.userId);
      final siteId = await StorageFunction.readStringData(StorageKey.siteIds) ?? "";
      debugPrint("Site id: $siteId");
      final String url = "${ApiUrls.baseUrl}/PendingSitePost";

      Map<String, dynamic> bodyData = {"site_engineer_id": userId, "mob_site_ids": siteId};

      final response = await ApiServices.postRequestWithAuth(url, bodyData);
      debugPrint("Response Data: $response");
      final responseJson = HomeResponse.fromJson(response);

      if (responseJson.data == null) {
        emit(DownLoadedErrorState("No new case available."));
        return;
      }
      final homeData = responseJson.data!;
      // ignore: unnecessary_null_comparison
      if (homeData != null) {
        DBHelper.insertHomeData(homeData);
      }
      final surveyDetails = responseJson.data!.surveyDetails;
      List<String> siteIdList = [];

      if (surveyDetails != null) {
        for (var detail in surveyDetails) {
          final basicDetails = detail.basicDetails;
          if (basicDetails != null && basicDetails.siteId != null) {
            siteIdList.add(basicDetails.siteId!.toString());
          }
        }
      }

      final commaSeparatedSiteIds = siteIdList.join(',');
      debugPrint("Writing Site IDs to storage: $commaSeparatedSiteIds");

      await StorageFunction.writeStringData(StorageKey.siteIds, commaSeparatedSiteIds);

      final savedSiteIds = await StorageFunction.readStringData(StorageKey.siteIds) ?? "";
      debugPrint("Saved Site IDs: $savedSiteIds");

      emit(DownLoadedState(siteIdList.length.toString()));
    } catch (e) {
      debugPrint("Error fetching data: $e");
      String result = e.toString().split(":")[1].trim();
      emit(DownLoadedErrorState(result));
    }
  }

  Map<String, dynamic> sanitizeForDb(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is bool) {
        sanitized[key] = value ? 1 : 0; //  Convert bool to int
      } else if (value is List || value is Map) {
        sanitized[key] = jsonEncode(value); // Convert List/Map to JSON string
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  void clearAllData() async {
    await StorageFunction.removeData(StorageKey.isCategoryDownload);
    await StorageFunction.removeData(StorageKey.siteIds);
    await DBHelper.clearAllData();
    emit(HomeDataClearedState());
  }

  void logoutUser() async {
    await StorageFunction.removeData(StorageKey.token);
    await StorageFunction.removeData(StorageKey.refreshToken);
    await StorageFunction.removeData(StorageKey.userId);
    await StorageFunction.removeData(StorageKey.loginDateTime);
    await StorageFunction.removeData(StorageKey.isLogin);
    FlutterForegroundTask.stopService();
    emit(LogoutState());
  }
}
