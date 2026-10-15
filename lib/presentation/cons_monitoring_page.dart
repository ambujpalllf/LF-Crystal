import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/cubit/construction_monitoring/cons_monitoring_cubit.dart';
import 'package:lf_crystal/cubit/construction_monitoring/cons_monitoring_state.dart';
import 'package:lf_crystal/widget/custom_elevated_btn.dart';
import 'package:lf_crystal/widget/custom_textform_field.dart';

class ConsMonitoringPage extends StatefulWidget {
  final String consValue;
  const ConsMonitoringPage({super.key, required this.consValue});

  @override
  State<ConsMonitoringPage> createState() => _ConsMonitoringPageState();
}

class _ConsMonitoringPageState extends State<ConsMonitoringPage> {
  late ConsMonitoringCubit consDescCubit;

  bool iDisableFields = true;
  TextEditingController floorsC = TextEditingController();
  TextEditingController slabsC = TextEditingController();
  TextEditingController plinthC = TextEditingController();
  TextEditingController rccC = TextEditingController();
  TextEditingController bwUptoSlabC = TextEditingController();
  TextEditingController plasteringInternalC = TextEditingController();
  TextEditingController plasteringExternalC = TextEditingController();
  TextEditingController flooringC = TextEditingController();
  TextEditingController electricC = TextEditingController();
  TextEditingController plumbingC = TextEditingController();
  TextEditingController woodWorkC = TextEditingController();
  TextEditingController paintingC = TextEditingController();
  final FocusNode plinthFocus = FocusNode();
  final FocusNode rccFocus = FocusNode();
  final FocusNode bwUptoSlabFocus = FocusNode();
  final FocusNode plasteringInternalFocus = FocusNode();
  final FocusNode plasteringExternalFocus = FocusNode();
  final FocusNode flooringFocus = FocusNode();
  final FocusNode electricFocus = FocusNode();
  final FocusNode plumbingFocus = FocusNode();
  final FocusNode woodWorkFocus = FocusNode();
  final FocusNode paintingFocus = FocusNode();

  String? floorEr;
  String? slabsEr;
  String? plinthEr;
  String? rccEr;
  String? bwUptoSlabEr;
  String? plasteringInternalEr;
  String? plasteringExternalEr;
  String? flooringEr;
  String? electricEr;
  String? plumbingEr;
  String? woodWorkEr;
  String? paintingEr;

  @override
  void initState() {
    super.initState();
    consDescCubit = context.read<ConsMonitoringCubit>();
    prefillConstructionFields(widget.consValue);
  }

  void prefillConstructionFields(String? value) {
    if (value == null || value.trim().isEmpty) {
      return;
    }

    try {
      final dynamic decoded = jsonDecode(value);
      if (decoded is! List || decoded.isEmpty) {
        return;
      }

      final dynamic firstItem = decoded[0];

      if (firstItem is! Map) {
        return;
      }

      void setController(String key, TextEditingController controller) {
        final dynamic item = firstItem[key];

        if (item is Map) {
          final dynamic fieldValue = item["value"];

          controller.text = fieldValue?.toString() ?? "";
        }
      }

      // setController("0", floorsC);
      // setController("1", slabsC);
      // setController("2", plinthC);
      // iDisableFields = plinthC.text.trim() != "100";
      // setController("3", rccC);
      // setController("4", bwUptoSlabC);
      // setController("5", flooringC);
      // setController("6", electricC);
      // setController("7", plumbingC);
      // setController("8", woodWorkC);
      // setController("9", plasteringInternalC);
      // setController("10", plasteringExternalC);
      // setController("11", paintingC);
      setController("0", floorsC);
      setController("1", slabsC);
      setController("2", plinthC);
      iDisableFields = plinthC.text.trim() != "100";
      setController("3", rccC);
      setController("4", bwUptoSlabC);
      setController("5", plasteringInternalC);
      setController("6", plasteringExternalC);
      setController("7", flooringC);
      setController("8", electricC);
      setController("9", plumbingC);
      setController("10", woodWorkC);
      setController("11", paintingC);
    } catch (e) {
      debugPrint("Error prefilling construction fields: $e");
    }
  }

  String getConstructionValue() {
    return consDescCubit.getConstructionValue(
      consValue: widget.consValue,
      floors: floorsC.text,
      slabs: slabsC.text,
      plinth: plinthC.text,
      rcc: rccC.text,
      bwUptoSlab: bwUptoSlabC.text,
      flooring: flooringC.text,
      electric: electricC.text,
      plumbing: plumbingC.text,
      woodWork: woodWorkC.text,
      plasteringInternal: plasteringInternalC.text,
      plasteringExternal: plasteringExternalC.text,
      painting: paintingC.text,
    );
  }

