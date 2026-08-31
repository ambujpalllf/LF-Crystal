import 'dart:convert';

PhotoCategoryResponse photoCategoryResponseFromJson(String str) =>
    PhotoCategoryResponse.fromJson(json.decode(str));

String photoCategoryModelToJson(PhotoCategoryResponse data) =>
    json.encode(data.toJson());

class PhotoCategoryResponse {
  List<CategoryDatum>? data;
  String? status;
  String? message;

  PhotoCategoryResponse({this.data, this.status, this.message});

  factory PhotoCategoryResponse.fromJson(Map<String, dynamic> json) =>
      PhotoCategoryResponse(
        data:
            json["data"] == null
                ? []
                : List<CategoryDatum>.from(
                  json["data"]!.map((x) => CategoryDatum.fromJson(x)),
                ),
        status: json["status"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
    "data":
        data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "status": status,
    "message": message,
  };
}

class CategoryDatum {
  String? categoryType;
  List<SubCategory>? subCategory;

  CategoryDatum({this.categoryType, this.subCategory});

  factory CategoryDatum.fromJson(Map<String, dynamic> json) => CategoryDatum(
    categoryType: json["category_type"],
    subCategory:
        json["sub_category"] == null
            ? []
            : List<SubCategory>.from(
              json["sub_category"]!.map((x) => SubCategory.fromJson(x)),
            ),
  );

  Map<String, dynamic> toJson() => {
    "category_type": categoryType,
    "sub_category":
        subCategory == null
            ? []
            : List<dynamic>.from(subCategory!.map((x) => x.toJson())),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryDatum &&
          runtimeType == other.runtimeType &&
          categoryType == other.categoryType;

  @override
  int get hashCode => categoryType.hashCode;
}

class SubCategory {
  String? subCategoryType;

  SubCategory({this.subCategoryType});

  factory SubCategory.fromJson(Map<String, dynamic> json) =>
      SubCategory(subCategoryType: json["sub_category_type"]);

  Map<String, dynamic> toJson() => {"sub_category_type": subCategoryType};
}
