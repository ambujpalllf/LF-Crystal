import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/cubit/selfie/selfie_cubit.dart';
import 'package:lf_crystal/cubit/selfie/selfie_state.dart';
import 'package:lf_crystal/model/image_entity_model.dart';
import 'package:lf_crystal/presentation/image_view.dart';
import 'package:lf_crystal/services/work_manager_task_register.dart';
import 'package:lf_crystal/widget/custom_alert_dialog.dart';
import 'package:lf_crystal/widget/custom_elevated_btn.dart';
import 'package:lf_crystal/widget/custom_textform_field.dart';
import 'package:lf_crystal/widget/refresh_widget.dart';

class SelfiePage extends StatefulWidget {
  final int siteId;
  final int initId;
  final int siteEngId;
  final int siteSubmitted;
  const SelfiePage({
    super.key,
    required this.siteId,
    required this.initId,
    required this.siteEngId,
    required this.siteSubmitted,
  });

  @override
  State<SelfiePage> createState() => _SelfiePageState();
}

class _SelfiePageState extends State<SelfiePage> {
  TextEditingController imgSerialC = TextEditingController();
  List<ImageEntity> imagesList = [];
  late ReceivePort _receivePort;
  @override
  void initState() {
    super.initState();
    // Step 1: Create a ReceivePort
    _receivePort = ReceivePort();
    // Step 2: Register port with a name so background isolates can find it
    IsolateNameServer.registerPortWithName(_receivePort.sendPort, 'selfie_sync_port');
    // Step 3: Listen to messages sent from background isolates
    _receivePort.listen((message) {
      // message will be the siteId sent from Workmanager
      final int siteId = message as int;
      debugPrint("Received update for siteId: $siteId");
      // Update your Cubit (main isolate)
      context.read<SelfieCubit>().fetchData(siteId);
    });

    // Optional: initial fetch
    context.read<SelfieCubit>().fetchData(widget.siteId);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('selfie_sync_port');
    _receivePort.close();
    imgSerialC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    InkWell(
                      onTap:
                          () => context.read<SelfieCubit>().takePicture(
                            siteId: widget.siteId,
                            imageSubTitle: "Selfie With Client",
                            index: imagesList.length + 1,
                            context: context,
                          ),
                      // context.read<SelfieCubit>().takePicture(
                      //   widget.siteId,
                      //   "Selfie With Client",
                      // ),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey.shade300),
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Selfie With Client", style: AppTextStyle.ts14MB),
                            Icon(Icons.camera_alt, color: AppColors.blue),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    InkWell(
                      onTap:
                          () => context.read<SelfieCubit>().takePicture(
                            siteId: widget.siteId,
                            imageSubTitle: "Selfie With Building",
                            index: imagesList.length + 1,
                            context: context,
                          ),
                      // context.read<SelfieCubit>().takePicture(
                      //   widget.siteId,
                      //   "Selfie With Building",
                      // ),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey.shade300),
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Selfie With Building", style: AppTextStyle.ts14MB),
                            Icon(Icons.camera_alt, color: AppColors.blue),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    Expanded(
                      child: BlocConsumer<SelfieCubit, SelfieState>(
                        buildWhen: (previous, current) {
                          return current is SelfiePickedState || current is SelfieLoadedState;
                        },
                        builder: (context, state) {
                          if (state is SelfiePickedState) {
                            imagesList.add(state.selfie);
                          } else if (state is SelfieLoadedState) {
                            imagesList.clear();
                            imagesList.addAll(state.selfie);
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            itemCount: imagesList.length,
                            // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            //   crossAxisCount: 3,
                            //   mainAxisExtent: 220,
                            //   crossAxisSpacing: 8,
                            //   mainAxisSpacing: 8,
                            // ),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 150, // Maximum width of each item
                              mainAxisExtent: 150,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemBuilder: (context, index) {
                              final itemData = imagesList[index];
                              return Stack(
                                fit: StackFit.expand,
                                alignment: Alignment.bottomLeft,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => ImageViewPage(imageData: itemData)),
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Card(
                                            color: itemData.sync == 1 ? Colors.green.shade400 : Colors.yellow.shade400,
                                            margin: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(4.0)),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(4.0)),
                                                child: Image.file(
                                                  File(itemData.imagePath),
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            updateSerialOrder(
                                              imgData: itemData,
                                              imgSerialC: imgSerialC,
                                              images: imagesList,
                                            );
                                          },
                                          child: Container(
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.all(4.0),
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(4.0),
                                                bottomRight: Radius.circular(4.0),
                                              ),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              spacing: 4.0,
                                              children: [
                                                Icon(Icons.edit, size: 18, color: Colors.grey),
                                                Flexible(
                                                  child: Text(
                                                    "${itemData.syncSerialOrder}",
                                                    style: AppTextStyle.ts14MB,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      padding: EdgeInsets.zero,
                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (_) => CustomAlertDialog(
                                                isShowCancelBtn: true,
                                                title: "Delete Image",
                                                content: "Are you sure you want to delete?",
                                                onConfirm: () {
                                                  context.read<SelfieCubit>().deleteImage(
                                                    widget.siteId,
                                                    itemData.imagePath,
                                                  );
                                                },
                                              ),
                                        );
                                      },
                                      icon: Icon(Icons.close, color: Colors.black, size: 20),
                                    ),
                                  ),

                                  itemData.sync == 1
                                      ? Container()
                                      : Positioned(
                                        bottom: 16,
                                        right: -8,
                                        child: BlocBuilder<SelfieCubit, SelfieState>(
                                          builder: (_, state) {
                                            bool isSync = false;
                                            if (state is SelfieRefreshState && state.index == index) {
                                              isSync = true;
                                            } else if (state is SelfiePickedState) {
                                              if (state.isProcessed == true) {
                                                isSync = true;
                                              } else {
                                                isSync = true;
                                              }
                                            } else {
                                              isSync = false;
                                            }
                                            return IconButton(
                                              icon: RefreshIcon(isSyncing: isSync, icColor: Colors.white),
                                              onPressed:
                                                  isSync == true
                                                      ? null
                                                      : () async {
                                                        // final userId = await StorageFunction.readIntData(
                                                        //   StorageKey.userId,
                                                        // );
                                                        // DateTime timestamp = DateTime.now();
                                                        if (!context.mounted) return;
                                                        WorkManagerTaskRegister.multiImageSync(siteId: itemData.siteId);
                                                        // WorkManagerTaskRegister.selfieSync(
                                                        //   imageData: selfie,
                                                        //   timestamp: timestamp,
                                                        //   userId: userId!,
                                                        // );
                                                      },
                                            );
                                          },
                                        ),
                                      ),
                                ],
                              );
                            },
                          );
                        },
                        listener: (BuildContext context, SelfieState state) {
                          if (state is SelfieSuccessState) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.green,
                                content: Text(state.message, style: AppTextStyle.ts14MW),
                              ),
                            );
                          } else if (state is SelfieErrorState) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(state.message, style: AppTextStyle.ts14MW),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              widget.siteSubmitted == 1
                  ? SizedBox.shrink()
                  : SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: CustomElevatedButton(
                      text: "FINAL SUBMIT CASE",
                      onPressed: () {
                        context.read<SelfieCubit>().finalSubmitMethod(
                          siteId: widget.siteId,
                          initId: widget.initId,
                          siteEngId: widget.siteEngId,
                        );
                      },
                      borderRadius: 2,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void updateSerialOrder({
    required List<ImageEntity> images,
    required ImageEntity imgData,
    required TextEditingController imgSerialC,
  }) {
    if (imgData.syncSerialOrder == 0) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(4.0)),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8.0,
              children: [Icon(Icons.info, color: Colors.yellow.shade400), Text("Info", style: AppTextStyle.ts18MB)],
            ),
            content: Text("Sync your images first, then you can rearrange their order.", style: AppTextStyle.ts14RB),
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade300,
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                  child: Text("OK", style: AppTextStyle.ts16MW),
                ),
              ),
            ],
          );
        },
      );
    } else {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(4.0)),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8.0,
              children: [
                Icon(Icons.info, color: Colors.blueGrey.shade300),
                Text("Add Serial Number", style: AppTextStyle.ts16MB),
              ],
            ),
            content: Form(
              key: formKey,
              child: CustomTextformField(
                controller: imgSerialC,
                hintText: "Enter the serial number",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a serial number";
                  }
                  return null;
                },
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      imgSerialC.clear();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(100.0)),
                      child: Text("CANCEL", style: AppTextStyle.ts16MW),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (formKey.currentState!.validate()) {
                        context.read<SelfieCubit>().updateSerialOrder(
                          imgData: imgData,
                          serialOrder: imgSerialC.text,
                          images: images,
                        );
                        imgSerialC.clear();
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade300,
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      child: Text("SET", style: AppTextStyle.ts16MW),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }
  }
}
