import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:lf_crystal/cubit/custom_card/custom_card_cubit.dart';
import 'package:lf_crystal/cubit/filter/filter_cubit.dart';
import 'package:lf_crystal/cubit/home/home_cubit.dart';
import 'package:lf_crystal/cubit/image_list/image_list_cubit.dart';
import 'package:lf_crystal/cubit/open_case/open_case_cubit.dart';
import 'package:lf_crystal/cubit/photo/photo_cubit.dart';
import 'package:lf_crystal/cubit/selfie/selfie_cubit.dart';
import 'package:lf_crystal/firebase_options.dart';
import 'package:lf_crystal/routes/app_routes.dart';
import 'package:lf_crystal/routes/app_routes_name.dart';
import 'package:lf_crystal/services/foreground_task_handler.dart';
import 'package:lf_crystal/services/notification_services.dart';
import 'package:lf_crystal/services/work_manager.dart';
import 'package:workmanager/workmanager.dart';

// @pragma("vm:entry-point")
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   NotificationServices().showNotification(message);
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // firebase implementation
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//   // Firebase Crashlytics
//   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
//   PlatformDispatcher.instance.onError = (error, stack) {
//     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
//     return true;
//   };
//   runApp(const MyApp());
//   Future.microtask(() async {
//     if (!kIsWeb) {
//       // ignore: deprecated_member_use
//       await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
//       FlutterForegroundTask.initCommunicationPort();
//       ForegroundTaskHandler.initService();
//     }

//     RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
//     if (initialMessage != null) {
//       NotificationServices().showNotification(initialMessage);
//     }
//   });
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(create: (context) => HomeCubit()),
//         BlocProvider(create: (context) => CustomCardCubit()),
//         BlocProvider(create: (context) => OpenCaseCubit()),
//         BlocProvider(create: (context) => PhotoCubit()),
//         BlocProvider(create: (context) => SelfieCubit()),
//         BlocProvider(create: (context) => ImageListCubit()),
//         BlocProvider(create: (context) => FilterCubit()),
//       ],
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Crystal',

//         initialRoute: AppRoutesName.loginPage,
//         onGenerateRoute: AppRoutes.generateRoute,
//       ),
//     );
//   }
// }

final NotificationServices notificationServices = NotificationServices();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await notificationServices.showNotification(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // // Initialize notification plugin only once
  // await notificationServices.initialize();

  runApp(const MyApp());

  // Perform heavy work after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!kIsWeb) {
      try {
        await Workmanager().initialize(callbackDispatcher);

        FlutterForegroundTask.initCommunicationPort();

        ForegroundTaskHandler.initService();
      } catch (e, stack) {
        FirebaseCrashlytics.instance.recordError(e, stack);
      }
    }

    try {
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        await notificationServices.showNotification(initialMessage);
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeCubit()),
        BlocProvider(create: (_) => CustomCardCubit()),
        BlocProvider(create: (_) => OpenCaseCubit()),
        BlocProvider(create: (_) => PhotoCubit()),
        BlocProvider(create: (_) => SelfieCubit()),
        BlocProvider(create: (_) => ImageListCubit()),
        BlocProvider(create: (_) => FilterCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Crystal',
        initialRoute: AppRoutesName.loginPage,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
