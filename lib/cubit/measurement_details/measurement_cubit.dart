import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/cubit/measurement_details/measurement_state.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/model/room_details.dart';
import 'package:lf_crystal/model/room_details_basic.dart';

class MeasurementCubit extends Cubit<MeasurementState> {
  MeasurementCubit() : super(InitState());

  Future<void> getData() async {
    try {
      final responseData = await DBHelper.getAllHomeData();

      if (responseData.isEmpty) {
        emit(ErrorState(message: "No home data found. Please try again."));
        return;
      }

      Map<String, List<SpinnerMaster>> spinnerMaster = {};

      for (final data in responseData) {
        if (data.spinnerMaster != null) {
          spinnerMaster.addAll(data.spinnerMaster!);
        }
      }

      final List<SpinnerMaster> buildingSpaces = spinnerMaster["building_space_id"] ?? [];

      if (buildingSpaces.isEmpty) {
        emit(ErrorState(message: "No building spaces available."));
        return;
      }

      emit(LoadedState(buildingSpaces: buildingSpaces));
    } catch (e) {
      emit(ErrorState(message: "Unable to load building spaces. Please try again."));
    }
  }

  bool fieldsValidation({
    SpinnerMaster? selectedBuildingSpace,
    required String lengthFeet,
    required String lengthInch,
    required String breadthFeet,
    required String breadthInch,
    required String buildingShape,
  }) {
    String selectedBuildingSpaceEr = "";
    String lengthFeetEr = "";
    String lengthInchEr = "";
    String breadthFeetEr = "";
    String breadthInchEr = "";
    String buildingShapeEr = "";

    // Validate each field independently
    if (selectedBuildingSpace == null ||
        selectedBuildingSpace.value == null ||
        selectedBuildingSpace.value!.trim().isEmpty) {
      selectedBuildingSpaceEr = "Please select a building space";
    }
    if (lengthFeet.trim().isEmpty) {
      lengthFeetEr = "Please enter the room length in feet";
    }

    if (lengthInch.trim().isEmpty) {
      lengthInchEr = "Please enter the remaining length in inches";
    }

    if (breadthFeet.trim().isEmpty) {
      breadthFeetEr = "Please enter the room breadth in feet";
    }

    if (breadthInch.trim().isEmpty) {
      breadthInchEr = "Please enter the remaining breadth in inches";
    }

    if (buildingShape.trim().isEmpty) {
      buildingShapeEr = "Please select a building shape";
    }

    emit(
      ValidationState(
        selectedBuildingSpaceEr: selectedBuildingSpaceEr,
        lengthFeetEr: lengthFeetEr,
        lengthInchEr: lengthInchEr,
        breadthFeetEr: breadthFeetEr,
        breadthInchEr: breadthInchEr,
        buildingShapeEr: buildingShapeEr,
      ),
    );

    // Return true only when all fields are valid
    return selectedBuildingSpaceEr.isEmpty &&
        lengthFeetEr.isEmpty &&
        lengthInchEr.isEmpty &&
        breadthFeetEr.isEmpty &&
        breadthInchEr.isEmpty &&
        buildingShapeEr.isEmpty;
  }

  void measurementCalculation({
    required String lengthFeet,
    required String lengthInch,
    required double lengthTotal,
    required String breadthFeet,
    required String breadthInch,
    required double breadthTotal,
    required String buildingShape,
    required double areaTotal,
  }) {
    try {
      // Length
      int lenFeet = int.tryParse(lengthFeet) ?? 0;
      int lenInch = int.tryParse(lengthInch) ?? 0;
      lengthTotal = double.parse((lenFeet + (lenInch / 12.0)).toStringAsFixed(2));

      // Breadth
      int breFeet = int.tryParse(breadthFeet) ?? 0;
      int breInch = int.tryParse(breadthInch) ?? 0;
      breadthTotal = breadthTotal = double.parse((breFeet + (breInch / 12.0)).toStringAsFixed(2));

      switch (buildingShape.toLowerCase()) {
        case "square":
          areaTotal = double.parse((lengthTotal * breadthTotal).toStringAsFixed(2));
          break;

        case "triangle":
          areaTotal = double.parse(((lengthTotal * breadthTotal) / 2).toStringAsFixed(2));
          break;

        case "door sill(1.75)":
          breadthTotal = 1.75;
          areaTotal = 1.75;
          break;

        case "door sill(1.25)":
          breadthTotal = 1.25;
          areaTotal = 1.25;
          break;

        case "semi-circle":
          final double radiusSquared = lengthTotal * lengthTotal;
          areaTotal = double.parse(((3.142 * radiusSquared) / 2).toStringAsFixed(2));
          break;

        case "quarter-circle":
          final double radiusSquared = lengthTotal * lengthTotal;
          areaTotal = double.parse(((3.142 * radiusSquared) / 4).toStringAsFixed(2));
          break;

        default:
          areaTotal = 0.0;
      }
      emit(
        CalculationState(
          lengthFeet: lengthFeet,
          lengthInch: lengthInch,
          lengthTotal: lengthTotal,
          breadthFeet: breadthFeet,
          breadthInch: breadthInch,
          breadthTotal: breadthTotal,
          areaTotal: areaTotal,
        ),
      );
    } catch (e) {
      emit(ErrorState(message: e.toString()));
    }
  }

