import UIKit
import Flutter
import FirebaseCore
import flutter_foreground_task
import workmanager_apple
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions:
      [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Firebase
    FirebaseApp.configure()

    // Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // IMPORTANT:
    // Register the Workmanager periodic task BEFORE
    // Dart calls registerPeriodicTask().
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.lfcrystal.syncLocation",
      frequency: NSNumber(value: 15 * 60)
    )

    // Workmanager background isolate
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // Foreground task background isolate
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // Notification delegate
    UNUserNotificationCenter.current().delegate = self

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }
}