abstract class HomeState {
  HomeState();
}

class HomeInitState extends HomeState {}

class HomeDataClearedState extends HomeState {}

class DownLoadingState extends HomeState {}

class DownLoadedState extends HomeState {
  String messase;
  DownLoadedState(this.messase);
}

class DownLoadedErrorState extends HomeState {
  String message;
  DownLoadedErrorState(this.message);
}

class LogoutState extends HomeState {}
