import 'dart:io';
import 'dart:math';
// import 'dart:math';
import 'package:app_settings/app_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Request Notification Permission
  void requestNotificationPermission() async {
    try {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint("User  granted permission.");
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint("User granted provisional.");
      } else {
        AppSettings.openAppSettings(type: AppSettingsType.notification);
        debugPrint("Permission is  denied.");
      }
      // Also request local notification permission for iOS
      if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint("$e");
    }
  }

  // Future<String> getDeviceToken() async {
  //   try {
  //     if (Platform.isIOS) {
  //     final deviceInfo = DeviceInfoPlugin();
  //     final iosInfo = await deviceInfo.iosInfo;
  //     if (!iosInfo.isPhysicalDevice) {
  //       debugPrint("Skipping FCM token fetch on iOS Simulator.");
  //       return "";
  //     }
  //   }
  //     String? token = await messaging.getToken();
  //     if (token != null) {
  //       debugPrint("Device Token: $token");
  //       return token;
  //     } else {
  //       FirebaseCrashlytics.instance.log("Device token is null.");
  //       return "";
  //     }
  //   } catch (e, stack) {
  //     FirebaseCrashlytics.instance.recordError(
  //       e,
  //       stack,
  //       reason: "Failed to get FCM device token",
  //     );
  //     return "";
  //   }
  // }

  Future<String> getDeviceToken() async {
    try {
      if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        if (!iosInfo.isPhysicalDevice) {
          debugPrint(" Skipping FCM token fetch on iOS Simulator.");
          return "";
        }

        //  Wait for APNs token
        String? apnsToken;
        int retry = 0;
        while (apnsToken == null && retry < 5) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken == null) {
            await Future.delayed(Duration(seconds: 1));
            retry++;
          }
        }

        if (apnsToken == null) {
          return "";
        }

        debugPrint("APNs Token: $apnsToken");
      }

      // Now safe to call getToken()
      String? token = await messaging.getToken();
      if (token != null) {
        debugPrint("FCM Device Token: $token");
        return token;
      } else {
        return "";
      }
    } catch (e) {
      debugPrint("$e");
      return "";
    }
  }

  void isTokenRefresh() {
    messaging.onTokenRefresh.listen((event) {
      event.toString();
    });
  }

  // when application is active in android and ios
  void firebaseInit(context) {
    FirebaseMessaging.onMessage.listen((message) async {
      try {
        if (Platform.isIOS) {
          await foregroundMessage();
          if (message.notification == null && message.data.isNotEmpty) {
            await showNotification(message);
          }
        } else if (Platform.isAndroid) {
          initLocalNotification(context, message);
          showNotification(message);
        }
      } catch (e) {
        debugPrint("$e");
      }
    });
  }

  // initialize show notification method
  void initLocalNotification(BuildContext context, RemoteMessage message) async {
    try {
      var androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosInitializationSettings = const DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      var initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (payload) {
          handleMessage(context, message);
        },
      );
    } catch (e) {
      debugPrint("$e");
    }
  }

  // show local notifiaction
  Future<void> showNotification(RemoteMessage message) async {
    try {
      AndroidNotificationChannel channel = AndroidNotificationChannel(
        // Random.secure().nextInt(1000).toString(),
        'high_importance_channel',
        "High Importance Notification",
        importance: Importance.max,
      );

      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        channel.id.toString(),
        channel.name.toString(),
        channelDescription: "This channel is used for important notifications.",
        // importance: Importance.high,
        importance: Importance.max,
        priority: Priority.high,
        ticker: "ticker",
      );

      DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );
      Future.delayed(Duration.zero, () {
        _flutterLocalNotificationsPlugin.show(
          // 0,
          // If you use a unique notification ID, Android creates a new notification each time.
          // If you use the same notification ID, Android updates/replaces the existing notification
          // instead of creating a new one.
          Random().nextInt(100000),
          // message.notification?.title.toString(),
          "LiasesForas Crystal Valuation",
          // message.notification?.body.toString(),
          "New Case is assign to you. Please open the app to check the details",
          notificationDetails,
        );
      });
    } catch (e) {
      debugPrint("$e");
    }
  }

  // handle Navigation
  void handleMessage(BuildContext context, RemoteMessage message) {
    if (message.data["type"] == "Msg") {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => MessagePage()));
    }
  }

  // When our application in background state
  Future<void> setUpInteractMessage(context) async {
    try {
      //When App is terminated state
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        handleMessage(context, initialMessage);
      }

      // When App is in background.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        handleMessage(context, message);
      });
    } catch (e) {
      debugPrint("$e");
    }
  }

  // For IOS Push Notification you have an iCloud Account it just as gmail account

  // For Ios Froreground Message
  Future foregroundMessage() async {
    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint("$e");
    }
  }
}
