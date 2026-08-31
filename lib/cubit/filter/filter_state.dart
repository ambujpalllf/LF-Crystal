abstract class FilterState {
  FilterState();
}

class FilterInitState extends FilterState {}

class FilterSuccessState extends FilterState {
  String message;
  FilterSuccessState(this.message);
}

class FilterErrorState extends FilterState {
  String message;
  FilterErrorState(this.message);
}

class TodayAppointmentState extends FilterState {
  bool appointment;
  TodayAppointmentState(this.appointment);
}

class FromDateState extends FilterState {
  DateTime? formDate;
  FromDateState(this.formDate);
}

class ToDateState extends FilterState {
  DateTime? date;
  ToDateState(this.date);
}

class SortState extends FilterState {
  String option;
  SortState(this.option);
}
