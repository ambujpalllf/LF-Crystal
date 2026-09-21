import 'dart:convert';
import 'package:lf_crystal/constants/workmanager_task_key.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:workmanager/workmanager.dart';

class WorkManagerTaskRegister {
  // static void selfieSync({required ImageEntity imageData, required DateTime timestamp, required int userId}) {
  //   Workmanager().registerOneOffTask(
  //     '${WorkmanagerTaskKey.selfieSync}_${DateTime.now().millisecondsSinceEpoch}',
  //     WorkmanagerTaskKey.selfieSync,
  //     inputData: {
  //       'imagePath': imageData.imagePath,
  //       'valueEmpId': imageData.valueEmpId,
  //       'siteId': imageData.siteId,
  //       'selectedCategoryTitle': imageData.selectedCategoryTitle,
  //       'selectedSubCategoryTitle': imageData.selectedSubCategoryTitle,
  //       'photoId': imageData.photoId,
  //       'serialOrder': imageData.serialOrder,
  //       'sync': imageData.sync,
  //       'syncSerialOrder': imageData.syncSerialOrder,
  //       'moDateTime': imageData.moDateTime.toIso8601String(),
  //       'imgLatitude': imageData.imgLatitude,
  //       'imgLongitude': imageData.imgLongitude,
  //       'imgAccuracy': imageData.imgAccuracy,
  //       "timestamp": timestamp.toIso8601String(),
  //       "user_id": userId.toString(),
  //     },
  //     constraints: Constraints(networkType: NetworkType.connected),
  //   );
  // }

  static void multiImageSync({required int siteId}) {
    Workmanager().registerOneOffTask(
      // '${WorkmanagerTaskKey.multiImageSync}_${DateTime.now().millisecondsSinceEpoch}',
      WorkmanagerTaskKey.multiImageSync,
      WorkmanagerTaskKey.multiImageSync,
      inputData: {"user_id": siteId.toString()},
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static void syncDataToServer({required SurveyDetail updatedSurveyDetail}) {
    final surveyDetailString = jsonEncode(updatedSurveyDetail.toJson());
    Workmanager().registerOneOffTask(WorkmanagerTaskKey.syncDataToServer, WorkmanagerTaskKey.syncDataToServer, inputData: {"surveydetails": surveyDetailString}, constraints: Constraints(networkType: NetworkType.connected));
  }

  static void syncLocation() {
    Workmanager().registerPeriodicTask(WorkmanagerTaskKey.syncLocation, WorkmanagerTaskKey.syncLocation, initialDelay: Duration(seconds: 2), frequency: Duration(minutes: 15), constraints: Constraints(networkType: NetworkType.connected));
  }
}
