import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/cubit/filter/filter_state.dart';

class FilterCubit extends Cubit<FilterState> {
  FilterCubit() : super(FilterInitState());

  void changeAppointment(bool appointment) {
    emit(TodayAppointmentState(appointment));
  }

  void selectFromDate(DateTime? date) {
    emit(FromDateState(date));
  }

  void selectToDate(DateTime? date) {
    emit(ToDateState(date));
  }

  void sortOption(String option) {
    emit(SortState(option));
  }
}
