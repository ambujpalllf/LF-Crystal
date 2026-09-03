import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/model/location_model.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskManager());
}

class ForegroundTaskManager extends TaskHandler {
  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      // Check if location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      // Check location permission.
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return;
      }

      // Get current position.
      Position position = await Geolocator.getCurrentPosition();

      debugPrint('Location: $position');

      final userId = await StorageFunction.readIntData(StorageKey.userId);

      final battery = Battery();
      final batteryPercentage = await battery.batteryLevel;

      final timestamp = DateTime.now();

      LocationModel locData = LocationModel(
        gpsTrackerDateTime: DateFormat("yyyy-MM-dd HH:mm:ss.000").format(timestamp),
        latitude: position.latitude,
        longitude: position.longitude,
        mobileAppId: 3,
        usersId: userId ?? 0,
        accuracy: position.accuracy,
        batteryPercentage: batteryPercentage,
        isMock: position.isMocked.toString(),
        provider: position.floor?.toString() ?? "gps", // or simply "gps"
      );

      await DBHelper.insertLocation(locData);
    } catch (e, stackTrace) {
      debugPrint("Location Error: $e");
      debugPrint(stackTrace.toString());
    }
  }

  // Called based on the eventAction set in ForegroundTaskOptions.
  @override
  void onRepeatEvent(DateTime timestamp) async {
    try {
      // Check if location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      // Check location permission.
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return;
      }

      // Get current position.
      Position position = await Geolocator.getCurrentPosition();

      debugPrint('Location: $position');

      final userId = await StorageFunction.readIntData(StorageKey.userId);

      final battery = Battery();
      final batteryPercentage = await battery.batteryLevel;

      final timestamp = DateTime.now();

      LocationModel locData = LocationModel(
        gpsTrackerDateTime: DateFormat("yyyy-MM-dd HH:mm:ss.000").format(timestamp),
        latitude: position.latitude,
        longitude: position.longitude,
        mobileAppId: 3,
        usersId: userId ?? 0,
        accuracy: position.accuracy,
        batteryPercentage: batteryPercentage,
        isMock: position.isMocked.toString(),
        provider: position.floor?.toString() ?? "gps", // or simply "gps"
      );

      await DBHelper.insertLocation(locData);
    } catch (e, stackTrace) {
      debugPrint("Location Error: $e");
      debugPrint(stackTrace.toString());
    }
  }

  // Called when the task is destroyed.
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('onDestroy(isTimeout: $isTimeout)');
    try {
      // Check if location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      // Check location permission.
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return;
      }

      // Get current position.
      Position position = await Geolocator.getCurrentPosition();

      debugPrint('Location: $position');

      final userId = await StorageFunction.readIntData(StorageKey.userId);

      final battery = Battery();
      final batteryPercentage = await battery.batteryLevel;

      final timestamp = DateTime.now();

      LocationModel locData = LocationModel(
        gpsTrackerDateTime: DateFormat("yyyy-MM-dd HH:mm:ss.000").format(timestamp),
        latitude: position.latitude,
        longitude: position.longitude,
        mobileAppId: 3,
        usersId: userId ?? 0,
        accuracy: position.accuracy,
        batteryPercentage: batteryPercentage,
        isMock: position.isMocked.toString(),
        provider: position.floor?.toString() ?? "gps", // or simply "gps"
      );

      await DBHelper.insertLocation(locData);
    } catch (e, stackTrace) {
      debugPrint("Location Error: $e");
      debugPrint(stackTrace.toString());
    }
    FlutterForegroundTask.stopService();
  }

  // Called when data is sent using `FlutterForegroundTask.sendDataToTask`.
  @override
  void onReceiveData(Object data) {
    debugPrint('onReceiveData: $data');
  }

  // Called when the notification button is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    debugPrint('onNotificationButtonPressed: $id');
  }

  // Called when the notification itself is pressed.
  @override
  void onNotificationPressed() {
    debugPrint('onNotificationPressed');
  }

  // Called when the notification itself is dismissed.
  @override
  void onNotificationDismissed() {
    debugPrint('onNotificationDismissed');
  }
}
