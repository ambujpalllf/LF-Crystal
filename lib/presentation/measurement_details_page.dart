import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/cubit/measurement_details/measurement_cubit.dart';
import 'package:lf_crystal/cubit/measurement_details/measurement_state.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/model/room_details.dart';
import 'package:lf_crystal/widget/custom_rich_text.dart';

class MeasurementDetailsPage extends StatefulWidget {
  final String value;
  const MeasurementDetailsPage({super.key, required this.value});

  @override
  State<MeasurementDetailsPage> createState() => _MeasurementDetailsPageState();
}

class _MeasurementDetailsPageState extends State<MeasurementDetailsPage> {
  late MeasurementCubit measurementCubit;
  bool _isPopping = false;
  List<RoomDetails> measurementData = [];
  List<SpinnerMaster> buildingSpaces = [];
  List<String> shapeName = ["Square", "Triangle", "Door Sill(1.75)", "Door Sill(1.25)", "Semi-Circle", "Quarter-Circle"];
  TextEditingController lengthFeetC = TextEditingController();
  TextEditingController lengthInchC = TextEditingController();
  TextEditingController breadthFeetC = TextEditingController();
  TextEditingController breadthInchC = TextEditingController();
  double lengthTotal = 0.0;
  double breadthTotal = 0.0;
  double areaTotal = 0.0;
  double sumTotalArea = 0.0;

  SpinnerMaster? selectedBuildingSpace;
  String? selectedShape;

