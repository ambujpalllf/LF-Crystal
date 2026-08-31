import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lf_crystal/constants/check_location_permission.dart';
import 'package:lf_crystal/cubit/map/map_state.dart';
import 'package:lf_crystal/services/base_client.dart';
import 'package:location/location.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(MapInitState());

  void getCurrentLocation() async {
    try {
      LocationData? currentLocation = await CheckLocationPermission.getCurrentLocation();

      emit(GetLocationState(currentLocation));
    } catch (e) {
      String errorMsg = e.toString().split(":").first;
      emit(MapErrorState(errorMsg));
    }
  }

  // void onMapSelectLocation(LatLng tapPosition) {
  //   emit(SelectLocationState(tapPosition, ""));
  // }
  Future<void> onMapSelectLocation(LatLng tapPosition) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(tapPosition.latitude, tapPosition.longitude);
      Placemark place = placemarks.first;
      String address = '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      emit(SelectLocationState(tapPosition, address));
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(SelectLocationState(tapPosition, ""));
      emit(MapErrorState("Error in reverse geocoding: $errorMsg"));
    }
  }

  void getSuggestions(String input) async {
    try {
      String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request = '$baseURL?input=$input&key=AIzaSyB6LqzUDIGa_F8MYq-dO2sbOZz6oKLwxy0&components=country:in';
      var response = await ApiServices.getRequestWithoutAuth(request);
      if (response['status'] == 'OK') {
        var predictions = List<Map<String, dynamic>>.from(response['predictions']);
        emit(PridictedLocations(predictions));
      } else {
        emit(MapErrorState('Failed to fetch suggestions: ${response['status']}'));
      }
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(MapErrorState(errorMsg));
    }
  }

  void selectPlace(String placeId) async {
    try {
      String detailsUrl =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=AIzaSyB6LqzUDIGa_F8MYq-dO2sbOZz6oKLwxy0';
      var response = await ApiServices.getRequestWithoutAuth(detailsUrl);
      if (response["status"] == "OK") {
        var location = response['result']['geometry']['location'];
        String placeName = response['result']['name'];
        LatLng latLng = LatLng(location['lat'], location['lng']);
        // emit(SelectLocationState(tapPosition: latLng, locationName: placeName));
        emit(SelectLocationState(latLng, placeName));
      } else {
        emit(MapErrorState('Failed to fetch location: ${response['status']}'));
      }
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(MapErrorState(errorMsg.trim()));
    }
  }
}