  bool saveMesurement({
    int? index,
    SpinnerMaster? selectedBuildingSpace,
    required String lengthFeet,
    required String lengthInch,
    required double lengthTotal,
    required String breadthFeet,
    required String breadthInch,
    required double breadthTotal,
    required String buildingShape,
    required double areaTotal,
  }) {
    try {
      final isValid = fieldsValidation(
        selectedBuildingSpace: selectedBuildingSpace,
        lengthFeet: lengthFeet,
        lengthInch: lengthInch,
        breadthFeet: breadthFeet,
        breadthInch: breadthInch,
        buildingShape: buildingShape,
      );
      if (!isValid) return false;
      List<RoomDetailsBasic> roomData = [
        RoomDetailsBasic(label: "", value: "true", type: "checkbox"),
        RoomDetailsBasic(
          label: "Description",
          value: "${selectedBuildingSpace?.key}-${selectedBuildingSpace?.value}",
          type: "text",
        ),
        RoomDetailsBasic(label: "Length (Feet)", value: lengthFeet, type: "number"),
        RoomDetailsBasic(label: "Length (Inches)", value: lengthInch, type: "number"),
        RoomDetailsBasic(label: "Length (Total)", value: lengthTotal.toString(), type: "number"),
        RoomDetailsBasic(label: "Breadth (Feet)", value: breadthFeet, type: "number"),
        RoomDetailsBasic(label: "Breadth (Inches)", value: breadthInch, type: "number"),
        RoomDetailsBasic(label: "Breadth (Total)", value: breadthTotal.toString(), type: "number"),
        RoomDetailsBasic(label: "Area", value: areaTotal.toString(), type: "number"),
        RoomDetailsBasic(label: "Shape", value: buildingShape, type: "text"),
      ];
      RoomDetails data = RoomDetails(data: roomData);
      emit(DataSavedState(data: data, index: index));
      return true;
    } catch (e) {
      emit(ErrorState(message: e.toString()));
      return false;
    }
  }

  void calculateSumofArea({required List<RoomDetails> mesurementData, required bool isChecked, required int index}) {
    try {
      // Update the current item's checked value.
      setChecked(mesurementData[index], isChecked);

      double totalArea = 0.0;

      for (final room in mesurementData) {
        final roomChecked = getChecked(room);

        if (!roomChecked) {
          continue;
        }

        final areaValue = getValue(room, "Area");

        final area = double.tryParse(areaValue);

        if (area != null) {
          totalArea += area;
        }
      }

      totalArea = double.parse(totalArea.toStringAsFixed(2));

      debugPrint("Total Selected Area: $totalArea");

      emit(AreaCalculatedState(sumArea: totalArea));
    } catch (e) {
      emit(ErrorState(message: e.toString()));
    }
  }

  // List<RoomDetails> parseMeasurementData(String value) {
  //   if (value.trim().isEmpty || value.trim() == "[]") {
  //     return [];
  //   }
  //   final List<dynamic> jsonList = jsonDecode(value);
  //   if (jsonList.isEmpty) {
  //     return [];
  //   }
  //   return jsonList.map<RoomDetails>((outerItem) {
  //     final Map<String, dynamic> outerMap = Map<String, dynamic>.from(outerItem);

  //     final List<RoomDetailsBasic> roomBasicList = [];

  //     // Sort keys so 0,1,2,3... remain in correct order
  //     final keys = outerMap.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

  //     for (final key in keys) {
  //       final innerMap = Map<String, dynamic>.from(outerMap[key]);

  //       roomBasicList.add(RoomDetailsBasic.fromJson(innerMap));
  //     }

  //     return RoomDetails(data: roomBasicList);
  //   }).toList();
  // }
  List<RoomDetails> parseMeasurementData(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == "[]") {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List || decoded.isEmpty) {
        return [];
      }

      return decoded.map<RoomDetails>((outerItem) {
        final Map<String, dynamic> outerMap = Map<String, dynamic>.from(outerItem);

        final List<RoomDetailsBasic> roomBasicList = [];

        final keys = outerMap.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

        for (final key in keys) {
          final innerMap = Map<String, dynamic>.from(outerMap[key]);

          roomBasicList.add(RoomDetailsBasic.fromJson(innerMap));
        }

        return RoomDetails(data: roomBasicList);
      }).toList();
    } catch (e) {
      debugPrint("Failed to parse measurement data: $e");
      return [];
    }
  }

  String getValue(RoomDetails room, String label) {
    for (final item in room.data) {
      if (item.label.toLowerCase() == label.toLowerCase()) {
        return item.value;
      }
    }

    return "";
  }

  void setChecked(RoomDetails room, bool checked) {
    for (final item in room.data) {
      if (item.type.toLowerCase() == "checkbox") {
        item.value = checked.toString();
        return;
      }
    }
  }

  bool getChecked(RoomDetails room) {
    for (final item in room.data) {
      if (item.type.toLowerCase() == "checkbox") {
        return item.value.toLowerCase() == "true";
      }
    }

    return false;
  }

  void calculateTotalArea(List<RoomDetails> rooms) {
    double sum = 0;
    for (final room in rooms) {
      final isChecked = getChecked(room);

      if (!isChecked) {
        continue;
      }

      final areaString = getValue(room, "Area");

      final area = double.tryParse(areaString);

      if (area != null) {
        sum += area;
      }
    }
    double total = double.parse(sum.toStringAsFixed(2));
    emit(AreaCalculatedState(sumArea: total));
  }

  void removeData({required int index}) {
    emit(RemoveState(index: index));
  }

  String measurementDataToJson(List<RoomDetails> data) {
    if (data.isEmpty) {
      return "[]";
    }

    final List<Map<String, dynamic>> result = [];

    for (final room in data) {
      final Map<String, dynamic> outerJsonObj = {};

      for (int index = 0; index < room.data.length; index++) {
        final item = room.data[index];

        outerJsonObj[index.toString()] = {"label": item.label, "value": item.value, "type": item.type};
      }

      result.add(outerJsonObj);
    }

    return jsonEncode(result);
  }
}
