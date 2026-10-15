import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/cubit/construction_monitoring/cons_monitoring_state.dart';

class ConsMonitoringCubit extends Cubit<ConsMonitoringState> {
  ConsMonitoringCubit() : super(InitState());

  void updatePlinth({required String plinth}) {
    if (plinth.trim() == "100") {
      emit(PlinthState(isEnable: false));
    } else {
      emit(PlinthState(isEnable: true));
    }
  }

  bool validateFields({
    required String floors,
    required String slabs,
    required String plinth,
    required bool isDisableFields,
    required String rcc,
    required String bwUptoSlab,
    required String plasteringInternal,
    required String plasteringExternal,
    required String flooring,
    required String electric,
    required String plumbing,
    required String woodWork,
    required String painting,
  }) {
    try {
      String? floorEr;
      String? slabsEr;
      String? plinthEr;
      String? rccEr;
      String? bwUptoSlabEr;
      String? plasteringInternalEr;
      String? plasteringExternalEr;
      String? flooringEr;
      String? electricEr;
      String? plumbingEr;
      String? woodWorkEr;
      String? paintingEr;
      // ALWAYS REQUIRED
      if (floors.trim().isEmpty) {
        floorEr = "Number of floors is required";
      }

      if (slabs.trim().isEmpty) {
        slabsEr = "Number of slabs is required";
      }

      if (plinth.trim().isEmpty) {
        plinthEr = "Plinth is required";
      }
      if (plinth.trim().isNotEmpty) {
        final int? pValue = int.tryParse(plinth.trim());

        if (pValue != null && pValue > 100) {
          plinthEr = "Plinth cannot be greater than 100 %";
        }
      }
      if (isDisableFields == false) {
        rccEr = validateNotGreaterThan(
          value: rcc,
          maximum: slabs,
          fieldName: "RCC",
          maximumFieldName: "Number of Slabs",
        );

        bwUptoSlabEr = validateNotGreaterThan(
          value: bwUptoSlab,
          maximum: rcc,
          fieldName: "B/W upto Slab",
          maximumFieldName: "RCC (Nos of Slabs Completed)",
        );

        flooringEr = validateNotGreaterThan(
          value: flooring,
          maximum: rcc,
          fieldName: "Flooring",
          maximumFieldName: "RCC (Nos of Slabs Completed)",
        );
        electricEr = validateNotGreaterThan(
          value: electric,
          maximum: bwUptoSlab,
          fieldName: "Electric",
          maximumFieldName: "B/W upto Slab",
        );
        plumbingEr = validateNotGreaterThan(
          value: plumbing,
          maximum: bwUptoSlab,
          fieldName: "Plumbing",
          maximumFieldName: "B/W upto Slab",
        );
        woodWorkEr = validateNotGreaterThan(
          value: woodWork,
          maximum: bwUptoSlab,
          fieldName: "Woodwork",
          maximumFieldName: "B/W upto Slab",
        );
        plasteringExternalEr = validateNotGreaterThan(
          value: plasteringExternal,
          maximum: bwUptoSlab,
          fieldName: "Plastering (External)",
          maximumFieldName: "B/W upto Slab",
        );
        plasteringInternalEr = validateNotGreaterThan(
          value: plasteringInternal,
          maximum: bwUptoSlab,
          fieldName: "Plastering (Internal)",
          maximumFieldName: "B/W upto Slab",
        );
        paintingEr = validateNotGreaterThan(
          value: painting,
          maximum: plasteringExternal,
          fieldName: "Painting",
          maximumFieldName: "Plastering (External)",
        );
      }

      final bool isValid =
          floorEr == null &&
          slabsEr == null &&
          plinthEr == null &&
          rccEr == null &&
          bwUptoSlabEr == null &&
          plasteringInternalEr == null &&
          plasteringExternalEr == null &&
          flooringEr == null &&
          electricEr == null &&
          plumbingEr == null &&
          woodWorkEr == null &&
          paintingEr == null;

      // Emit validation state
      emit(
        ValidationState(
          floorEr: floorEr,
          slabsEr: slabsEr,
          plinthEr: plinthEr,
          rccEr: rccEr,
          bwUptoSlabEr: bwUptoSlabEr,
          plasteringInternalEr: plasteringInternalEr,
          plasteringExternalEr: plasteringExternalEr,
          flooringEr: flooringEr,
          electricEr: electricEr,
          plumbingEr: plumbingEr,
          woodWorkEr: woodWorkEr,
          paintingEr: paintingEr,
        ),
      );

      return isValid;
    } catch (e) {
      emit(ErrorState(message: e.toString()));
      return false;
    }
  }

