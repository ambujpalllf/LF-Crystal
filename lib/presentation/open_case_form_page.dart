import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/constants/check_location_permission.dart';
import 'package:lf_crystal/cubit/open_case/open_case_cubit.dart';
import 'package:lf_crystal/cubit/open_case/open_case_state.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/routes/app_routes_name.dart';
import 'package:lf_crystal/widget/custom_alert_dialog.dart';
import 'package:lf_crystal/widget/custom_date_picker.dart';
import 'package:lf_crystal/widget/custom_elevated_btn.dart';
import 'package:lf_crystal/widget/custom_textform_field.dart';
import 'package:lf_crystal/widget/multi_select_dropdown.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenCaseFormPage extends StatefulWidget {
  final int siteId;
  final int initId;
  final int siteEngId;
  final int siteSubmitted;
  const OpenCaseFormPage({
    super.key,
    required this.siteId,
    required this.initId,
    required this.siteEngId,
    required this.siteSubmitted,
  });

  @override
  State<OpenCaseFormPage> createState() => _OpenCaseFormPageState();
}

class _OpenCaseFormPageState extends State<OpenCaseFormPage> {
  late List<TextEditingController?> textBoxC;
  late List<TextEditingController?> textAreaC;
  late List<String?> dropdownValues;
  late List<List<String>?> multiDropdownValues;
  late List<TextEditingController?> dateControllers;

  void initFileds(List<Field> fields) {
    textBoxC =
        fields.map((itemData) {
          if (itemData.type == "TEXTBOX") {
            return TextEditingController(text: itemData.value?.toString() ?? '');
          } else {
            return null;
          }
        }).toList();
    textAreaC =
        fields.map((itemData) {
          if (itemData.type == "TEXTAREA") {
            return TextEditingController(text: itemData.value?.toString() ?? '');
          } else {
            return null;
          }
        }).toList();
    dropdownValues =
        fields.map((itemData) {
          if (itemData.type == "COMBOBOX") {
            return itemData.value?.toString();
          } else {
            return null;
          }
        }).toList();

    multiDropdownValues =
        fields.map((itemData) {
          if (itemData.type == "MULTISELECT") {
            if (itemData.value is List) {
              return List<String>.from(itemData.value as List);
            } else if (itemData.value is String) {
              final str = itemData.value as String;
              return str.isNotEmpty ? str.split(',').map((e) => e.trim()).toList() : <String>[];
            } else {
              return <String>[];
            }
          }
          return null;
        }).toList();

    dateControllers =
        fields.map((itemData) {
          if (itemData.type == "DATE") {
            return TextEditingController(text: itemData.value?.toString() ?? '');
          }
          return null;
        }).toList();
  }

