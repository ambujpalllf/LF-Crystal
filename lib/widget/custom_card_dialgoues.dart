import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/cubit/custom_card/custom_card_cubit.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/widget/custom_alert_dialog.dart';
import 'package:lf_crystal/widget/custom_elevated_btn.dart';
import 'package:lf_crystal/widget/custom_textform_field.dart';

class CustomCardDialgoues {
  static void acceptCaseDialogue({required BuildContext context, required BasicDetails basicDetails}) {
    showDialog(
      context: context,
      builder: (_) {
        return CustomAlertDialog(
          isShowCancelBtn: true,
          title: "Accept Case",
          content: "Click Yes to Accept the Case",
          onConfirm: () {
            context.read<CustomCardCubit>().acceptMethod(
              siteId: basicDetails.siteId!,
              initId: basicDetails.initId!,
              siteEngId: basicDetails.siteEngineerId!,
              basicDetails: basicDetails,
            );
          },
        );
      },
    );
  }

  static void rejectCaseDialogue({
    required BuildContext context,
    required int siteId,
    required int initId,
    required int siteEngineerId,
    required TextEditingController rejectC,
  }) {
    bool rejectError = false;
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, innerState) {
            return AlertDialog(
              actionsPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: rejectC,
                    decoration: InputDecoration(
                      suffixIcon: rejectError == true ? const Icon(Icons.error, color: Colors.red) : null,
                      hintText: "Reject Reason",
                      hintStyle: AppTextStyle.ts14MB.copyWith(color: Colors.grey),
                      border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && rejectError) {
                        innerState(() {
                          rejectError = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: CustomElevatedButton(
                      borderRadius: 2.0,
                      text: "Submit",
                      onPressed: () {
                        if (rejectC.text.isEmpty) {
                          innerState(() {
                            rejectError = true;
                          });
                        } else {
                          Navigator.pop(context);
                          context.read<CustomCardCubit>().rejectMethod(
                            siteId: siteId,
                            initId: initId,
                            siteEngineerId: siteEngineerId,
                            reason: rejectC.text,
                          );
                          rejectC.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void fixedAppointment({
    required BuildContext context,
    required int siteId,
    required int initId,
    required int siteEngineerId,
    required TextEditingController appointmentDateC,
    required TextEditingController appointmentTimeC,
    required BasicDetails basicDetails,
  }) {
    bool showDateError = false;
    bool showTimeError = false;
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (_, innerState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Appointment Date Time:", style: AppTextStyle.ts14RB.copyWith(color: AppColors.blue)),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextformField(
                          controller: appointmentDateC,
                          readOnly: true,
                          suffixIcon: showDateError ? const Icon(Icons.error, color: Colors.red) : null,
                          hintText: "Date",
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2200),
                            );
                            if (picked != null) {
                              appointmentDateC.text = DateFormat('yyyy-MM-dd').format(picked);
                              innerState(() {
                                showDateError = false;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 15.0),
                      Expanded(
                        child: CustomTextformField(
                          controller: appointmentTimeC,
                          readOnly: true,
                          suffixIcon: showTimeError ? const Icon(Icons.error, color: Colors.red) : null,
                          hintText: "Time",
                          onTap: () async {
                            final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (pickedTime != null) {
                              final now = DateTime.now();
                              final dateTime = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              appointmentTimeC.text = DateFormat('hh:mm a').format(dateTime);
                              innerState(() {
                                showTimeError = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: CustomElevatedButton(
                      borderRadius: 4.0,
                      backgroundColor: AppColors.black,
                      text: "Submit",
                      onPressed: () {
                        if (appointmentDateC.text.isEmpty && appointmentTimeC.text.isEmpty) {
                          innerState(() {
                            showDateError = true;
                            showTimeError = true;
                          });
                        } else if (appointmentDateC.text.isEmpty) {
                          innerState(() => showDateError = true);
                        } else if (appointmentTimeC.text.isEmpty) {
                          innerState(() => showTimeError = true);
                        } else {
                          context.read<CustomCardCubit>().fixAppointmentMethod(
                            date: appointmentDateC.text,
                            time: appointmentTimeC.text,
                            siteId: siteId,
                            initId: initId,
                            siteEngineerId: siteEngineerId,
                            basicDetails: basicDetails,
                          );
                          appointmentDateC.clear();
                          appointmentTimeC.clear();
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void removeDialogue({
    required BuildContext context,
    required int siteId,
    required int initId,
    required int siteEngineerId,
    required TextEditingController rejectC,
  }) {
    bool hasError = false;
    bool isLoading = false;
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, innerState) {
            return AlertDialog(
              actionsPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: rejectC,
                    decoration: InputDecoration(
                      suffixIcon: hasError ? const Icon(Icons.error, color: Colors.red) : null,
                      hintText: "Reject Reason",
                      hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                      border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: CustomElevatedButton(
                      borderRadius: 0,
                      isLoading: isLoading,
                      onPressed: () {
                        innerState(() {
                          isLoading = true;
                        });
                        if (rejectC.text.trim().isEmpty) {
                          innerState(() {
                            hasError = true;
                          });
                        } else {
                          Navigator.pop(context);
                          context.read<CustomCardCubit>().rejectMethod(
                            siteId: siteId,
                            initId: initId,
                            siteEngineerId: siteEngineerId,
                            reason: rejectC.text,
                          );
                          innerState(() {
                            isLoading = false;
                          });
                        }
                      },
                      text: "Submit",
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void changeAppointmentDialogue({
    required BuildContext context,
    required TextEditingController appointmentRemarkC,
    required TextEditingController appointmentDateC,
    required TextEditingController appointmentTimeC,
    required int siteId,
    required int initId,
    required int siteEngId,
    required BasicDetails basicDetails,
  }) {
    bool showRemarkError = false;
    bool showDateError = false;
    bool showTimeError = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, innerState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextformField(
                      controller: appointmentRemarkC,
                      suffixIcon: showRemarkError ? Icon(Icons.error, color: Colors.red) : null,
                      cursorColor: AppColors.blue,
                      hintText: "Appointment Remarks:",
                      hintTextColor: AppColors.blue,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          innerState(() => showRemarkError = false);
                        }
                      },
                    ),
                    const SizedBox(height: 15.0),
                    Text("Appointment Date Time:", style: AppTextStyle.ts14RB.copyWith(color: AppColors.blue)),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextformField(
                            controller: appointmentDateC,
                            readOnly: true,
                            suffixIcon: showDateError ? const Icon(Icons.error, color: Colors.red) : null,
                            hintText: "Date",
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2200),
                              );
                              if (picked != null) {
                                appointmentDateC.text = DateFormat('yyyy-MM-dd').format(picked);
                                innerState(() {
                                  showDateError = false;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 15.0),
                        Expanded(
                          child: CustomTextformField(
                            controller: appointmentTimeC,
                            readOnly: true,
                            suffixIcon: showTimeError ? const Icon(Icons.error, color: Colors.red) : null,
                            hintText: "Time",
                            onTap: () async {
                              final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                              if (pickedTime != null) {
                                final now = DateTime.now();
                                final dateTime = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                                appointmentTimeC.text = DateFormat('hh:mm a').format(dateTime);
                                innerState(() {
                                  showTimeError = false;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15.0),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: CustomElevatedButton(
                        borderRadius: 4.0,
                        backgroundColor: AppColors.black,
                        text: "Submit",
                        onPressed: () {
                          if (appointmentRemarkC.text.isEmpty) {
                            innerState(() => showRemarkError = true);
                          } else if (appointmentDateC.text.isEmpty) {
                            innerState(() => showDateError = true);
                          } else if (appointmentTimeC.text.isEmpty) {
                            innerState(() => showTimeError = true);
                          } else {
                            context.read<CustomCardCubit>().changeAppointment(
                              dates: appointmentDateC.text,
                              times: appointmentTimeC.text,
                              siteId: siteId,
                              initId: initId,
                              siteEngId: siteEngId,
                              remarks: appointmentRemarkC.text,
                              basicDetails: basicDetails,
                            );
                            appointmentRemarkC.clear();
                            appointmentDateC.clear();
                            appointmentTimeC.clear();
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
