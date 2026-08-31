import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

abstract class LoginState {
  LoginState();
}

class LoginInitState extends LoginState {}

class ShowHidePassState extends LoginState {
  final bool isShow;
  ShowHidePassState(this.isShow);
}

class LoginLoadingState extends LoginState {}

class LoginErrorState extends LoginState {
  final String message;
  LoginErrorState(this.message);
}

class LoginSuccesState extends LoginState {
  final String message;
  LoginSuccesState(this.message);
}

class LoginLocationLoadedState extends LoginState {
  final Position position;
  LoginLocationLoadedState(this.position);
}

class AutoLogoutState extends LoginState {}

class LoggedInState extends LoginState {}

class GetLocationState extends LoginState {
  LocationData locationData;
  GetLocationState({required this.locationData});
}
