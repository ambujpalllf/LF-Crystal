import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/constants/utils.dart';
import 'package:lf_crystal/cubit/open_case/open_case_state.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/services/work_manager_task_register.dart';

class OpenCaseCubit extends Cubit<OpenCaseState> {
  HomeData? homeData;
  OpenCaseCubit() : super(OpenCaseInitState());

  Future<void> fetchOpenCaseBySiteId(int siteId) async {
    emit(OpenCaseLoadingState());

    try {
      final data = await DBHelper.getAllHomeData();
      List<Field> matchedFields = [];
      Map<String, List<SpinnerMaster>> spinnerMaster = {};

      for (var item in data) {
        if (item.surveyDetails != null) {
          homeData = item;
          spinnerMaster = item.spinnerMaster!;

          for (var itemData in item.surveyDetails!) {
            final basic = itemData.basicDetails;
            final siteDetails = itemData.siteDetails;

            if (basic != null && basic.siteId == siteId) {
              if (siteDetails?.fields != null) {
                matchedFields.addAll(siteDetails!.fields!);
                // for (var field in siteDetails.fields!) {
                //   debugPrint("Field:");
                //   debugPrint("  Name: ${field.name}");
                //   debugPrint("  Label: ${field.label}");
                //   debugPrint("  Type: ${field.type}");
                //   debugPrint("  Value: ${field.value}");
                //   debugPrint("  Data Type: ${field.dataType}");
                //   debugPrint("  Is Mandatory: ${field.isMandatory}");
                //   debugPrint("  Is Editable: ${field.isEditable}");
                //   debugPrint("  Field Length: ${field.fieldLength}");
                //   debugPrint("-----------------------------");
                // }
              }
            }
          }
        }
      }

      debugPrint("Fetched fields for siteId $siteId: ${matchedFields.length}");

      emit(OpenCaseLoadedState(matchedFields, spinnerMaster));
    } catch (e) {
      debugPrint("Open case fetch error: $e");
      emit(OpenCaseErrorState("Failed to load fields for siteId $siteId."));
    }
  }

  void saveData(int siteId, List<Field> updatedFields) async {
    try {
      emit(OpenCaseLoadingState());

      //  Validate Required fields
      final missingFields = updatedFields.where((field) => field.isMandatory == true && (field.value == null || field.value.toString().trim().isEmpty)).toList();

      if (missingFields.isNotEmpty) {
        final labels = missingFields.map((f) => f.label ?? '').join(', ');
        emit(OpenCaseErrorState("$labels is required."));
        return;
      }
      final homeDataList = await DBHelper.getAllHomeData();
      if (homeDataList.isEmpty) {
        emit(OpenCaseErrorState("No data found."));
        return;
      }
      HomeData? targetHomeData;
      int? surveyIndex;
      for (final item in homeDataList) {
        final index = item.surveyDetails?.indexWhere((sd) => sd.basicDetails?.siteId == siteId);
        if (index != null && index != -1) {
          targetHomeData = item;
          surveyIndex = index;
          break;
        }
      }
      if (targetHomeData == null || surveyIndex == null) {
        emit(OpenCaseErrorState("Site ID $siteId not found."));
        return;
      }
      final currentSurveyDetail = targetHomeData.surveyDetails![surveyIndex];
      final existingFields = currentSurveyDetail.siteDetails?.fields ?? [];

      // Compare old and new fields
      bool hasChanged = false;

      for (final newField in updatedFields) {
        final oldField = existingFields.firstWhere((f) => f.name == newField.name, orElse: () => Field(name: "", value: null));

        final oldValue = oldField.value?.toString().trim() ?? "";
        final newValue = newField.value?.toString().trim() ?? "";

        if (oldValue != newValue) {
          hasChanged = true;
          break;
        }
      }

      if (!hasChanged) {
        emit(OpenCaseErrorState("No changes detected."));
        fetchOpenCaseBySiteId(siteId);
        return;
      }

      // Update fields and mark form saved
      targetHomeData.surveyDetails![surveyIndex].siteDetails?.fields = updatedFields;
      targetHomeData.surveyDetails![surveyIndex].basicDetails?.isFormSaved = true;

      final result = await DBHelper.updateHomeData(targetHomeData);

      if (result == -1) {
        emit(OpenCaseErrorState("Failed to update data."));
        return;
      }

      for (var field in updatedFields) {
        debugPrint("Updated Field - Label: ${field.label}, Value: ${field.value}");
      }

      debugPrint("Fields updated successfully for siteId $siteId");
      emit(OpenCaseSuccessState("Your changes have been saved successfully."));
      fetchOpenCaseBySiteId(siteId);
      // saveDataToServerMehod(currentSurveyDetail);
      WorkManagerTaskRegister.syncDataToServer(updatedSurveyDetail: currentSurveyDetail);
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(OpenCaseErrorState(errorMsg));
    }
  }

  void finalSubmitMethod({required int siteId, required int initId, required int siteEngId}) async {
    try {
      final String msg = await Utils.finalSubmitMethod(siteId: siteId, initId: initId, siteEngId: siteEngId);
      emit(OpenCaseSuccessState(msg));
    } on Exception catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(OpenCaseErrorState(errorMsg));
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(OpenCaseErrorState(errorMsg));
    }
  }
}
