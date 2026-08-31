import 'package:lf_crystal/model/image_entity_model.dart';

abstract class ImageListState {
  ImageListState();
}

class ImageListInitState extends ImageListState {}

class ImageListLoadingState extends ImageListState {}

class ImageListLoadedState extends ImageListState {
  List<ImageEntity> images;
  ImageListLoadedState(this.images);
}

class ImageListErrorState extends ImageListState {
  String message;
  ImageListErrorState(this.message);
}

class ImageListSuccesState extends ImageListState {
  String message;
  ImageListSuccesState(this.message);
}
