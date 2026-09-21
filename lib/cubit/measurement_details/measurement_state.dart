import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/model/room_details.dart';

class MeasurementState {}

class InitState extends MeasurementState {}

class LoadingState extends MeasurementState {}

class LoadedState extends MeasurementState {
  List<SpinnerMaster> buildingSpaces;
  LoadedState({required this.buildingSpaces});
}

class ErrorState extends MeasurementState {
  final String message;
  ErrorState({required this.message});
}

class ValidationState extends MeasurementState {
  String selectedBuildingSpaceEr;
  String lengthFeetEr;
  String lengthInchEr;
  String breadthFeetEr;
  String breadthInchEr;
  String buildingShapeEr;

  ValidationState({
    required this.selectedBuildingSpaceEr,
    required this.lengthFeetEr,
    required this.lengthInchEr,
    required this.breadthFeetEr,
    required this.breadthInchEr,
    required this.buildingShapeEr,
  });
}

class CalculationState extends MeasurementState {
  String lengthFeet;
  String lengthInch;
  double lengthTotal;
  String breadthFeet;
  String breadthInch;
  double breadthTotal;
  double areaTotal;

  CalculationState({
    required this.lengthFeet,
    required this.lengthInch,
    required this.lengthTotal,
    required this.breadthFeet,
    required this.breadthInch,
    required this.breadthTotal,
    required this.areaTotal,
  });
}

class DataSavedState extends MeasurementState {
  RoomDetails data;
  int? index;
  DataSavedState({required this.data, this.index});
}

class AreaCalculatedState extends MeasurementState {
  double sumArea;
  AreaCalculatedState({required this.sumArea});
}

class RemoveState extends MeasurementState {
  final int index;
  RemoveState({required this.index});
}
