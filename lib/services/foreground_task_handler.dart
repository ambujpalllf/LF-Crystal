import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:lf_crystal/services/foreground_task_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class ForegroundTaskHandler {
  // latest request with battery optimisation
  // static Future<bool> requestPermissions() async {
  //   bool notificationGranted = true;
  //   bool batteryOptimDisabled = true;

  //   final notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
  //   if (notificationPermission != NotificationPermission.granted) {
  //     final granted = await FlutterForegroundTask.requestNotificationPermission();
  //     if (granted != NotificationPermission.granted) {
  //       notificationGranted = false;
  //     }
  //   }

  //   if (Platform.isAndroid) {
  //     final ignoringBattery = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
  //     if (!ignoringBattery) {
  //       // Optionally show user-friendly explanation here
  //       await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  //       // Cannot guarantee user accepted
  //       batteryOptimDisabled = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
  //     }
  //   }

  //   debugPrint('Notification granted: $notificationGranted, battery optimization ignored: $batteryOptimDisabled');
  //   return notificationGranted && batteryOptimDisabled;
  // }

  static Future<bool> requestPermissions() async {
    bool notificationGranted = false;
    bool batteryOptimDisabled = true;

    /// ---------- Notification Permission ----------
    try {
      final permission = await FlutterForegroundTask.checkNotificationPermission();

      if (permission == NotificationPermission.granted) {
        notificationGranted = true;
      } else {
        final result = await FlutterForegroundTask.requestNotificationPermission();

        notificationGranted = result == NotificationPermission.granted;
      }
    } on PlatformException catch (e) {
      // This happens when user dismisses dialog (Samsung issue)
      debugPrint('Notification permission cancelled: ${e.message}');
      notificationGranted = false;
    }

    /// ---------- Battery Optimization ----------
    if (Platform.isAndroid && notificationGranted) {
      try {
        final ignoringBattery = await FlutterForegroundTask.isIgnoringBatteryOptimizations;

        if (!ignoringBattery) {
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
          batteryOptimDisabled = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
        }
      } catch (e) {
        // Never crash for battery optimization
        debugPrint('Battery optimization request failed: $e');
        batteryOptimDisabled = false;
      }
    }

    debugPrint('Permission result → Notification: $notificationGranted, Battery: $batteryOptimDisabled');

    return notificationGranted && batteryOptimDisabled;
  }

  static void initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.HIGH,
        // onlyAlertOnce: true,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true, playSound: true),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(300000),
        // eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<ServiceRequestResult> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.location],
        notificationTitle: 'LiasesForas',
        notificationText: 'Liasesforas service running',
        callback: startCallback,
      );
    }
  }

  static Future<void> foregroundServiceInit(BuildContext context) async {
    final granted = await requestPermissionsSafe();

    if (!granted) {
      if (!context.mounted) return;
      await showPermissionDialog(context);
      return;
    }

    await startService();
  }

  static Future<bool> requestPermissionsSafe() async {
    try {
      final status = await FlutterForegroundTask.checkNotificationPermission();

      if (status == NotificationPermission.granted) {
        return true;
      }

      final result = await FlutterForegroundTask.requestNotificationPermission();

      return result == NotificationPermission.granted;
    } on PlatformException catch (e) {
      debugPrint('Permission cancelled: ${e.message}');
      return false;
    }
  }

  static Future<void> showPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'This app needs notification permission to run the background service properly.\n\n'
            'Please allow notification permission to continue.',
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              child: const Text('Allow'),
              onPressed: () async {
                Navigator.pop(context);

                final granted = await requestPermissionsSafe();

                if (!granted) {
                  if (!context.mounted) return;
                  // Still denied → open settings
                  await showSettingsDialog(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Enable Permission Manually'),
            content: const Text(
              'Permission was denied. Please enable notification permission '
              'from app settings to continue.',
            ),
            actions: [
              TextButton(child: const Text('Later'), onPressed: () => Navigator.pop(context)),
              ElevatedButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }
}
