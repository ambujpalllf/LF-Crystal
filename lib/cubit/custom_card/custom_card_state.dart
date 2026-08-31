import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/model/image_entity_model.dart';

abstract class CustomCardState {
  CustomCardState();
}

class CustomCardInitState extends CustomCardState {}

class CustomCardLoadingState extends CustomCardState {}

class CustomCardStopLoadingState extends CustomCardState {}

class CustomCardDownloadedState extends CustomCardState {
  List<BasicDetails> basicDetails;
  List<ImageEntity> images;
  CustomCardDownloadedState(this.basicDetails, this.images);
}

class CustomCardErrorState extends CustomCardState {
  String message;
  CustomCardErrorState(this.message);
}

class CustomCardSuccessState extends CustomCardState {
  String message;
  CustomCardSuccessState(this.message);
}

class CustomCardSyncState extends CustomCardState {
  String message;
  CustomCardSyncState(this.message);
}

class CustomCardImageListLoadedState extends CustomCardState {
  List<ImageEntity> images;
  CustomCardImageListLoadedState(this.images);
}