  @override
  void dispose() {
    floorsC.dispose();
    slabsC.dispose();
    plinthC.dispose();
    rccC.dispose();
    bwUptoSlabC.dispose();
    plasteringInternalC.dispose();
    plasteringExternalC.dispose();
    flooringC.dispose();
    electricC.dispose();
    plumbingC.dispose();
    woodWorkC.dispose();
    paintingC.dispose();

    plinthFocus.dispose();
    rccFocus.dispose();
    bwUptoSlabFocus.dispose();
    plasteringInternalFocus.dispose();
    plasteringExternalFocus.dispose();
    flooringFocus.dispose();
    electricFocus.dispose();
    plumbingFocus.dispose();
    woodWorkFocus.dispose();
    paintingFocus.dispose();

    super.dispose();
  }

  void clearFields({required String value}) {
    if (value != "100") {
      rccC.clear();
      bwUptoSlabC.clear();
      plasteringInternalC.clear();
      plasteringExternalC.clear();
      flooringC.clear();
      electricC.clear();
      plumbingC.clear();
      woodWorkC.clear();
      paintingC.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final String value = getConstructionValue();
        Navigator.pop(context, value);
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              final String value = getConstructionValue();
              Navigator.pop(context, value);
            },
            icon: Icon(Icons.arrow_back, color: AppColors.white),
          ),
          backgroundColor: AppColors.blue,
          title: Text("Construction Monitoring", style: AppTextStyle.ts18RW),
        ),
        body: SafeArea(
          child: BlocListener<ConsMonitoringCubit, ConsMonitoringState>(
            listener: (context, state) {
              if (state is PlinthState) {
                iDisableFields = state.isEnable;
              } else if (state is ValidationState) {
                floorEr = state.floorEr;
                slabsEr = state.slabsEr;
                plinthEr = state.plinthEr;
                rccEr = state.rccEr;
                bwUptoSlabEr = state.bwUptoSlabEr;
                plasteringInternalEr = state.plasteringInternalEr;
                plasteringExternalEr = state.plasteringExternalEr;
                flooringEr = state.flooringEr;
                electricEr = state.electricEr;
                plumbingEr = state.plumbingEr;
                woodWorkEr = state.woodWorkEr;
                paintingEr = state.paintingEr;
              }
            },
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: SingleChildScrollView(
                  child: BlocBuilder<ConsMonitoringCubit, ConsMonitoringState>(
                    builder: (context, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12.0,
                        children: [
                          Text("Construction Progress", style: AppTextStyle.ts16MB),
                          CustomTextformField(
                            controller: floorsC,
                            labelText: "Number Of Floors",
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            errorText: floorEr,
                            onChanged: (String value) {
                              if (value.isNotEmpty) {
                                int fValue = int.parse(value);
                                int result = fValue + 1;
                                slabsC.text = result.toString();
                              } else {
                                slabsC.text = value;
                              }

                              // consDescCubit.validateFields(floors: value);
                              consDescCubit.validateFields(
                                floors: value,
                                slabs: slabsC.text,
                                plinth: plinthC.text,
                                isDisableFields: iDisableFields,
                                rcc: rccC.text,
                                bwUptoSlab: bwUptoSlabC.text,
                                plasteringInternal: plasteringInternalC.text,
                                plasteringExternal: plasteringExternalC.text,
                                flooring: flooringC.text,
                                electric: electricC.text,
                                plumbing: plumbingC.text,
                                woodWork: woodWorkC.text,
                                painting: paintingC.text,
                              );
                            },
                          ),
                          CustomTextformField(
                            controller: slabsC,
                            labelText: "Number Of Slabs",
                            errorText: slabsEr,
                            errorMaxLines: 2,
                            enableSpeech: false,
                            readOnly: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            lableTextColor: Colors.grey,
                            onChanged: (String value) {},
                          ),
                          CustomTextformField(
                            controller: plinthC,
                            labelText: "Plinth",
                            errorText: plinthEr,
                            errorMaxLines: 2,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            onChanged: (String value) {
                              clearFields(value: value);
                              consDescCubit.updatePlinth(plinth: value);
                              consDescCubit.validateFields(
                                floors: floorsC.text,
                                slabs: slabsC.text,
                                plinth: value,
                                isDisableFields: iDisableFields,
                                rcc: rccC.text,
                                bwUptoSlab: bwUptoSlabC.text,
                                plasteringInternal: plasteringInternalC.text,
                                plasteringExternal: plasteringExternalC.text,
                                flooring: flooringC.text,
                                electric: electricC.text,
                                plumbing: plumbingC.text,
                                woodWork: woodWorkC.text,
                                painting: paintingC.text,
                              );
                            },
                          ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                spacing: 12.0,
                                children: [
                                  CustomTextformField(
                                    controller: rccC,
                                    labelText: "RCC (Nos of Slabs Completed)",
                                    errorText: rccEr,
                                    errorMaxLines: 2,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    onChanged: (String value) {
                                      // consDescCubit.validateFields(rcc: rccC.text, isEnableFields: isEnableFields);
                                      consDescCubit.validateFields(
                                        floors: floorsC.text,
                                        slabs: slabsC.text,
                                        plinth: plinthC.text,
                                        isDisableFields: iDisableFields,
                                        rcc: value,
                                        bwUptoSlab: bwUptoSlabC.text,
                                        plasteringInternal: plasteringInternalC.text,
                                        plasteringExternal: plasteringExternalC.text,
                                        flooring: flooringC.text,
                                        electric: electricC.text,
                                        plumbing: plumbingC.text,
                                        woodWork: woodWorkC.text,
                                        painting: paintingC.text,
                                      );
                                    },
                                  ),
                                  CustomTextformField(
                                    controller: bwUptoSlabC,
                                    labelText: "B/W upto Slab",
                                    keyboardType: TextInputType.number,
                                    errorText: bwUptoSlabEr,
                                    errorMaxLines: 2,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    onChanged: (String value) {
                                      consDescCubit.validateFields(
                                        floors: floorsC.text,
                                        slabs: slabsC.text,
                                        plinth: plinthC.text,
                                        isDisableFields: iDisableFields,
                                        rcc: rccC.text,
                                        bwUptoSlab: value,
                                        plasteringInternal: plasteringInternalC.text,
                                        plasteringExternal: plasteringExternalC.text,
                                        flooring: flooringC.text,
                                        electric: electricC.text,
                                        plumbing: plumbingC.text,
                                        woodWork: woodWorkC.text,
                                        painting: paintingC.text,
                                      );
                                    },
                                  ),
                                  CustomTextformField(
                                    controller: flooringC,
                                    labelText: "Flooring",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    errorText: flooringEr,
                                    errorMaxLines: 2,
                                    onChanged: (String value) {
                                      consDescCubit.validateFields(
                                        floors: floorsC.text,
                                        slabs: slabsC.text,
                                        plinth: plinthC.text,
                                        isDisableFields: iDisableFields,
                                        rcc: rccC.text,
                                        bwUptoSlab: bwUptoSlabC.text,
                                        plasteringInternal: plasteringInternalC.text,
                                        plasteringExternal: plasteringExternalC.text,
                                        flooring: value,
                                        electric: electricC.text,
                                        plumbing: plumbingC.text,
                                        woodWork: woodWorkC.text,
                                        painting: paintingC.text,
                                      );
                                    },
                                  ),
                                  CustomTextformField(
                                    controller: electricC,
                                    labelText: "Electric",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    errorText: electricEr,
                                    errorMaxLines: 2,
                                    onChanged: (String value) {
                                      consDescCubit.validateFields(
                                        floors: floorsC.text,
                                        slabs: slabsC.text,
                                        plinth: plinthC.text,
                                        isDisableFields: iDisableFields,
                                        rcc: rccC.text,
                                        bwUptoSlab: bwUptoSlabC.text,
                                        plasteringInternal: plasteringInternalC.text,
                                        plasteringExternal: plasteringExternalC.text,
                                        flooring: flooringC.text,
                                        electric: value,
                                        plumbing: plumbingC.text,
                                        woodWork: woodWorkC.text,
                                        painting: paintingC.text,
                                      );
                                    },
                                  ),
                                  CustomTextformField(
                                    controller: plumbingC,
                                    labelText: "Plumbing",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    errorText: plumbingEr,
                                    errorMaxLines: 2,
                                    onChanged: (String value) {
                                      consDescCubit.validateFields(
                                        floors: floorsC.text,
                                        slabs: slabsC.text,
                                        plinth: plinthC.text,
                                        isDisableFields: iDisableFields,
                                        rcc: rccC.text,
                                        bwUptoSlab: bwUptoSlabC.text,
                                        plasteringInternal: plasteringInternalC.text,
                                        plasteringExternal: plasteringExternalC.text,
                                        flooring: flooringC.text,
                                        electric: electricC.text,
                                        plumbing: value,
                                        woodWork: woodWorkC.text,
                                        painting: paintingC.text,
                                      );
                                    },
                                  ),
                                  CustomTextformField(
                                    controller: woodWorkC,
                                    labelText: "Woodwork",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    errorText: woodWorkEr,
                                    errorMaxLines: 2,
                                    onChanged: (String value) {
                                      consDescCubit.validateFields(
                                        floors: floorsC.text,
                                        slabs: slabsC.text,
                                        plinth: plinthC.text,
                                        isDisableFields: iDisableFields,
                                        rcc: rccC.text,
                                        bwUptoSlab: bwUptoSlabC.text,
                                        plasteringInternal: plasteringInternalC.text,
                                        plasteringExternal: plasteringExternalC.text,
                                        flooring: flooringC.text,
                                        electric: electricC.text,
                                        plumbing: plumbingC.text,
                                        woodWork: value,
                                        painting: paintingC.text,
                                      );
                                    },
                                  ),
                                  CustomTextformField(
                                    controller: plasteringInternalC,
                                    labelText: "Plastering (Internal)",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    errorText: plasteringInternalEr,
                                    errorMaxLines: 2,
                                    onChanged: (String value) {
                                      consDescCubit.validateFields(
                                        floors: floorsC.text,
                                        slabs: slabsC.text,
                                        plinth: plinthC.text,
                                        isDisableFields: iDisableFields,
                                        rcc: rccC.text,
                                        bwUptoSlab: bwUptoSlabC.text,
                                        plasteringInternal: value,
                                        plasteringExternal: plasteringExternalC.text,
                                        flooring: flooringC.text,
                                        electric: electricC.text,
                                        plumbing: plumbingC.text,
                                        woodWork: woodWorkC.text,
                                        painting: paintingC.text,
                                      );
                                    },
                                  ),
                                  CustomTextformField(
                                    controller: plasteringExternalC,
                                    labelText: "Plastering (External)",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    errorText: plasteringExternalEr,
                                    errorMaxLines: 2,
                                    onChanged: (String value) {
                                      consDescCubit.validateFields(
                                        floors: floorsC.text,
                                        slabs: slabsC.text,
                                        plinth: plinthC.text,
                                        isDisableFields: iDisableFields,
                                        rcc: rccC.text,
                                        bwUptoSlab: bwUptoSlabC.text,
                                        plasteringInternal: plasteringInternalC.text,
                                        plasteringExternal: value,
                                        flooring: flooringC.text,
                                        electric: electricC.text,
                                        plumbing: plumbingC.text,
                                        woodWork: woodWorkC.text,
                                        painting: paintingC.text,
                                      );
                                    },
                                  ),
                                  CustomTextformField(
                                    controller: paintingC,
                                    labelText: "Painting",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    errorText: paintingEr,
                                    errorMaxLines: 2,
                                    onChanged: (String value) {
                                      consDescCubit.validateFields(
                                        floors: floorsC.text,
                                        slabs: slabsC.text,
                                        plinth: plinthC.text,
                                        isDisableFields: iDisableFields,
                                        rcc: rccC.text,
                                        bwUptoSlab: bwUptoSlabC.text,
                                        plasteringInternal: plasteringInternalC.text,
                                        plasteringExternal: plasteringExternalC.text,
                                        flooring: flooringC.text,
                                        electric: electricC.text,
                                        plumbing: plumbingC.text,
                                        woodWork: woodWorkC.text,
                                        painting: value,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              if (iDisableFields)
                                Positioned.fill(child: AbsorbPointer(child: ColoredBox(color: Colors.white54))),
                            ],
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: CustomElevatedButton(
                              text: "Save",
                              borderRadius: 4.0,
                              onPressed: () {
                                bool result = consDescCubit.validateFields(
                                  floors: floorsC.text,
                                  slabs: slabsC.text,
                                  plinth: plinthC.text,
                                  isDisableFields: iDisableFields,
                                  rcc: rccC.text,
                                  bwUptoSlab: bwUptoSlabC.text,
                                  plasteringInternal: plasteringInternalC.text,
                                  plasteringExternal: plasteringExternalC.text,
                                  flooring: flooringC.text,
                                  electric: electricC.text,
                                  plumbing: plumbingC.text,
                                  woodWork: woodWorkC.text,
                                  painting: paintingC.text,
                                );
                                if (result) {
                                  final String value = getConstructionValue();
                                  Navigator.pop(context, value);
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
