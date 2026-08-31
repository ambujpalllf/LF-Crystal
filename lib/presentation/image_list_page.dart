import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/cubit/image_list/image_list_cubit.dart';
import 'package:lf_crystal/cubit/image_list/image_list_state.dart';
import 'package:lf_crystal/model/image_entity_model.dart';
import 'package:lf_crystal/presentation/image_view.dart';
import 'package:lf_crystal/services/work_manager_task_register.dart';
import 'package:lf_crystal/widget/custom_alert_dialog.dart';
import 'package:lf_crystal/widget/custom_textform_field.dart';
import 'package:lf_crystal/widget/refresh_widget.dart';

class ImageListPage extends StatefulWidget {
  final int siteId;
  final String? listType;
  const ImageListPage({super.key, required this.siteId, this.listType});

  @override
  State<ImageListPage> createState() => _ImageListPageState();
}

class _ImageListPageState extends State<ImageListPage> {
  TextEditingController imgSerialC = TextEditingController();
  bool isAllSync = false;
  bool isTapSync = false;
  List<ImageEntity> imageList = [];
  List<bool> syncList = [];

  void updateSyncListLength(int length) {
    if (syncList.length != length) {
      syncList = List<bool>.filled(length, false);
    }
  }

  String getFileSize(File file, [int decimals = 2]) {
    int bytes = file.lengthSync();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes == 0) ? 0 : (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  late ReceivePort _receivePort;
  @override
  void initState() {
    super.initState();
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort.sendPort, 'image_list_sync_port');
    _receivePort.listen((message) {
      final int siteId = message as int;
      debugPrint("Received update for siteId: $siteId");
      context.read<ImageListCubit>().fetchData(siteId);
    });

    context.read<ImageListCubit>().fetchData(widget.siteId);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('image_list_sync_port');
    _receivePort.close();
    imgSerialC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          icon: Icon(Icons.arrow_back, color: AppColors.white),
        ),
        title: Text("Image List (${widget.siteId})", style: AppTextStyle.ts18BW),
        actions: [
          IconButton(
            onPressed:
                isAllSync == true || isTapSync == true
                    ? null
                    : () async {
                      setState(() {
                        isTapSync = true;
                        isAllSync = true;
                        for (int i = 0; i < syncList.length; i++) {
                          syncList[i] = true; // Start animation for all unsynced
                        }
                      });

                      await context.read<ImageListCubit>().submitMultiImage(widget.siteId);

                      setState(() {
                        isAllSync = false;
                        for (int i = 0; i < syncList.length; i++) {
                          syncList[i] = false; // Stop all after done
                        }
                      });
                      Future.delayed(Duration(seconds: 40), () {
                        setState(() {
                          isTapSync = false;
                        });
                      });
                    },

            icon: RefreshIcon(isSyncing: isAllSync, icColor: isTapSync ? Colors.grey.shade500 : Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<ImageListCubit, ImageListState>(
          builder: (_, state) {
            if (state is ImageListLoadedState) {
              imageList = state.images;
              updateSyncListLength(imageList.length);
            } else if (state is ImageListLoadingState) {
              return Center(child: CircularProgressIndicator());
            }
            return widget.listType == "Grid"
                ? GridView.builder(
                  shrinkWrap: true,
                  itemCount: imageList.length,
                  padding: EdgeInsets.all(8),
                  // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  //   crossAxisCount: 2,
                  //   mainAxisExtent: 220,
                  //   mainAxisSpacing: 12,
                  //   crossAxisSpacing: 8,
                  //   childAspectRatio: 1.0,
                  // ),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150, // Maximum width of each item
                    mainAxisExtent: 150,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final itemData = imageList[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewPage(imageData: itemData)));
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.directional(
                                  topStart: Radius.circular(4.0),
                                  topEnd: Radius.circular(4.0),
                                ),
                              ),
                              margin: EdgeInsets.all(0),
                              clipBehavior: Clip.none,
                              color: itemData.sync == 1 ? Colors.green.shade400 : Colors.yellow.shade400,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4.0),
                                          topRight: Radius.circular(4.0),
                                        ),
                                        child: Image.file(File(itemData.imagePath), fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    // top: 10,
                                    top: -2,
                                    right: -3,
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
                                                content: "Are you sure you want to delete this image?",
                                                onConfirm: () {
                                                  context.read<ImageListCubit>().deleteImage(
                                                    siteId: widget.siteId,
                                                    imgId: itemData.id!,
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
                                        right: 5,
                                        bottom: 0,
                                        child: GestureDetector(
                                          onTap:
                                              syncList[index] == true || isTapSync == true
                                                  ? null
                                                  : () async {
                                                    setState(() {
                                                      isTapSync = true;
                                                      for (int i = 0; i < syncList.length; i++) {
                                                        syncList[i] = i == index;
                                                      }
                                                    });
                                                    // await context.read<ImageListCubit>().refreshImageSync(
                                                    //   widget.siteId,
                                                    //   itemData,
                                                    // );
                                                    // int? userId = await StorageFunction.readIntData(StorageKey.userId);
                                                    WorkManagerTaskRegister.multiImageSync(siteId: itemData.siteId);
                                                    // WorkManagerTaskRegister.selfieSync(
                                                    //   imageData: itemData,
                                                    //   timestamp: DateTime.now(),
                                                    //   userId: userId!,
                                                    // );
                                                    setState(() {
                                                      for (int i = 0; i < syncList.length; i++) {
                                                        syncList[i] = false;
                                                      }
                                                    });
                                                    Future.delayed(Duration(seconds: 40), () {
                                                      setState(() {
                                                        isTapSync = false;
                                                      });
                                                    });
                                                  },
                                          child: RefreshIcon(
                                            isSyncing: syncList[index],
                                            icColor: isTapSync == true ? Colors.grey.shade500 : Colors.white,
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              updateSerialOrder(imgData: itemData, imgSerialC: imgSerialC);
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
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 4.0,
                                children: [
                                  Icon(Icons.edit, size: 18, color: Colors.grey),
                                  Flexible(child: Text("${itemData.syncSerialOrder}", style: AppTextStyle.ts14MB)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
                : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: imageList.length,
                    itemBuilder: (context, index) {
                      var itemData = imageList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: itemData.sync == 1 ? Colors.green.shade300 : Colors.yellow.shade300,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(itemData.imagePath.split("/").last),
                                    Text(DateFormat("dd-MM-yyyy").format(itemData.moDateTime)),
                                  ],
                                ),
                              ),
                              itemData.sync == 1
                                  ? const SizedBox()
                                  : GestureDetector(
                                    onTap:
                                        syncList[index] == true
                                            ? null
                                            : () async {
                                              setState(() {
                                                isTapSync = true;
                                                for (int i = 0; i < syncList.length; i++) {
                                                  syncList[i] = i == index;
                                                }
                                              });
                                              // await context.read<ImageListCubit>().refreshImageSync(
                                              //   widget.siteId,
                                              //   itemData,
                                              // );
                                              // int? userId = await StorageFunction.readIntData(StorageKey.userId);
                                              WorkManagerTaskRegister.multiImageSync(siteId: itemData.siteId);
                                              // WorkManagerTaskRegister.selfieSync(
                                              //   imageData: itemData,
                                              //   timestamp: DateTime.now(),
                                              //   userId: userId!,
                                              // );
                                              setState(() {
                                                for (int i = 0; i < syncList.length; i++) {
                                                  syncList[i] = false;
                                                }
                                              });
                                              Future.delayed(Duration(seconds: 40), () {
                                                setState(() {
                                                  isTapSync = false;
                                                });
                                              });
                                            },
                                    child: RefreshIcon(
                                      isSyncing: syncList[index],
                                      icColor: isTapSync == true ? Colors.grey.shade500 : Colors.white,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
          },
          listener: (context, state) {
            if (state is ImageListErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(backgroundColor: Colors.red, content: Text(state.message, style: AppTextStyle.ts14MW)),
              );
            } else if (state is ImageListSuccesState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(backgroundColor: Colors.green, content: Text(state.message, style: AppTextStyle.ts14MW)),
              );
            }
          },
        ),
      ),
    );
  }

  void updateSerialOrder({required ImageEntity imgData, required TextEditingController imgSerialC}) {
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
                        context.read<ImageListCubit>().updateSerialOrder(
                          imgData: imgData,
                          serialOrder: imgSerialC.text,
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
