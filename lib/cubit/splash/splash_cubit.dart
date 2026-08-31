import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/cubit/splash/splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitState());

  Future<void> initializeApp() async {
    await Future.delayed(Duration(seconds: 2));
    emit(SplashCompletedState());
    // await Future.delayed(Duration(milliseconds: 200));
    // autoLogoutMethod();
  }

  void autoLogoutMethod() async {
    String? dateStr = await StorageFunction.readStringData(
      StorageKey.loginDateTime,
    );

    if (dateStr == null) {
      emit(SplashAutoLogoutState());
      return;
    }

    DateTime loginDateTime = DateTime.parse(dateStr);
    DateTime currentDateTime = DateTime.now();

    // Create date-only versions (removing time) for accurate date comparison
    DateTime loginDateOnly = DateTime(
      loginDateTime.year,
      loginDateTime.month,
      loginDateTime.day,
    );
    DateTime currentDateOnly = DateTime(
      currentDateTime.year,
      currentDateTime.month,
      currentDateTime.day,
    );

    // Logout if login date is before current date
    if (loginDateOnly.isBefore(currentDateOnly)) {
      await StorageFunction.removeData(StorageKey.token);
      await StorageFunction.removeData(StorageKey.refreshToken);
      await StorageFunction.removeData(StorageKey.userId);
      await StorageFunction.removeData(StorageKey.loginDateTime);
      await StorageFunction.removeData(StorageKey.isLogin);
      emit(SplashAutoLogoutState());
    }
    emit(LoggedInState());
  }
}
