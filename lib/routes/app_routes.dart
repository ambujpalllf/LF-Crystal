import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/cubit/auth/login_cubit.dart';
import 'package:lf_crystal/cubit/map/map_cubit.dart';
import 'package:lf_crystal/cubit/measurement_details/measurement_cubit.dart';
import 'package:lf_crystal/cubit/splash/splash_cubit.dart';
import 'package:lf_crystal/presentation/home_page.dart';
import 'package:lf_crystal/presentation/login_page.dart';
import 'package:lf_crystal/presentation/map_page.dart';
import 'package:lf_crystal/presentation/measurement_details_page.dart';
import 'package:lf_crystal/presentation/splash_page.dart';
import 'package:lf_crystal/presentation/survey_details_page.dart';
import 'package:lf_crystal/routes/app_routes_name.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutesName.splashPage:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(create: (context) => SplashCubit(), child: const SplashPage()),
        );
      case AppRoutesName.loginPage:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(create: (context) => LoginCubit(), child: const LoginPage()),
        );
      case AppRoutesName.homePage:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case AppRoutesName.survayDetailsPage:
        int siteId = 0;
        int index = 0;
        int initId = 0;
        int siteEngId = 0;
        int siteSubmitted = 0;
        int bankId = 0;
        String applicantName = "";
        final args = settings.arguments as Map<String, dynamic>;
        siteId = args["siteId"];
        index = args["index"];
        initId = args["initId"];
        siteEngId = args["siteEngId"];
        siteSubmitted = args["siteSubmitted"];
        bankId = args["bankId"];
        applicantName = args["applicantName"];
        return MaterialPageRoute(
          builder:
              (_) => SurveyDetailsPage(
                siteId: siteId,
                index: index,
                initId: initId,
                siteEngId: siteEngId,
                siteSubmitted: siteSubmitted,
                bankId: bankId,
                applicantName: applicantName,
              ),
        );
      case AppRoutesName.mapPage:
        return MaterialPageRoute(builder: (_) => BlocProvider(create: (context) => MapCubit(), child: const MapPage()));
      case AppRoutesName.measurementDetailsPage:
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder:
              (_) => BlocProvider(create: (context) => MeasurementCubit(), child: MeasurementDetailsPage(value: args)),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => SafeArea(child: Scaffold(body: Center(child: Text("No route defined for ${settings.name}")))),
        );
    }
  }
}