  String? validateNotGreaterThan({
    required String value,
    required String maximum,
    required String fieldName,
    required String maximumFieldName,
  }) {
    if (value.trim().isEmpty) {
      return "$fieldName is required";
    }

    final int? valueNumber = int.tryParse(value.trim());

    if (valueNumber == null) {
      return "Enter a valid $fieldName value";
    }

    final int? maximumNumber = int.tryParse(maximum.trim());

    if (maximumNumber == null) {
      return null;
    }

    if (valueNumber > maximumNumber) {
      return "$fieldName cannot be greater than $maximumFieldName";
    }

    return null;
  }

  // String getConstructionValue({
  //   required String floors,
  //   required String slabs,
  //   required String plinth,
  //   required String rcc,
  //   required String bwUptoSlab,
  //   required String flooring,
  //   required String electric,
  //   required String plumbing,
  //   required String woodWork,
  //   required String plasteringInternal,
  //   required String plasteringExternal,
  //   required String painting,
  // }) {
  //   final List<Map<String, dynamic>> data = [
  //     {
  //       "0": {"stage_id": 1, "label": "No of Floors", "value": floors, "type": "number", "default_value": ""},
  //       "1": {"stage_id": 2, "label": "No of Slabs", "value": slabs, "type": "number", "default_value": ""},
  //       "2": {"stage_id": 3, "label": "Plinth", "value": plinth, "type": "number"},
  //       "3": {
  //         "stage_id": 4,
  //         "label": "RCC (No of Slabs Completed)",
  //         "value": rcc,
  //         "type": "number",
  //         "default_value": "",
  //       },
  //       "4": {"stage_id": 5, "label": "B/W upto Slab", "value": bwUptoSlab, "type": "number", "default_value": ""},
  //       "5": {"stage_id": 1, "label": "Flooring", "value": flooring, "type": "number", "default_value": ""},
  //       "6": {"stage_id": 1, "label": "Electric", "value": electric, "type": "number", "default_value": ""},
  //       "7": {"stage_id": 1, "label": "Plumbing", "value": plumbing, "type": "number", "default_value": ""},
  //       "8": {"stage_id": 1, "label": "Woodwork", "value": woodWork, "type": "number", "default_value": ""},
  //       "9": {
  //         "stage_id": 1,
  //         "label": "Plastering (Internal)",
  //         "value": plasteringInternal,
  //         "type": "number",
  //         "default_value": "",
  //       },
  //       "10": {
  //         "stage_id": 1,
  //         "label": "Plastering (External)",
  //         "value": plasteringExternal,
  //         "type": "number",
  //         "default_value": "",
  //       },
  //       "11": {"stage_id": 1, "label": "Painting", "value": painting, "type": "number", "default_value": ""},
  //     },
  //   ];

  //   return jsonEncode(data);
  // }

  String getConstructionValue({
    required String consValue,
    required String floors,
    required String slabs,
    required String plinth,
    required String rcc,
    required String bwUptoSlab,
    required String flooring,
    required String electric,
    required String plumbing,
    required String woodWork,
    required String plasteringInternal,
    required String plasteringExternal,
    required String painting,
  }) {
    try {
      if (consValue.isEmpty) return consValue;

      final dynamic decoded = jsonDecode(consValue);

      if (decoded is! List || decoded.isEmpty || decoded[0] is! Map) {
        return consValue;
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded[0]);

      void updateValue(String key, String value) {
        final dynamic item = data[key];

        if (item is Map) {
          item['value'] = value;
        }
      }

      updateValue("0", floors);
      updateValue("1", slabs);
      updateValue("2", plinth);
      updateValue("3", rcc);
      updateValue("4", bwUptoSlab);
      updateValue("5", plasteringInternal);
      updateValue("6", plasteringExternal);
      updateValue("7", flooring);
      updateValue("8", electric);
      updateValue("9", plumbing);
      updateValue("10", woodWork);
      updateValue("11", painting);

      decoded[0] = data;

      return jsonEncode(decoded);
    } catch (e) {
      // debugPrint("Error updating construction values: $e");
      return consValue;
    }
  }
}
