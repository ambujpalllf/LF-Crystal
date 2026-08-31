class ImageEntity {
  int? id;
  String imagePath;
  int valueEmpId;
  int siteId;
  String selectedCategoryTitle;
  String selectedSubCategoryTitle;
  int photoId;
  int serialOrder;
  int sync;
  int syncSerialOrder;
  DateTime moDateTime;
  String imgLatitude;
  String imgLongitude;
  String imgAccuracy;

  ImageEntity({
    this.id,
    required this.imagePath,
    required this.valueEmpId,
    required this.siteId,
    required this.selectedCategoryTitle,
    required this.selectedSubCategoryTitle,
    required this.photoId,
    required this.serialOrder,
    required this.sync,
    required this.syncSerialOrder,
    required this.moDateTime,
    required this.imgLatitude,
    required this.imgLongitude,
    required this.imgAccuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      // 'id': id,
      'imagePath': imagePath,
      'valueEmpId': valueEmpId,
      'siteId': siteId,
      'selectedCategoryTitle': selectedCategoryTitle,
      'selectedSubCategoryTitle': selectedSubCategoryTitle,
      'photoId': photoId,
      'serialOrder': serialOrder,
      'sync': sync,
      'syncSerialOrder': syncSerialOrder,
      'moDateTime': moDateTime.toIso8601String(),
      'imgLatitude': imgLatitude,
      'imgLongitude': imgLongitude,
      'imgAccuracy': imgAccuracy,
    };
  }

  factory ImageEntity.fromMap(Map<String, dynamic> map) {
    return ImageEntity(
      id: map['id'],
      imagePath: map['imagePath'],
      valueEmpId: map['valueEmpId'],
      siteId: map['siteId'],
      selectedCategoryTitle: map['selectedCategoryTitle'],
      selectedSubCategoryTitle: map['selectedSubCategoryTitle'],
      photoId: map['photoId'],
      serialOrder: map['serialOrder'],
      sync: map['sync'],
      syncSerialOrder: map['syncSerialOrder'],
      moDateTime: DateTime.parse(map['moDateTime']),
      imgLatitude: map['imgLatitude'],
      imgLongitude: map['imgLongitude'],
      imgAccuracy: map['imgAccuracy'],
    );
  }
  factory ImageEntity.fromJson(Map<String, dynamic> json) {
    return ImageEntity.fromMap(json);
  }

  /// 🧩 Creates a copy of this object with optional updated fields.
  ImageEntity copyWith({
    int? id,
    String? imagePath,
    int? valueEmpId,
    int? siteId,
    String? selectedCategoryTitle,
    String? selectedSubCategoryTitle,
    int? photoId,
    int? serialOrder,
    int? sync,
    int? syncSerialOrder,
    DateTime? moDateTime,
    String? imgLatitude,
    String? imgLongitude,
    String? imgAccuracy,
  }) {
    return ImageEntity(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      valueEmpId: valueEmpId ?? this.valueEmpId,
      siteId: siteId ?? this.siteId,
      selectedCategoryTitle: selectedCategoryTitle ?? this.selectedCategoryTitle,
      selectedSubCategoryTitle: selectedSubCategoryTitle ?? this.selectedSubCategoryTitle,
      photoId: photoId ?? this.photoId,
      serialOrder: serialOrder ?? this.serialOrder,
      sync: sync ?? this.sync,
      syncSerialOrder: syncSerialOrder ?? this.syncSerialOrder,
      moDateTime: moDateTime ?? this.moDateTime,
      imgLatitude: imgLatitude ?? this.imgLatitude,
      imgLongitude: imgLongitude ?? this.imgLongitude,
      imgAccuracy: imgAccuracy ?? this.imgAccuracy,
    );
  }
}
