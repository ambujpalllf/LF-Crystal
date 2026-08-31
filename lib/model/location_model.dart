// class LocationModel {
//   int? id;
//   int userId;
//   double latitude;
//   double longitude;
//   double accuracy;
//   String timestamp;
//   double batteryPercentage;

//   LocationModel({
//     this.id,
//     required this.userId,
//     required this.latitude,
//     required this.longitude,
//     required this.accuracy,
//     required this.timestamp,
//     required this.batteryPercentage,
//   });

//   factory LocationModel.fromMap(Map<String, dynamic> map) {
//     return LocationModel(
//       id: map['id'],
//       userId: map['userId'],
//       latitude: map['latitude'],
//       longitude: map['longitude'],
//       accuracy: map['accuracy'],
//       timestamp: map['timestamp'],
//       batteryPercentage: map['batteryPercentage'],
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       if (id != null) 'id': id,
//       'userId': userId,
//       'latitude': latitude,
//       'longitude': longitude,
//       'accuracy': accuracy,
//       'timestamp': timestamp,
//       'batteryPercentage': batteryPercentage,
//     };
//   }
// }

class LocationModel {
  String gpsTrackerDateTime;
  int? gpsTrackerId;
  double latitude;
  double longitude;
  int mobileAppId;
  int usersId;
  double accuracy;
  int batteryPercentage;
  String isMock;
  String provider;

  LocationModel({
    required this.gpsTrackerDateTime,
    this.gpsTrackerId,
    required this.latitude,
    required this.longitude,
    required this.mobileAppId,
    required this.usersId,
    required this.accuracy,
    required this.batteryPercentage,
    required this.isMock,
    required this.provider,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      gpsTrackerDateTime: map['GPS_TRACKER_DATE_TIME'],
      gpsTrackerId: map['GPS_TRACKER_ID'],
      latitude: map['LATITUDE'],
      longitude: map['LONGITUDE'],
      mobileAppId: map['MOBILE_APP_ID'],
      usersId: map['USERS_ID'],
      accuracy: map['ACCURACY'],
      batteryPercentage: map['BATTERY_PERC'],
      isMock: map['IS_MOCK'],
      provider: map['PROVIDER'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "GPS_TRACKER_DATE_TIME": gpsTrackerDateTime,
      "GPS_TRACKER_ID": gpsTrackerId,
      "LATITUDE": latitude,
      "LONGITUDE": longitude,
      "MOBILE_APP_ID": mobileAppId,
      "USERS_ID": usersId,
      "BATTERY_PERC": batteryPercentage,
      "ACCURACY": accuracy,
      "IS_MOCK": isMock,
      "PROVIDER": provider,
    };
  }
}