  @override
  void initState() {
    super.initState();
    measurementCubit = context.read<MeasurementCubit>();
    measurementCubit.getData();
    measurementData = measurementCubit.parseMeasurementData(widget.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      measurementCubit.calculateTotalArea(measurementData);
    });
  }

  void clearFields() {
    lengthFeetC.clear();
    lengthInchC.clear();
    breadthFeetC.clear();
    breadthInchC.clear();
    selectedBuildingSpace = null;
    selectedShape = null;
    lengthTotal = 0.0;
    breadthTotal = 0.0;
    areaTotal = 0.0;
  }

  void prefillFields({required String lengthFeet, required String lengthInch, required double lenTotal, required String breadthFeet, required String breadthInch, required double breTotal, required String description, required String buildingShape, required double area}) {
    final parts = description.split('-');
    final key = parts.isNotEmpty ? parts[0].trim() : '';
    // final value = parts.length > 1 ? parts[1].trim() : '';
    lengthFeetC.text = lengthFeet;
    lengthInchC.text = lengthInch;
    breadthFeetC.text = breadthFeet;
    breadthInchC.text = breadthInch;
    lengthTotal = lenTotal;
    breadthTotal = breTotal;
    areaTotal = area;
    selectedBuildingSpace = buildingSpaces.where((item) => item.key == key).first;
    selectedShape = shapeName.where((i) => i == buildingShape).first;
  }

  @override
  void dispose() {
    super.dispose();
    lengthFeetC.dispose();
    lengthInchC.dispose();
    breadthFeetC.dispose();
    breadthInchC.dispose();
  }

  void _goBackWithData() {
    if (_isPopping) return;

    _isPopping = true;

    // Convert your data to JSON
    final String jsonString = measurementCubit.measurementDataToJson(measurementData);

    Map<String, dynamic> data = {"sumTotalArea": sumTotalArea, "jsonString": jsonString};

    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        _goBackWithData();
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(backgroundColor: AppColors.blue, automaticallyImplyLeading: false, leading: IconButton(onPressed: () => _goBackWithData(), icon: Icon(Icons.arrow_back, color: AppColors.white)), title: Text("Measurement Details", style: AppTextStyle.ts18BW)),
        body: BlocListener<MeasurementCubit, MeasurementState>(
          listener: (context, state) {
            if (state is LoadedState) {
              buildingSpaces.clear();
              buildingSpaces.addAll(state.buildingSpaces);
            } else if (state is DataSavedState) {
              if (state.index != null) {
                measurementData[state.index!] = state.data;
              } else {
                measurementData.add(state.data);
              }

              measurementCubit.calculateTotalArea(measurementData);
            } else if (state is AreaCalculatedState) {
              sumTotalArea = state.sumArea;
            } else if (state is RemoveState) {
              measurementData.removeAt(state.index);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white),
                  child: BlocBuilder<MeasurementCubit, MeasurementState>(
                    builder: (context, state) {
                      return Text("Sum of Area: $sumTotalArea", style: AppTextStyle.ts14MB);
                    },
                  ),
                ),
                const SizedBox(height: 12.0),
                Expanded(
                  child: BlocBuilder<MeasurementCubit, MeasurementState>(
                    builder: (context, state) {
                      return ListView.builder(
                        itemCount: measurementData.length,
                        itemBuilder: (_, index) {
                          var data = measurementData[index];
                          final description = measurementCubit.getValue(data, "Description");
                          final lengthFeet = measurementCubit.getValue(data, "Length (Feet)");
                          final lengthInches = measurementCubit.getValue(data, "Length (Inches)");
                          final lengthTotal = measurementCubit.getValue(data, "Length (Total)");

                          final breadthFeet = measurementCubit.getValue(data, "Breadth (Feet)");
                          final breadthInches = measurementCubit.getValue(data, "Breadth (Inches)");
                          final breadthTotal = measurementCubit.getValue(data, "Breadth (Total)");

                          final area = measurementCubit.getValue(data, "Area");
                          final shape = measurementCubit.getValue(data, "Shape");
                          final isChecked = measurementCubit.getChecked(data);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Card(
                              shape: RoundedRectangleBorder(),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  spacing: 4.0,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(description, style: AppTextStyle.ts16MB),
                                        Checkbox(
                                          activeColor: Colors.green,
                                          value: isChecked,
                                          onChanged: (value) {
                                            measurementCubit.calculateSumofArea(isChecked: value!, index: index, mesurementData: measurementData);
                                          },
                                        ),
                                      ],
                                    ),
                                    Divider(thickness: 1.5),
                                    Text("Length: $lengthFeet feet $lengthInches inches = Total: $lengthTotal"),
                                    Text("Breadth: $breadthFeet feet $breadthInches inches = Total: $breadthTotal"),
                                    Divider(thickness: 1),
                                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text("Area: $area", softWrap: true)), const SizedBox(width: 16), Expanded(child: Text("Shape: $shape", softWrap: true, textAlign: TextAlign.end))]),
                                    Row(
                                      spacing: 12.0,
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              prefillFields(lengthFeet: lengthFeet, lengthInch: lengthInches, lenTotal: double.tryParse(lengthTotal) ?? 0.0, breadthFeet: breadthFeet, breadthInch: breadthInches, breTotal: double.tryParse(breadthTotal) ?? 0.0, description: description, buildingShape: shape, area: double.tryParse(area) ?? 0.0);
                                              measurementDialgoue(index: index);
                                            },
                                            child: Container(alignment: Alignment.center, padding: EdgeInsets.all(6.0), decoration: BoxDecoration(color: AppColors.blue), child: Text("EDIT", style: AppTextStyle.ts14MW)),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              removeDataDialogue(index: index);
                                            },
                                            child: Container(alignment: Alignment.center, padding: EdgeInsets.all(6.0), decoration: BoxDecoration(color: AppColors.blue), child: Text("REMOVE", style: AppTextStyle.ts14MW)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Colors.blueGrey,
          onPressed: () {
            measurementDialgoue();
          },
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  void measurementDialgoue({int? index}) {
    final cubit = context.read<MeasurementCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BlocProvider.value(
              value: cubit,
              child: BlocBuilder<MeasurementCubit, MeasurementState>(
                buildWhen: (previous, current) => current is ValidationState || current is CalculationState,
                builder: (context, state) {
                  String selectedBuildingSpaceEr = "";
                  String lengthFeetEr = "";
                  String lengthInchEr = "";
                  String breadthFeetEr = "";
                  String breadthInchEr = "";
                  String buildingShapeEr = "";

                  if (state is ValidationState) {
                    selectedBuildingSpaceEr = state.selectedBuildingSpaceEr;
                    lengthFeetEr = state.lengthFeetEr;
                    lengthInchEr = state.lengthInchEr;
                    breadthFeetEr = state.breadthFeetEr;
                    breadthInchEr = state.breadthInchEr;
                    buildingShapeEr = state.buildingShapeEr;
                  } else if (state is CalculationState) {
                    lengthTotal = state.lengthTotal;
                    breadthTotal = state.breadthTotal;
                    areaTotal = state.areaTotal;
                  }

                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(),
                    contentPadding: EdgeInsets.zero,
                    content: SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: DropdownButtonFormField<SpinnerMaster>(
                                initialValue: selectedBuildingSpace,
                                hint: const Text("Select Building Space"),
                                isExpanded: true,
                                items:
                                    buildingSpaces.map<DropdownMenuItem<SpinnerMaster>>((spinner) {
                                      return DropdownMenuItem<SpinnerMaster>(value: spinner, child: Text("${spinner.key} - ${spinner.value}", overflow: TextOverflow.ellipsis));
                                    }).toList(),

                                onChanged: (SpinnerMaster? value) {
                                  setState(() {
                                    selectedBuildingSpace = value;
                                  });

                                  cubit.fieldsValidation(selectedBuildingSpace: selectedBuildingSpace, lengthFeet: lengthFeetC.text.trim(), lengthInch: lengthInchC.text.trim(), breadthFeet: breadthFeetC.text.trim(), breadthInch: breadthInchC.text.trim(), buildingShape: selectedShape ?? "");
                                },

                                decoration: InputDecoration(errorText: selectedBuildingSpaceEr.isEmpty ? null : selectedBuildingSpaceEr, contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0), hintText: "Select Building Space", hintStyle: AppTextStyle.ts14RB.copyWith(color: AppColors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0))),
                              ),
                            ),

                            const Divider(thickness: 1.5, color: Colors.black),

                            // Length
                            textWidget(
                              lable: "Room Length",
                              feetC: lengthFeetC,
                              inchC: lengthInchC,
                              total: lengthTotal,
                              feetEr: lengthFeetEr,
                              inchEr: lengthInchEr,
                              feetOnChanged: (value) {
                                cubit.fieldsValidation(selectedBuildingSpace: selectedBuildingSpace, lengthFeet: lengthFeetC.text.trim(), lengthInch: lengthInchC.text.trim(), breadthFeet: breadthFeetC.text.trim(), breadthInch: breadthInchC.text.trim(), buildingShape: selectedShape ?? "");

                                cubit.measurementCalculation(lengthFeet: lengthFeetC.text, lengthInch: lengthInchC.text, lengthTotal: lengthTotal, breadthFeet: breadthFeetC.text, breadthInch: breadthInchC.text, breadthTotal: breadthTotal, buildingShape: selectedShape ?? "", areaTotal: areaTotal);
                              },
                              inchOnChanged: (value) {
                                cubit.fieldsValidation(selectedBuildingSpace: selectedBuildingSpace, lengthFeet: lengthFeetC.text.trim(), lengthInch: lengthInchC.text.trim(), breadthFeet: breadthFeetC.text.trim(), breadthInch: breadthInchC.text.trim(), buildingShape: selectedShape ?? "");
                                cubit.measurementCalculation(lengthFeet: lengthFeetC.text, lengthInch: lengthInchC.text, lengthTotal: lengthTotal, breadthFeet: breadthFeetC.text, breadthInch: breadthInchC.text, breadthTotal: breadthTotal, buildingShape: selectedShape ?? "", areaTotal: areaTotal);
                              },
                            ),

                            const Divider(),

                            // Breadth
                            textWidget(
                              lable: "Room Breadth",
                              feetC: breadthFeetC,
                              inchC: breadthInchC,
                              total: breadthTotal,
                              feetEr: breadthFeetEr,
                              inchEr: breadthInchEr,
                              feetOnChanged: (value) {
                                cubit.fieldsValidation(selectedBuildingSpace: selectedBuildingSpace, lengthFeet: lengthFeetC.text.trim(), lengthInch: lengthInchC.text.trim(), breadthFeet: breadthFeetC.text.trim(), breadthInch: breadthInchC.text.trim(), buildingShape: selectedShape ?? "");
                                cubit.measurementCalculation(lengthFeet: lengthFeetC.text, lengthInch: lengthInchC.text, lengthTotal: lengthTotal, breadthFeet: breadthFeetC.text, breadthInch: breadthInchC.text, breadthTotal: breadthTotal, buildingShape: selectedShape ?? "", areaTotal: areaTotal);
                              },
                              inchOnChanged: (value) {
                                cubit.fieldsValidation(selectedBuildingSpace: selectedBuildingSpace, lengthFeet: lengthFeetC.text.trim(), lengthInch: lengthInchC.text.trim(), breadthFeet: breadthFeetC.text.trim(), breadthInch: breadthInchC.text.trim(), buildingShape: selectedShape ?? "");
                                cubit.measurementCalculation(lengthFeet: lengthFeetC.text, lengthInch: lengthInchC.text, lengthTotal: lengthTotal, breadthFeet: breadthFeetC.text, breadthInch: breadthInchC.text, breadthTotal: breadthTotal, buildingShape: selectedShape ?? "", areaTotal: areaTotal);
                              },
                            ),

                            const SizedBox(height: 8),

                            const Divider(),

                            const SizedBox(height: 8),

                            // Shape + Area
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedShape,
                                      hint: const Text("Select Shape"),
                                      isExpanded: true,
                                      items:
                                          shapeName.map<DropdownMenuItem<String>>((shape) {
                                            return DropdownMenuItem<String>(value: shape, child: Text(shape, overflow: TextOverflow.ellipsis));
                                          }).toList(),
                                      onChanged:
                                          index == null
                                              ? (value) {
                                                setState(() {
                                                  selectedShape = value;
                                                  if (selectedShape?.toLowerCase() == "semi-circle" || selectedShape?.toLowerCase() == "quarter-circle") {
                                                    breadthFeetC.text = "0";
                                                    breadthInchC.text = "0";
                                                    breadthTotal = 0.0;
                                                  }
                                                });
                                                cubit.fieldsValidation(selectedBuildingSpace: selectedBuildingSpace, lengthFeet: lengthFeetC.text.trim(), lengthInch: lengthInchC.text.trim(), breadthFeet: breadthFeetC.text.trim(), breadthInch: breadthInchC.text.trim(), buildingShape: selectedShape ?? "");
                                                cubit.measurementCalculation(lengthFeet: lengthFeetC.text, lengthInch: lengthInchC.text, lengthTotal: lengthTotal, breadthFeet: breadthFeetC.text, breadthInch: breadthInchC.text, breadthTotal: breadthTotal, buildingShape: selectedShape ?? "", areaTotal: areaTotal);
                                              }
                                              : null,
                                      decoration: InputDecoration(
                                        filled: index != null,
                                        fillColor: Colors.grey.shade200,
                                        errorText: buildingShapeEr.isEmpty ? null : buildingShapeEr,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                                        hintText: "Select Shape",
                                        hintStyle: AppTextStyle.ts14RB.copyWith(color: AppColors.grey),
                                        border: OutlineInputBorder(borderSide: BorderSide(color: index != null ? Colors.grey.shade200 : Colors.black), borderRadius: BorderRadius.circular(8.0)),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  CustomRichText(labelText: "Area  ", labelStyle: AppTextStyle.ts14MB, valueText: "  $areaTotal"),
                                ],
                              ),
                            ),

                            const Divider(thickness: 1.5, color: Colors.black),

                            // Buttons
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      clearFields();
                                    },
                                    child: Text("Cancel", style: AppTextStyle.ts16MB.copyWith(color: Colors.red)),
                                  ),

                                  TextButton(
                                    onPressed: () {
                                      final bool result = cubit.saveMesurement(
                                        index: index,
                                        selectedBuildingSpace: selectedBuildingSpace,
                                        lengthFeet: lengthFeetC.text.trim(),
                                        lengthInch: lengthInchC.text.trim(),
                                        breadthFeet: breadthFeetC.text.trim(),
                                        breadthInch: breadthInchC.text.trim(),
                                        buildingShape: selectedShape ?? "",
                                        lengthTotal: lengthTotal,
                                        breadthTotal: breadthTotal,
                                        areaTotal: areaTotal,
                                      );
                                      if (result) {
                                        Navigator.pop(dialogContext);
                                        clearFields();
                                      }
                                    },
                                    child: Text("Save", style: AppTextStyle.ts16MB.copyWith(color: Colors.green)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Padding textWidget({required String lable, required TextEditingController feetC, required TextEditingController inchC, required String feetEr, required String inchEr, required double total, required ValueChanged<String> feetOnChanged, required ValueChanged<String> inchOnChanged}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          Text(lable, style: AppTextStyle.ts14MB),

          const SizedBox(height: 8),

          Row(
            spacing: 8.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  spacing: 8.0,
                  children: [
                    Expanded(child: TextField(controller: feetC, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], onChanged: feetOnChanged, decoration: InputDecoration(hintText: "Feet", errorText: feetEr.isEmpty ? null : feetEr))),

                    Expanded(child: TextField(controller: inchC, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], onChanged: inchOnChanged, decoration: InputDecoration(hintText: "Inch", errorText: inchEr.isEmpty ? null : inchEr))),
                  ],
                ),
              ),

              const Padding(padding: EdgeInsets.only(top: 15), child: Text("=")),

              Padding(padding: const EdgeInsets.only(top: 10), child: CustomRichText(labelText: "Total  ", labelStyle: AppTextStyle.ts14MB, valueText: " $total")),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void removeDataDialogue({required int index}) {
    final cubit = context.read<MeasurementCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(),
          title: Row(spacing: 16.0, children: [Icon(Icons.info, color: Colors.blueGrey, size: 30), Text("Remove Data", style: AppTextStyle.ts16MB)]),
          content: Text("Are you sure you want to remove this data?", style: AppTextStyle.ts14RB),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text("CANCEL", style: AppTextStyle.ts14MB.copyWith(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                cubit.removeData(index: index);

                Navigator.pop(dialogContext);
              },
              child: Text("REMOVE", style: AppTextStyle.ts14MB.copyWith(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
