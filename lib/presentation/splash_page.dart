import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/constants/app_images.dart';
import 'package:lf_crystal/cubit/splash/splash_cubit.dart';
import 'package:lf_crystal/cubit/splash/splash_state.dart';
import 'package:lf_crystal/routes/app_routes_name.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    context.read<SplashCubit>().initializeApp();
    // context.read<SplashCubit>().autoLogoutMethod();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashCompletedState) {
          context.read<SplashCubit>().autoLogoutMethod();
        } else if (state is SplashAutoLogoutState) {
          Navigator.pushReplacementNamed(context, AppRoutesName.loginPage);
          // Navigator.pushReplacementNamed(context, AppRoutesName.homePage);
        } else if (state is LoggedInState) {
          // Navigator.pushReplacementNamed(context, AppRoutesName.loginPage);
          Navigator.pushReplacementNamed(context, AppRoutesName.homePage);
        }
      },
      child: Scaffold(
        body: SafeArea(child: Center(child: Image.asset(AppImages.logoImg, height: 150, fit: BoxFit.fill))),
      ),
    );
  }
}
