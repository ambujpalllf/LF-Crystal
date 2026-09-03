import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServices {
  NotificationServices._privateConstructor();

  static final NotificationServices instance = NotificationServices._privateConstructor();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // ============================================================
  // INITIALIZE EVERYTHING
  // ============================================================

  Future<void> initialize(BuildContext context) async {
    try {
      // 1. Initialize local notifications
      await _initializeLocalNotifications(context);

      // 2. Request Firebase notification permission
      await _requestNotificationPermission();

      // 3. Configure foreground notification behavior
      await _configureForegroundNotifications();
      if (!context.mounted) return;
      // 4. Listen for foreground messages
      _listenToForegroundMessages(context);

      // 5. Handle notification taps
      await setupInteractedMessage(context);

      // 6. Get FCM token
      await getDeviceToken();

      // 7. Listen for token refresh
      listenToTokenRefresh();
    } catch (e, stackTrace) {
      debugPrint('Notification initialization error: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // LOCAL NOTIFICATION INITIALIZATION
  // ============================================================

  Future<void> _initializeLocalNotifications(BuildContext context) async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false, requestCriticalPermission: false);

      const InitializationSettings initializationSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Local notification tapped: ${response.payload}');

          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final Map<String, dynamic> data = jsonDecode(response.payload!);

              final RemoteMessage message = RemoteMessage(data: Map<String, String>.from(data.map((key, value) => MapEntry(key, value.toString()))));

              handleMessage(context, message);
            } catch (e) {
              debugPrint('Notification payload parse error: $e');
            }
          }
        },
      );

      // Android notification channel
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel('high_importance_channel', 'High Importance Notification', description: 'This channel is used for important notifications.', importance: Importance.max);

        await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
      }

      debugPrint('Local notification initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Local notification initialization error: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // REQUEST FIREBASE NOTIFICATION PERMISSION
  // ============================================================

  Future<void> _requestNotificationPermission() async {
    try {
      final NotificationSettings settings = await messaging.requestPermission(alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true);

      debugPrint(
        'FCM permission status: '
        '${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission.');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permission.');
      } else {
        debugPrint('Notification permission denied.');

        // Optional:
        // AppSettings.openAppSettings(
        //   type: AppSettingsType.notification,
        // );
      }

      // Local notification permission on iOS/macOS
      if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosPlugin = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

        await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
      }
      // // --------------------------------------------------------
      // // ANDROID 13+
      // // --------------------------------------------------------

      // if (Platform.isAndroid) {
      //   final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      //   await androidPlugin?.requestNotificationsPermission();
      // }
    } catch (e, stackTrace) {
      debugPrint('Permission request error: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // FOREGROUND NOTIFICATION CONFIGURATION
  // ============================================================

  Future<void> _configureForegroundNotifications() async {
    try {
      /*
       * IMPORTANT:
       *
       * We set these to FALSE because we are going to display
       * the notification ourselves using flutter_local_notifications
       * when the app is in foreground.
       *
       * This prevents duplicate notifications on iOS.
       */
      await messaging.setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false);

      debugPrint('Foreground notification presentation configured.');
    } catch (e) {
      debugPrint('Foreground configuration error: $e');
    }
  }

  // ============================================================
  // FOREGROUND FCM MESSAGE
  // ============================================================

  void _listenToForegroundMessages(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        debugPrint('========================================');
        debugPrint('FOREGROUND FCM MESSAGE');
        debugPrint('Message ID: ${message.messageId}');
        debugPrint('Notification: ${message.notification}');
        debugPrint('Data: ${message.data}');
        debugPrint('========================================');

        /*
           * Whether notification + data OR data-only,
           * we show our own local notification while
           * the app is in foreground.
           */
        await showNotification(message);
      } catch (e, stackTrace) {
        debugPrint('Foreground message error: $e');
        debugPrint('$stackTrace');
      }
    });
  }

  // ============================================================
  // SHOW LOCAL NOTIFICATION
  // ============================================================

  Future<void> showNotification(RemoteMessage message) async {
    try {
      String title = 'LiasesForas Crystal Valuation';

      String body = 'New Case is assigned to you. Please open the app to check the details.';

      /*
       * If FCM contains notification title/body,
       * use them.
       *
       * Otherwise use your default title/body.
       */
      if (message.notification?.title != null && message.notification!.title!.isNotEmpty) {
        title = message.notification!.title!;
      }

      if (message.notification?.body != null && message.notification!.body!.isNotEmpty) {
        body = message.notification!.body!;
      }

      final String payload = jsonEncode(message.data);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails('high_importance_channel', 'High Importance Notification', channelDescription: 'This channel is used for important notifications.', importance: Importance.max, priority: Priority.high, ticker: 'ticker', playSound: true);

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);

      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final int notificationId = Random().nextInt(100000);

      await _flutterLocalNotificationsPlugin.show(notificationId, title, body, notificationDetails, payload: payload);

      debugPrint('Local notification displayed successfully.');
    } catch (e, stackTrace) {
      debugPrint('showNotification error: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // FCM TOKEN
  // ============================================================

  Future<String> getDeviceToken() async {
    try {
      if (Platform.isIOS) {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

        if (!iosInfo.isPhysicalDevice) {
          debugPrint('Skipping FCM token fetch on iOS Simulator.');
          return '';
        }

        // Wait for APNs token
        String? apnsToken;

        int retry = 0;

        while (apnsToken == null && retry < 10) {
          apnsToken = await messaging.getAPNSToken();

          if (apnsToken == null) {
            debugPrint(
              'Waiting for APNs token... '
              'attempt ${retry + 1}',
            );

            await Future.delayed(const Duration(seconds: 1));

            retry++;
          }
        }

        if (apnsToken == null) {
          debugPrint('APNs token could not be obtained.');

          return '';
        }

        debugPrint('APNs Token: $apnsToken');
      }

      final String? fcmToken = await messaging.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('FCM Device Token: $fcmToken');

        return fcmToken;
      }

      debugPrint('FCM token is null.');

      return '';
    } catch (e, stackTrace) {
      debugPrint('getDeviceToken error: $e');
      debugPrint('$stackTrace');

      return '';
    }
  }

  // ============================================================
  // TOKEN REFRESH
  // ============================================================

  void listenToTokenRefresh() {
    messaging.onTokenRefresh.listen((String token) {
      debugPrint('FCM token refreshed: $token');

      /*
         * IMPORTANT:
         *
         * Send this new token to your backend here.
         */
    });
  }

  // ============================================================
  // HANDLE NOTIFICATION TAP
  // ============================================================

  void handleMessage(BuildContext context, RemoteMessage message) {
    try {
      debugPrint('Handling notification: ${message.data}');

      final String? type = message.data['type'];

      final String? initId = message.data['init_id'];

      final String? siteEngineerId = message.data['site_engineer_id'];

      debugPrint('Type: $type');
      debugPrint('Init ID: $initId');
      debugPrint('Site Engineer ID: $siteEngineerId');

      /*
       * Example:
       *
       * if (type == "Msg") {
       *   Navigator.push(
       *     context,
       *     MaterialPageRoute(
       *       builder: (_) => MessagePage(),
       *     ),
       *   );
       * }
       *
       * For your case:
       *
       * Navigator.push(
       *   context,
       *   MaterialPageRoute(
       *     builder: (_) => CaseDetailsPage(
       *       initId: initId!,
       *     ),
       *   ),
       * );
       */
    } catch (e) {
      debugPrint('handleMessage error: $e');
    }
  }

  // ============================================================
  // BACKGROUND / TERMINATED NOTIFICATION TAP
  // ============================================================

  Future<void> setupInteractedMessage(BuildContext context) async {
    try {
      // --------------------------------------------------------
      // App was TERMINATED and opened by tapping notification
      // --------------------------------------------------------

      final RemoteMessage? initialMessage = await messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint('App opened from terminated notification:');

        debugPrint('${initialMessage.data}');

        /*
         * Wait until Flutter UI is ready before navigation.
         */
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleMessage(context, initialMessage);
        });
      }

      // --------------------------------------------------------
      // App was BACKGROUND and opened by tapping notification
      // --------------------------------------------------------

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from background notification:');

        debugPrint('${message.data}');
        if (!context.mounted) return;
        handleMessage(context, message);
      });
    } catch (e, stackTrace) {
      debugPrint('setupInteractedMessage error: $e');
      debugPrint('$stackTrace');
    }
  }
}
