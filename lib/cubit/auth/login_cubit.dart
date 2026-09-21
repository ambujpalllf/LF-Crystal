import 'dart:convert';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lf_crystal/constants/api_urls.dart';
import 'package:lf_crystal/constants/check_location_permission.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/cubit/auth/login_state.dart';
import 'package:lf_crystal/database/database_helper.dart';
import 'package:lf_crystal/services/base_client.dart';
import 'package:lf_crystal/services/notification_services.dart';
import 'package:location/location.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitState());
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  void showPassword(bool isShow) {
    emit(ShowHidePassState(!isShow));
  }

  Future<void> submitMethod({required String userName, required String password, required dynamic context}) async {
    emit(LoginLoadingState());

    if (userName.trim().isEmpty) {
      emit(LoginErrorState("User name is required."));
      return;
    }

    if (password.trim().isEmpty) {
      emit(LoginErrorState("Password is required."));
      return;
    }

    try {
      final batteryPercentage = kIsWeb ? 100 : await Battery().batteryLevel;
      final appVersion = "7.4.1"; //await getAppVersion();
      final sdkVersion = kIsWeb ? "Web" : await getSdkVersion();

      bool permission = await CheckLocationPermission.checkPermissionGps(context: context);
      if (!permission) {
        emit(LoginErrorState("Unable to fetch location."));
        return;
      }
      LocationData position = await CheckLocationPermission.getCurrentLocation();
      String firebaseToken = await NotificationServices.instance.getDeviceToken();
      final url = "${ApiUrls.baseUrl}/MobLogin";
      Map<String, dynamic> deviceInfo = await getDeviceInfo();
      final jsonInfo = jsonEncode(deviceInfo);
      debugPrint("Divice Info:  $jsonInfo");
      debugPrint("Divice Info Length:  ${jsonInfo.length}");
      final bodyData = {
        "scope": "valuer",
        "user_name": userName,
        "password": password,
        "firebase_token": firebaseToken,
        "sdk_version": sdkVersion,
        "app_version": appVersion,
        // "is_mock": position.isMocked ? 1 : 0,
        "is_mock": position.isMock != null ? (position.isMock! ? 1 : 0) : 0,
        "provider": "Flutter: $jsonInfo",
        "lat": position.latitude,
        "lng": position.longitude,
        "accuracy": position.accuracy,
        "battery_perc": batteryPercentage,
      };
      final response = await ApiServices.postRequestWithoutAuth(url, bodyData);

      // Handle error response
      if (response == null || response["status"] != "OK" || response["token"] == null) {
        TextInput.finishAutofillContext(shouldSave: false);
        emit(LoginErrorState(response?["message"] ?? "Login failed."));

        return;
      }
      final token = response["token"];
      final accessToken = token["access_token"];
      final refreshToken = token["refresh_token"];
      if (accessToken == null || refreshToken == null) {
        emit(LoginErrorState("Invalid token data."));
        return;
      }
      DateTime now = DateTime.now();
      await secureStorage.write(key: 'saved_username', value: userName.trim());
      await secureStorage.write(key: 'saved_password', value: password);
      TextInput.finishAutofillContext(shouldSave: true);
      await StorageFunction.writeStringData(StorageKey.loginDateTime, now.toIso8601String());
      await StorageFunction.writeStringData(StorageKey.token, accessToken);
      await StorageFunction.writeStringData(StorageKey.refreshToken, refreshToken);
      final dataList = response["data"];
      if (dataList != null && dataList is List && dataList.isNotEmpty) {
        final userId = dataList[0]["user_id"];
        final valuerId = dataList[0]["valuer_id"];
        if (userId != null) {
          // Clear the previous user data
          final previousUserId = await StorageFunction.readIntData(StorageKey.userId);
          if (previousUserId != null && previousUserId != userId) {
            clearAllData();
          }

          await StorageFunction.writeIntData(StorageKey.userId, userId);
          await StorageFunction.writeIntData(StorageKey.valuerId, valuerId);
        }
      }
      await StorageFunction.writeBoolData(StorageKey.isLogin, true);
      emit(LoginSuccesState(response["message"] ?? "Login successful."));
    } catch (e) {
      String errorMsg = e.toString().split(":").last;
      emit(LoginErrorState(errorMsg));
    }
  }

  void clearAllData() async {
    await StorageFunction.removeData(StorageKey.isCategoryDownload);
    await StorageFunction.removeData(StorageKey.siteIds);
    await DBHelper.clearAllData();
  }

  Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  // Function to get the SDK version
  Future<String> getSdkVersion() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.release;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.systemVersion;
    } else {
      return "Unknown SDK version";
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo android = await deviceInfo.androidInfo;

      return {
        "platform": "Android",
        "brand": android.brand,
        "model": android.model,
        "device": android.device,
        "manufacturer": android.manufacturer,
        "product": android.product,
        "androidVersion": android.version.release,
        "sdkInt": android.version.sdkInt,
        "board": android.board,
        "hardware": android.hardware,
        "isPhysicalDevice": android.isPhysicalDevice,
        "id": android.id,
      };
    }

    if (Platform.isIOS) {
      final IosDeviceInfo ios = await deviceInfo.iosInfo;

      return {
        "platform": "iOS",
        "name": ios.name,
        "model": ios.model,
        "localizedModel": ios.localizedModel,
        "systemName": ios.systemName,
        "systemVersion": ios.systemVersion,
        "identifierForVendor": ios.identifierForVendor,
        "isPhysicalDevice": ios.isPhysicalDevice,
      };
    }

    return {"platform": "Unknown"};
  }

  Future<void> checkGpsPermission(context) async {
    try {
      bool permission = await CheckLocationPermission.checkPermissionGps(context: context);
      if (!permission) return;
      LocationData locdata = await CheckLocationPermission.getCurrentLocation();
      emit(GetLocationState(locationData: locdata));
    } catch (e) {
      emit(LoginErrorState(e.toString()));
    }
  }

  Future<void> autoLogoutMethod() async {
    String? dateStr = await StorageFunction.readStringData(StorageKey.loginDateTime);

    if (dateStr == null) {
      return;
    }

    DateTime loginDateTime = DateTime.parse(dateStr);
    DateTime currentDateTime = DateTime.now();

    // Create date-only versions (removing time) for accurate date comparison
    DateTime loginDateOnly = DateTime(loginDateTime.year, loginDateTime.month, loginDateTime.day);
    DateTime currentDateOnly = DateTime(currentDateTime.year, currentDateTime.month, currentDateTime.day);

    // Logout if login date is before current date
    if (loginDateOnly.isBefore(currentDateOnly)) {
      await StorageFunction.removeData(StorageKey.token);
      await StorageFunction.removeData(StorageKey.refreshToken);
      // await StorageFunction.removeData(StorageKey.userId);
      await StorageFunction.removeData(StorageKey.loginDateTime);
      await StorageFunction.removeData(StorageKey.isLogin);
      FlutterForegroundTask.stopService();
      emit(AutoLogoutState());
    } else {
      emit(LoggedInState());
    }
  }
}