  TextInputType _getKeyboardType(String? dataType) {
    switch (dataType) {
      case "contact":
      case "int":
      case "float":
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    final formats = [
      'yyyy-MM-ddTHH:mm:ss',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'yyyy-MMM-dd hh:mm:ss:a',
      'yyyy-MMMM-dd hh:mm:ss:a',
      'dd MMM yyyy',
    ];

    for (var pattern in formats) {
      try {
        return DateFormat(pattern).parseStrict(dateStr);
      } catch (_) {
        // Try next
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocConsumer<OpenCaseCubit, OpenCaseState>(
          buildWhen: (previous, current) {
            return current is OpenCaseLoadedState;
          },
          builder: (context, state) {
            if (state is OpenCaseLoadingState) {
              return Center(child: CircularProgressIndicator());
            } else if (state is OpenCaseLoadedState) {
              initFileds(state.fields);

              return Stack(
                children: [
                  Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: state.fields.length,
                                  itemBuilder: (context, index) {
                                    final latIndex = state.fields.indexWhere((item) => item.label == "Latitude *");
                                    final lngIndex = state.fields.indexWhere((item) => item.label == "Longitude *");
                                    var itemData = state.fields[index];
                                    List<SpinnerMaster> dropdownList = [];
                                    List<String> multiDropdownItems = [];
                                    if (itemData.type == "COMBOBOX") {
                                      dropdownList = state.spinnerMaster[itemData.name] ?? [];
                                    }
                                    if (itemData.type == "MULTISELECT") {
                                      List<SpinnerMaster> options = state.spinnerMaster[itemData.name] ?? [];

                                      multiDropdownItems = options.map((e) => e.value!).toList();
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 20.0),
                                      child: Column(
                                        children: [
                                          itemData.type == "TEXTBOX"
                                              ? (itemData.label == "Latitude *" || itemData.label == "Longitude *")
                                                  ? InkWell(
                                                    onLongPress: () async {
                                                      // bool permission = await Utils.checkLGpsRequestPermission();
                                                      bool permission =
                                                          await CheckLocationPermission.checkPermissionGps(
                                                            context: context,
                                                          );

                                                      if (permission) {
                                                        // var location = await Utils.getCurrentLocation();
                                                        var location =
                                                            await CheckLocationPermission.getCurrentLocation();
                                                        final latText = location.latitude.toString();
                                                        final lngText = location.longitude.toString();

                                                        textBoxC[latIndex]!.text = latText;
                                                        textBoxC[lngIndex]!.text = lngText;

                                                        state.fields[latIndex].value = latText;
                                                        state.fields[lngIndex].value = lngText;
                                                      }
                                                      // else {
                                                      //   if (!context.mounted) return;
                                                      //   Utils.showPermissionDialog(context: context);
                                                      // }
                                                    },
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              "${itemData.label} (long press below to get value)",
                                                              style: AppTextStyle.ts14MB.copyWith(
                                                                color:
                                                                    itemData.isMandatory == true
                                                                        ? AppColors.red
                                                                        : AppColors.black,
                                                              ),
                                                            ),
                                                            itemData.label == "Longitude *"
                                                                ? SizedBox.shrink()
                                                                : Expanded(
                                                                  child: IconButton(
                                                                    visualDensity: VisualDensity(vertical: -4),
                                                                    onPressed: () async {
                                                                      bool permission =
                                                                          await CheckLocationPermission.checkPermissionGps(
                                                                            context: context,
                                                                          );
                                                                      // if (!permission) {
                                                                      // if (!context.mounted) return;
                                                                      // Utils.showPermissionDialog(context: context);
                                                                      // return;
                                                                      // }
                                                                      if (!permission) return;
                                                                      if (!context.mounted) return;
                                                                      final result = await Navigator.pushNamed(
                                                                        context,
                                                                        AppRoutesName.mapPage,
                                                                      );
                                                                      if (result != null && result is LatLng) {
                                                                        textBoxC[latIndex]!.text =
                                                                            result.latitude.toString();
                                                                        textBoxC[lngIndex]!.text =
                                                                            result.longitude.toString();
                                                                        state.fields[latIndex].value =
                                                                            result.latitude.toString();
                                                                        state.fields[lngIndex].value =
                                                                            result.longitude.toString();
                                                                      }
                                                                    },
                                                                    icon: Icon(Icons.location_on, color: AppColors.red),
                                                                  ),
                                                                ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 5.0),
                                                        AbsorbPointer(
                                                          child: CustomTextformField(
                                                            keyboardType: _getKeyboardType(itemData.dataType),
                                                            controller: textBoxC[index],
                                                            readOnly: true,
                                                            lableTextColor:
                                                                itemData.isMandatory == true
                                                                    ? AppColors.red
                                                                    : AppColors.black,
                                                            onChanged: (value) {
                                                              itemData.value = value;
                                                            },
                                                            // labelText:
                                                            //     "${itemData.label} (long press below to get value)",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                  : CustomTextformField(
                                                    keyboardType: _getKeyboardType(itemData.dataType),
                                                    lableTextColor:
                                                        itemData.label!.contains("*") ? AppColors.red : AppColors.black,
                                                    borderColor:
                                                        itemData.label!.contains("*") ? AppColors.red : AppColors.grey,
                                                    controller: textBoxC[index],
                                                    labelText: itemData.label,
                                                    onChanged: (value) {
                                                      itemData.value = value;
                                                    },
                                                  )
                                              : itemData.type == "TEXTAREA"
                                              ? CustomTextformField(
                                                maxLines: 3,
                                                maxLength:
                                                    (itemData.fieldLength != null && itemData.fieldLength! > 0)
                                                        ? itemData.fieldLength
                                                        : null,
                                                keyboardType: _getKeyboardType(itemData.dataType),
                                                controller: textAreaC[index],
                                                lableTextColor:
                                                    itemData.isMandatory == true ? AppColors.red : AppColors.black,
                                                labelText: itemData.label,
                                                onChanged: (value) {
                                                  itemData.value = value;
                                                },
                                              )
                                              : itemData.type == "COMBOBOX"
                                              ? DropdownButtonFormField(
                                                initialValue:
                                                    (dropdownValues[index] != null &&
                                                            dropdownList.any(
                                                              (item) => item.value == dropdownValues[index],
                                                            ))
                                                        ? dropdownValues[index]
                                                        : null,
                                                decoration: InputDecoration(
                                                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12),
                                                  labelText: itemData.label,
                                                  labelStyle: AppTextStyle.ts14RB.copyWith(color: AppColors.red),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8.0),
                                                    borderSide: BorderSide(color: AppColors.grey),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8.0),
                                                    borderSide: BorderSide(color: AppColors.grey),
                                                  ),
                                                  errorBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8.0),
                                                    borderSide: BorderSide(color: AppColors.red),
                                                  ),
                                                  focusedErrorBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8.0),
                                                    borderSide: BorderSide(color: AppColors.red),
                                                  ),
                                                ),
                                                items:
                                                    dropdownList.map<DropdownMenuItem<String>>((spinner) {
                                                      return DropdownMenuItem<String>(
                                                        value: spinner.value.toString(),
                                                        child: Text("${spinner.value}"),
                                                      );
                                                    }).toList(),
                                                onChanged: (String? value) {
                                                  dropdownValues[index] = value;
                                                },
                                              )
                                              : itemData.type == "MULTISELECT"
                                              ? MultiSelectDropdown(
                                                labelStyle:
                                                    itemData.isMandatory == true
                                                        ? AppTextStyle.ts12RB.copyWith(color: AppColors.red)
                                                        : AppTextStyle.ts12RB,
                                                options: multiDropdownItems,
                                                selectedValues: multiDropdownValues[index] ?? [],
                                                label: itemData.label!,
                                                onChanged: (value) {
                                                  multiDropdownValues[index] = value;
                                                },
                                              )
                                              : itemData.type == "DATE"
                                              ? CustomDatePicker(
                                                firstDate: DateTime(1800),
                                                lastDate: DateTime.now(),
                                                initialDate: _parseDate(dateControllers[index]!.text),
                                                textController: dateControllers[index]!,
                                                labelStyle:
                                                    itemData.isMandatory == true
                                                        ? AppTextStyle.ts12RB.copyWith(color: AppColors.red)
                                                        : AppTextStyle.ts12RB,
                                                label: itemData.label!,
                                                onDateSelected: (date) {},
                                              )
                                              : itemData.type == "WEBVIEW"
                                              ? Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      itemData.value ?? "",
                                                      style: AppTextStyle.ts12RB.copyWith(
                                                        color: Colors.blue,
                                                        decoration: TextDecoration.underline,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      final urlString = itemData.value?.trim() ?? "";
                                                      if (urlString.isEmpty) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            backgroundColor: Colors.red,
                                                            content: Text("URL is empty", style: AppTextStyle.ts14MW),
                                                          ),
                                                        );
                                                        return;
                                                      }

                                                      Uri? uri;
                                                      try {
                                                        uri = Uri.parse(urlString);
                                                      } catch (_) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            backgroundColor: Colors.red,
                                                            content: Text("Invalid URL", style: AppTextStyle.ts14MW),
                                                          ),
                                                        );
                                                        return;
                                                      }

