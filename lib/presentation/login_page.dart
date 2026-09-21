import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_images.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/cubit/auth/login_cubit.dart';
import 'package:lf_crystal/cubit/auth/login_state.dart';
import 'package:lf_crystal/routes/app_routes_name.dart';
import 'package:lf_crystal/services/notification_services.dart';
import 'package:location/location.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final NotificationServices notificationServices = NotificationServices.instance;
  TextEditingController userNameC = TextEditingController();
  TextEditingController passwordC = TextEditingController();
  LocationData? locationData;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadSavedCredentials();
      // checkLoginStatus();
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted) {
      return;
    }
    try {
      // --------------------------------------------------------
      // 1. Initialize Firebase Notifications FIRST
      // --------------------------------------------------------
      await checkLoginStatus();
      // await initializeFirebaseMessaging();

      if (!mounted) return;

      // Give Android a little time to finish any notification
      // permission/lifecycle transition.
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // --------------------------------------------------------
      // 2. Check Login Status SECOND
      // --------------------------------------------------------

      // await checkLoginStatus();
      await initializeFirebaseMessaging();
    } catch (e, stackTrace) {
      debugPrint('Login page initialization error: $e');

      debugPrint('$stackTrace');
    }
  }

  Future<void> initializeFirebaseMessaging() async {
    await notificationServices.initialize(context);
  }

  Future<void> checkLoginStatus() async {
    if (!mounted) return;

    final cubit = context.read<LoginCubit>();

    await cubit.autoLogoutMethod();

    if (!mounted) return;

    final token = await StorageFunction.readStringData(StorageKey.token);

    if (!mounted) return;

    if (token == null) {
      await cubit.checkGpsPermission(context);
    }
  }

  Future<void> loadSavedCredentials() async {
    try {
      final username = await secureStorage.read(key: 'saved_username');

      final password = await secureStorage.read(key: 'saved_password');

      if (!mounted) return;

      if (username != null && username.isNotEmpty) {
        userNameC.text = username;
      }

      if (password != null && password.isNotEmpty) {
        passwordC.text = password;
      }
      setState(() {});
    } catch (e) {
      debugPrint("Error loading saved credentials: $e");
    }
  }

  @override
  void dispose() {
    userNameC.dispose();
    passwordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage(AppImages.loginBgImg), fit: BoxFit.cover)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: BlocConsumer<LoginCubit, LoginState>(
              listener: (context, state) {
                if (state is LoginErrorState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AppColors.red, content: Text(state.message, style: AppTextStyle.ts14BW)),
                  );
                  if (state.message.toLowerCase() == "unable to fetch location.") {
                    locationData = null;
                  }
                } else if (state is LoginSuccesState) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutesName.homePage, (route) => false);
                } else if (state is GetLocationState) {
                  locationData = state.locationData;
                } else if (state is LoggedInState) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutesName.homePage, (route) => false);
                }
              },
              builder: (context, state) {
                bool isPasswordVisible = false;

                if (state is ShowHidePassState) {
                  isPasswordVisible = state.isShow;
                }

                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Image.asset(AppImages.logoImg, height: height * 0.11),
                        Text("Version 1.0.0", style: AppTextStyle.ts16BW),
                        const SizedBox(height: 20),
                        AutofillGroup(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: userNameC,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username],
                                textInputAction: TextInputAction.next,
                                style: AppTextStyle.ts14RW,
                                cursorColor: AppColors.white,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(top: 15),
                                  prefixIcon: Icon(Icons.person_outline, color: AppColors.white),
                                  hintText: "Username",
                                  hintStyle: AppTextStyle.ts14MW,
                                  border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.white)),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.white)),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.white)),
                                ),
                              ),

                              TextFormField(
                                controller: passwordC,
                                obscureText: !isPasswordVisible,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                style: AppTextStyle.ts14RW,
                                cursorColor: AppColors.white,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(top: 15),
                                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.white),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                      color: AppColors.white,
                                    ),
                                    onPressed: () {
                                      context.read<LoginCubit>().showPassword(isPasswordVisible);
                                    },
                                  ),
                                  hintText: "Password",
                                  hintStyle: AppTextStyle.ts14MW,
                                  border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.white)),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.white)),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: width * 0.6,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            ),
                            onPressed: () {
                              context.read<LoginCubit>().submitMethod(
                                userName: userNameC.text,
                                password: passwordC.text,
                                context: context,
                              );
                            },
                            child:
                                state is LoginLoadingState
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                      // state is LoginLocationLoadedState ? "Got Location\nLogin Now" : "Login",
                                      locationData != null ? "Got Location\nLogin Now" : "Login",
                                      textAlign: TextAlign.center,
                                      style: AppTextStyle.ts16MW,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
