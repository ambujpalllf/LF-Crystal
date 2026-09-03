import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/cubit/filter/filter_cubit.dart';
import 'package:lf_crystal/cubit/filter/filter_state.dart';
import 'package:lf_crystal/widget/custom_elevated_btn.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  final List<String> options = ['Assign Case DateWise Old to Latest', 'Assign Case DateWise Latest to Old', 'Completed Case DateWise Old to Latest', 'Completed Case DateWise Latest to Old', 'Appointment DateWise Old to Latest', 'Appointment DateWise Latest to Old'];

  final TextEditingController _bankNameController = TextEditingController();

  bool todayAppointment = false;

  DateTime? fromDate;

  DateTime? toDate;

  String sortOption = 'Assign Case DateWise Old to Latest';

  @override
  void dispose() {
    super.dispose();
    _bankNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Build Build");
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, leading: IconButton(onPressed: () => Navigator.pop(context, null), icon: Icon(Icons.arrow_back, color: AppColors.white)), backgroundColor: AppColors.blue, title: Text("Apply Filter", style: AppTextStyle.ts18RW)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<FilterCubit, FilterState>(
                builder: (_, state) {
                  if (state is TodayAppointmentState) {
                    todayAppointment = state.appointment;
                  }
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text("Today's Appointment", style: AppTextStyle.ts14RB),
                    value: todayAppointment,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<FilterCubit>().changeAppointment(value);
                      }
                    },
                  );
                },
              ),

              Text("Filter Visit Date :-", style: AppTextStyle.ts14MB),
              const SizedBox(height: 5.0),
              BlocBuilder<FilterCubit, FilterState>(
                builder: (_, state) {
                  if (state is FromDateState) {
                    fromDate = state.formDate;
                  } else if (state is ToDateState) {
                    toDate = state.date;
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(context: context, initialDate: fromDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                          if (picked != null && picked != fromDate) {
                            if (!context.mounted) return;
                            context.read<FilterCubit>().selectFromDate(picked);
                          }
                        },
                        child: Container(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), decoration: BoxDecoration(color: AppColors.blue), child: Text(fromDate == null ? "From Date" : DateFormat('dd MMMM yyyy').format(fromDate!), style: AppTextStyle.ts14RW)),
                      ),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(context: context, initialDate: toDate, firstDate: DateTime.now(), lastDate: DateTime(2070));
                          if (picked != null && picked != toDate) {
                            if (!context.mounted) return;
                            context.read<FilterCubit>().selectToDate(picked);
                          }
                        },
                        child: Container(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), decoration: BoxDecoration(color: AppColors.blue), child: Text(toDate == null ? "To Date" : DateFormat('dd MMMM yyyy').format(toDate!), style: AppTextStyle.ts14RW)),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 10.0),

              TextFormField(
                controller: _bankNameController,
                cursorColor: AppColors.calenderColor,
                decoration: InputDecoration(hintText: "Bank Name", hintStyle: AppTextStyle.ts14LB.copyWith(color: AppColors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.calenderColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.calenderColor))),
              ),

              const SizedBox(height: 15),
              Text("Sort by :-", style: AppTextStyle.ts12MB),

              Expanded(
                child: BlocBuilder<FilterCubit, FilterState>(
                  builder: (context, state) {
                    if (state is SortState) {
                      sortOption = state.option;
                    }
                    return ListView(
                      shrinkWrap: true,
                      clipBehavior: Clip.none,
                      physics: const NeverScrollableScrollPhysics(),
                      children:
                          options.map((option) {
                            return RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                              activeColor: AppColors.calenderColor,
                              title: Text(option, style: AppTextStyle.ts12RB),
                              value: option,
                              // ignore: deprecated_member_use
                              groupValue: sortOption,
                              // ignore: deprecated_member_use
                              onChanged: (value) {
                                if (value != null) {
                                  context.read<FilterCubit>().sortOption(value);
                                }
                              },
                            );
                          }).toList(),
                    );
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildButton(context, "CLEAR FILTER", () {
                    _bankNameController.clear();
                    context.read<FilterCubit>().changeAppointment(false);
                    context.read<FilterCubit>().selectFromDate(null);
                    context.read<FilterCubit>().selectToDate(null);
                    _bankNameController.clear();
                    sortOption = options.first;

                    Navigator.pop(context);
                  }),
                  _buildButton(context, "APPLY FILTER", () {
                    Map<String, dynamic> filterData = {"appointment": todayAppointment, "fromDate": fromDate, "toDate": toDate, "bankName": _bankNameController.text, "sortBy": sortOption};
                    Navigator.pop(context, filterData);
                  }),
                ],
              ),

              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(width: MediaQuery.of(context).size.width * 0.4, child: CustomElevatedButton(textStyle: AppTextStyle.ts14BW, borderRadius: 2.0, text: text, onPressed: onPressed));
  }
}