                                                      if (!await canLaunchUrl(uri)) {
                                                        if (!context.mounted) return;
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            backgroundColor: Colors.red,
                                                            content: Text(
                                                              "Unable to open the URL",
                                                              style: AppTextStyle.ts14MW,
                                                            ),
                                                          ),
                                                        );
                                                        return;
                                                      }

                                                      try {
                                                        await launchUrl(uri, mode: LaunchMode.inAppWebView);
                                                      } catch (e) {
                                                        if (!context.mounted) return;
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            backgroundColor: Colors.red,
                                                            content: Text(
                                                              "Failed to launch: $e",
                                                              style: AppTextStyle.ts14MW,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: Text(
                                                      "Click here",
                                                      style: AppTextStyle.ts12RB.copyWith(color: AppColors.green),
                                                    ),
                                                  ),
                                                ],
                                              )
                                              : SizedBox.shrink(),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      widget.siteSubmitted == 1
                          ? SizedBox.shrink()
                          : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: CustomElevatedButton(
                                    borderRadius: 0,
                                    text: "Save",
                                    onPressed: () {
                                      var updatedFields = state.fields;
                                      for (var i = 0; i < updatedFields.length; i++) {
                                        if (updatedFields[i].type == "TEXTBOX") {
                                          updatedFields[i].value = textBoxC[i]?.text;
                                        } else if (updatedFields[i].type == "TEXTAREA") {
                                          updatedFields[i].value = textAreaC[i]?.text;
                                        } else if (updatedFields[i].type == "COMBOBOX") {
                                          updatedFields[i].value = dropdownValues[i];
                                        } else if (updatedFields[i].type == "MULTISELECT") {
                                          updatedFields[i].value = (multiDropdownValues[i] ?? []).join(', ');
                                        } else if (updatedFields[i].type == "DATE") {
                                          updatedFields[i].value = dateControllers[i]?.text;
                                        }
                                        if (updatedFields[i].label?.toLowerCase() == "visit charges" &&
                                            int.parse(textBoxC[i]!.text.trim()) == 0) {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) => CustomAlertDialog(
                                                  title: "",
                                                  content: "Charges cannot be 0.",
                                                  onConfirm: () {},
                                                  confirmText: "OK",
                                                  confirmTextStyle: AppTextStyle.ts14MB.copyWith(color: Colors.teal),
                                                ),
                                          );
                                          return;
                                        }
                                      }
                                      context.read<OpenCaseCubit>().saveData(widget.siteId, updatedFields);
                                    },
                                  ),
                                ),
                                SizedBox(width: 5),
                                // widget.siteSubmitted == 1
                                //     ? SizedBox.shrink()
                                //     :
                                Expanded(
                                  flex: 2,
                                  child: CustomElevatedButton(
                                    borderRadius: 0,
                                    text: "FINAL SUBMIT CASE",
                                    textStyle: AppTextStyle.ts14BW,
                                    onPressed: () {
                                      context.read<OpenCaseCubit>().finalSubmitMethod(
                                        siteId: widget.siteId,
                                        initId: widget.initId,
                                        siteEngId: widget.siteEngId,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      SizedBox(height: 5.0),
                    ],
                  ),
                  if (widget.siteSubmitted == 1)
                    Positioned.fill(child: AbsorbPointer(child: ColoredBox(color: Colors.white38))),
                ],
              );
            }
            return SizedBox();
          },
          listener: (BuildContext context, OpenCaseState state) {
            if (state is OpenCaseErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(backgroundColor: Colors.red, content: Text(state.message, style: AppTextStyle.ts14MW)),
              );
            } else if (state is OpenCaseSuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(backgroundColor: Colors.green, content: Text(state.message, style: AppTextStyle.ts14MW)),
              );
            }
          },
        ),
      ),
    );
  }
}
