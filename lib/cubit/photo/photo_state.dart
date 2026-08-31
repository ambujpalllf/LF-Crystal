import 'package:lf_crystal/model/photo_category_model.dart';

abstract class PhotoState {
  PhotoState();
}

class PhotoInitState extends PhotoState {}

class PhotoLoadingState extends PhotoState {}

class StopLoadingState extends PhotoState {}

class PhotoLoadedState extends PhotoState {
  PhotoCategoryResponse photoCategoryResponse;
  List<SubCategory> subcategory;
  // for dropdown
  String initialValue = "";
  PhotoLoadedState({required this.photoCategoryResponse, required this.subcategory, this.initialValue = ""});
}

class PhotoErrorState extends PhotoState {
  String message;
  PhotoErrorState(this.message);
}

class PhotoSuccessState extends PhotoState {
  String message;
  PhotoSuccessState(this.message);
}

class PhotoCategoryErrorState extends PhotoState {
  String message;
  PhotoCategoryErrorState(this.message);
}

class PhototSubCategoryLoadedSata extends PhotoState {
  List<SubCategory> subcategory;
  PhototSubCategoryLoadedSata(this.subcategory);
}
