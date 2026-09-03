import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:lf_crystal/services/work_manager.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('========================================');

  debugPrint('BACKGROUND FCM MESSAGE');

  debugPrint('Message ID: ${message.messageId}');

  debugPrint('Notification: ${message.notification}');

  debugPrint('Data: ${message.data}');

  debugPrint('========================================');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FIREBASE
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FCM BACKGROUND HANDLER
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // WORKMANAGER
  if (!kIsWeb) {
    try {
      await Workmanager().initialize(callbackDispatcher);
    } catch (e, stack) {
      debugPrint('Workmanager initialization failed: $e');

      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  // FOREGROUND TASK

  if (!kIsWeb) {
    try {
      FlutterForegroundTask.initCommunicationPort();

      ForegroundTaskHandler.initService();
    } catch (e, stack) {
      debugPrint('Foreground task initialization failed: $e');

      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  // CRASHLYTICS
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);

    return true;
  };

  // ==========================================================
  // RUN APP
  // ==========================================================

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => HomeCubit()), BlocProvider(create: (_) => CustomCardCubit()), BlocProvider(create: (_) => OpenCaseCubit()), BlocProvider(create: (_) => PhotoCubit()), BlocProvider(create: (_) => SelfieCubit()), BlocProvider(create: (_) => ImageListCubit()), BlocProvider(create: (_) => FilterCubit())],
      child: MaterialApp(debugShowCheckedModeBanner: false, title: 'Crystal', initialRoute: AppRoutesName.loginPage, onGenerateRoute: AppRoutes.generateRoute),
    );
  }
}
