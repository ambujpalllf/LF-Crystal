import 'package:lf_crystal/model/room_details_basic.dart';

class RoomDetails {
  List<RoomDetailsBasic> data;

  RoomDetails({required this.data});

  Map<String, dynamic> toJson() {
    return {"data": data.map((item) => item.toJson()).toList()};
  }
}
