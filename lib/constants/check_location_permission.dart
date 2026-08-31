import 'package:flutter/widgets.dart';
import 'package:lf_crystal/constants/dialogue_helper.dart';
import 'package:location/location.dart';
// import 'package:permission_handler/permission_handler.dart' show openAppSettings;

class CheckLocationPermission {
  static Future<bool> checkPermissionGps({required BuildContext context}) async {
    try {
      final Location location = Location();

      // Check if GPS is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return false;
        }
      }

      // Check location permission
      PermissionStatus permission = await location.hasPermission();

      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
      }

      // Check if permission is permanently denied
      if (permission == PermissionStatus.deniedForever) {
        // Show your dialog and ask the user to open app settings.
        // Example:
        if (!context.mounted) return false;
        DialogueHelper.locPermissionDialog(context);
        return false;
      }

      if (permission != PermissionStatus.granted) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<LocationData> getCurrentLocation() async {
    try {
      Location location = Location();
      LocationData locationData = await location.getLocation();
      return locationData;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }
}
