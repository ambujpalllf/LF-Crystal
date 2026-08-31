import 'package:lf_crystal/model/home_model.dart';

abstract class OpenCaseState {}

class OpenCaseInitState extends OpenCaseState {}

class OpenCaseLoadingState extends OpenCaseState {}

class OpenCaseLoadedState extends OpenCaseState {
  List<Field> fields;
  Map<String, List<SpinnerMaster>> spinnerMaster;
  OpenCaseLoadedState(this.fields, this.spinnerMaster);
}

class OpenCaseErrorState extends OpenCaseState {
  final String message;
  OpenCaseErrorState(this.message);
}

class OpenCaseSuccessState extends OpenCaseState {
  final String message;
  OpenCaseSuccessState(this.message);
}
