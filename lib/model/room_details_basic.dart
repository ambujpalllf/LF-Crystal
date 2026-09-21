class RoomDetailsBasic {
  String label;
  String value;
  String type;

  RoomDetailsBasic({required this.label, required this.value, required this.type});

  factory RoomDetailsBasic.fromJson(Map<String, dynamic> json) {
    return RoomDetailsBasic(
      label: json["label"]?.toString() ?? "",
      value: json["value"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {"label": label, "value": value, "type": type};
  }
}
