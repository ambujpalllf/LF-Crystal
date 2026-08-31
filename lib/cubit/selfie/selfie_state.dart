import 'package:lf_crystal/model/image_entity_model.dart';

abstract class SelfieState {
  SelfieState();
}

class SelfieInitState extends SelfieState {}

class SelfieLoadingState extends SelfieState {
  final ImageEntity? currentImage;
  SelfieLoadingState({this.currentImage});
}

class SelfieLoadedState extends SelfieState {
  List<ImageEntity> selfie;
  SelfieLoadedState(this.selfie);
}

class SelfiePickedState extends SelfieState {
  ImageEntity selfie;
  bool isProcessed;
  int index;
  SelfiePickedState({required this.selfie, required this.isProcessed, required this.index});
}

class SelfieErrorState extends SelfieState {
  String message;
  SelfieErrorState(this.message);
}

class SelfieSuccessState extends SelfieState {
  String message;
  SelfieSuccessState(this.message);
}

class SelfieRefreshState extends SelfieState {
  final int index;
  SelfieRefreshState({required this.index});
}
