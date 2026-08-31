import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

abstract class MapState {
  const MapState();
}

class MapInitState extends MapState {}

class LocationLodingState extends MapState {}

class GetLocationState extends MapInitState {
  LocationData position;
  GetLocationState(this.position);
}

class SelectLocationState extends MapInitState {
  LatLng tapPosition;
  String? locationName;
  SelectLocationState(this.tapPosition, this.locationName);
}

class MapSuccessState extends MapState {
  String message;
  MapSuccessState(this.message);
}

class MapErrorState extends MapState {
  String message;
  MapErrorState(this.message);
}

class PridictedLocations extends MapState {
  List<Map<String, dynamic>> pridictedData;
  PridictedLocations(this.pridictedData);
}
