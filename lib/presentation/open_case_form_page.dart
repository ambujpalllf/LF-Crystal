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
  double sumTotalArea = 0.0;
  List<TextEditingController?> textBoxC = [];
  List<TextEditingController?> textAreaC = [];
  List<String?> dropdownValues = [];
  List<List<String>?> multiDropdownValues = [];
  List<TextEditingController?> dateControllers = [];

  // Holds the "Sum of Area" text for each JSONTABLE field (e.g. MEASUREMENT_DETAILS),
  // populated once the user returns from the room-details screen — mirrors mSumOfArea
  // in the Kotlin SurveyFragment.
  List<String?> jsonTableSumOfArea = [];

  // Guard so initFileds() only runs once per successful load instead
  // of on every build() call — otherwise every rebuild wipes out whatever
  // the user has already typed.
  bool _fieldsInitialized = false;

  @override
  void dispose() {
    for (final c in textBoxC) {
      c?.dispose();
    }
    for (final c in textAreaC) {
      c?.dispose();
    }
    for (final c in dateControllers) {
      c?.dispose();
    }
    super.dispose();
  }

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

    jsonTableSumOfArea =
        fields.map((itemData) {
          if (itemData.type == "JSONTABLE") {
            return "";
          }
          return null;
        }).toList();

    _fieldsInitialized = true;
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
              // Only build controllers the first time this state
              // arrives, not on every rebuild.
              if (!_fieldsInitialized) {
                initFileds(state.fields);
              }

              final latIndex = state.fields.indexWhere((item) => item.label == "Latitude *");
              final lngIndex = state.fields.indexWhere((item) => item.label == "Longitude *");

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      Expanded(
                        child: SingleChildScrollView(
                          // clipBehavior: Clip.none,
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: state.fields.length,
                                  itemBuilder: (context, index) {
                                    var itemData = state.fields[index];
                                    List<SpinnerMaster> dropdownList = [];
                                    List<String> multiDropdownItems = [];
                                    if (itemData.type == "COMBOBOX") {
                                      dropdownList = state.spinnerMaster[itemData.name] ?? [];
                                    }
                                    if (itemData.type == "MULTISELECT") {
                                      List<SpinnerMaster> options = state.spinnerMaster[itemData.name] ?? [];

                                      multiDropdownItems =
                                          options
                                              .map((e) => e.value)
                                              .whereType<String>()
                                              .where((v) => v.isNotEmpty)
                                              .toList();
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 20.0),
                                      child: Column(
                                        children: [
                                          itemData.type == "TEXTBOX"
                                              ? (itemData.label == "Latitude *" || itemData.label == "Longitude *")
                                                  ? InkWell(
                                                    onLongPress: () async {
                                                      // guard against the labels not being
                                                      // found (indexWhere == -1) before indexing.
                                                      if (latIndex == -1 || lngIndex == -1) return;

                                                      bool permission =
                                                          await CheckLocationPermission.checkPermissionGps(
                                                            context: context,
                                                          );

                                                      if (permission) {
                                                        var location =
                                                            await CheckLocationPermission.getCurrentLocation();
                                                        final latText = location.latitude.toString();
                                                        final lngText = location.longitude.toString();

                                                        setState(() {
                                                          textBoxC[latIndex]!.text = latText;
                                                          textBoxC[lngIndex]!.text = lngText;
                                                          state.fields[latIndex].value = latText;
                                                          state.fields[lngIndex].value = lngText;
                                                        });
                                                      }
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
                                                                      if (latIndex == -1 || lngIndex == -1) return;

                                                                      bool permission =
                                                                          await CheckLocationPermission.checkPermissionGps(
                                                                            context: context,
                                                                          );
                                                                      if (!permission) return;
                                                                      if (!context.mounted) return;
                                                                      final result = await Navigator.pushNamed(
                                                                        context,
                                                                        AppRoutesName.mapPage,
                                                                      );
                                                                      if (result != null && result is LatLng) {
                                                                        setState(() {
                                                                          textBoxC[latIndex]!.text =
                                                                              result.latitude.toString();
                                                                          textBoxC[lngIndex]!.text =
                                                                              result.longitude.toString();
                                                                          state.fields[latIndex].value =
                                                                              result.latitude.toString();
                                                                          state.fields[lngIndex].value =
                                                                              result.longitude.toString();
                                                                        });
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
                                                            enableSpeech: false,
                                                            keyboardType: _getKeyboardType(itemData.dataType),
                                                            controller: textBoxC[index],
                                                            readOnly: true,
                                                            lableTextColor:
                                                                itemData.isMandatory == true
                                                                    ? AppColors.red
                                                                    : AppColors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                  : CustomTextformField(
                                                    keyboardType: _getKeyboardType(itemData.dataType),
                                                    maxLength:
                                                        (itemData.fieldLength ?? 0) > 0 ? itemData.fieldLength : null,
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
                                              ? DropdownButtonFormField<String>(
                                                initialValue:
                                                    dropdownValues[index] != null &&
                                                            dropdownList.any(
                                                              (item) => item.key.toString() == dropdownValues[index],
                                                            )
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
                                                        value: spinner.key.toString(),
                                                        child: Text("${spinner.value}"),
                                                      );
                                                    }).toList(),
                                                onChanged: (String? value) {
                                                  setState(() {
                                                    dropdownValues[index] = value;
                                                    itemData.value = value;
                                                  });
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
                                                  setState(() {
                                                    multiDropdownValues[index] = value;
                                                    itemData.value = value.join(', ');
                                                  });
                                                },
                                              )
                                              : itemData.type == "JSONTABLE"
                                              ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  sumTotalArea == 0.0
                                                      ? SizedBox()
                                                      : SizedBox(
                                                        width: double.infinity,
                                                        child: Text("Sum of Area: $sumTotalArea"),
                                                      ),
                                                  const SizedBox(height: 15.0),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: CustomElevatedButton(
                                                      // backgroundColor: Colors.grey.shade500,
                                                      backgroundColor: Colors.lightBlue,
                                                      borderRadius: 0,
                                                      text: "${itemData.label} ->",
                                                      onPressed: () async {
                                                        final result = await Navigator.pushNamed(
                                                          context,
                                                          AppRoutesName.measurementDetailsPage,
                                                          arguments: itemData.value,
                                                        );

                                                        if (result != null && result is Map) {
                                                          final newJson = result['jsonString'] as String;
                                                          final sumOfArea = result['sumTotalArea'] as double;
                                                          setState(() {
                                                            if (newJson.isNotEmpty) {
                                                              itemData.value = newJson;
                                                              sumTotalArea = sumOfArea;
                                                            }
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
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
                                                onDateSelected: (date) {
                                                  itemData.value = dateControllers[index]!.text;
                                                },
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
                                        final field = updatedFields[i];

                                        if (field.type == "TEXTBOX") {
                                          field.value = textBoxC[i]?.text;
                                        } else if (field.type == "TEXTAREA") {
                                          field.value = textAreaC[i]?.text;
                                        } else if (field.type == "COMBOBOX") {
                                          field.value = dropdownValues[i];
                                        } else if (field.type == "MULTISELECT") {
                                          field.value = (multiDropdownValues[i] ?? []).join(', ');
                                        } else if (field.type == "DATE") {
                                          field.value = dateControllers[i]?.text;
                                        }

                                        if (field.type == "TEXTBOX" && field.label?.toLowerCase() == "visit charges") {
                                          final raw = textBoxC[i]?.text.trim() ?? "";
                                          final charges = int.tryParse(raw);
                                          if (charges == null || charges == 0) {
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
                                      }
                                      context.read<OpenCaseCubit>().saveData(widget.siteId, updatedFields);
                                    },
                                  ),
                                ),
                                SizedBox(width: 5),
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
