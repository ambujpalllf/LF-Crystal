import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/constants/check_location_permission.dart';
import 'package:lf_crystal/cubit/custom_card/custom_card_cubit.dart';
import 'package:lf_crystal/cubit/custom_card/custom_card_state.dart';
import 'package:lf_crystal/model/home_model.dart';
import 'package:lf_crystal/model/image_entity_model.dart';
import 'package:lf_crystal/routes/app_routes_name.dart';
import 'package:lf_crystal/widget/custom_alert_dialog.dart';
import 'package:lf_crystal/widget/custom_card_dialgoues.dart';
import 'package:lf_crystal/widget/custom_elevated_btn.dart';
import 'package:lf_crystal/widget/custom_rich_text.dart';
import 'package:lf_crystal/widget/refresh_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomCardWidget extends StatefulWidget {
  final int tabIndex;
  const CustomCardWidget({super.key, required this.tabIndex});

  @override
  State<CustomCardWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<CustomCardWidget> {
  List<BasicDetails> basicDetailsList = [];
  TextEditingController rejectC = TextEditingController();
  TextEditingController appointmentRemarkC = TextEditingController();
  TextEditingController appointmentDateC = TextEditingController();
  TextEditingController appointmentTimeC = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomCardCubit>().fetchDataWithDB();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    rejectC.dispose();
    appointmentRemarkC.dispose();
    appointmentDateC.dispose();
    appointmentTimeC.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocConsumer<CustomCardCubit, CustomCardState>(
        buildWhen: (previous, current) {
          return current is CustomCardDownloadedState ||
              current is CustomCardLoadingState ||
              current is CustomCardStopLoadingState;
        },
        builder: (context, state) {
          if (state is CustomCardLoadingState) {
            return Center(child: CircularProgressIndicator());
          } else if (state is CustomCardDownloadedState) {
            List<bool> refreshList = [];
            List<ImageEntity> imageList = [];
            List<ImageEntity> syncImageList = [];
            List<ImageEntity> selfieList = [];
            refreshList = List.generate(state.basicDetails.length, (i) => false);
            basicDetailsList.clear();
            basicDetailsList.addAll(
              widget.tabIndex == 0
                  ? state.basicDetails.where((i) => i.siteSubmitted == 0).toList()
                  : state.basicDetails.where((i) => i.siteSubmitted == 1).toList(),
            );
            return ListView.builder(
              shrinkWrap: true,
              itemCount: basicDetailsList.length,
              itemBuilder: (context, index) {
                List<ImageEntity> unSyncImageList = [];
                var itemData = basicDetailsList[index];
                imageList = state.images.where((i) => i.siteId == itemData.siteId!).toList();
                syncImageList = state.images.where((i) => i.sync == 1 && i.siteId == itemData.siteId!).toList();
                unSyncImageList = state.images.where((i) => i.sync == 0 && i.siteId == itemData.siteId!).toList();
                selfieList =
                    state.images
                        .where((i) => i.selectedCategoryTitle == "Selfie" && i.siteId == itemData.siteId!)
                        .toList();
                return Card(
                  color: itemData.siteSubmitted == 1 ? Colors.green.shade200 : AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(itemData.bankName!, style: AppTextStyle.ts16BB),
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(4.0),
                            width: width * 0.53,
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              borderRadius: BorderRadius.only(topRight: Radius.circular(5.0)),
                            ),
                            child:
                                itemData.siteSubmitted == 1
                                    ? Text("Site Submitted: ${itemData.visitDate!}", style: AppTextStyle.ts12RW)
                                    : Text("Visit Date : ${itemData.visitDate!}", style: AppTextStyle.ts12RW),
                          ),
                        ],
                      ),
                      Padding(padding: EdgeInsets.zero, child: Divider(color: AppColors.grey, height: 1, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomRichText(
                              labelText: "Applicant Name : ",
                              valueText: "${itemData.applicantNameSite}",
                              labelStyle: AppTextStyle.ts12MB,
                              valueStyle: AppTextStyle.ts12LB,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: CustomRichText(
                                    labelText: "Conatct Person : ",
                                    valueText: "${itemData.contactName}",
                                    labelStyle: AppTextStyle.ts12MB,
                                    valueStyle: AppTextStyle.ts12LB,
                                  ),
                                ),
                                Expanded(
                                  flex: 0,
                                  child: Text("(Site_id: ${itemData.siteId})", style: AppTextStyle.ts12RB),
                                ),
                              ],
                            ),
                            CustomRichText(
                              labelText: "Applicant Address : ",
                              valueText: "${itemData.addressAsPerSite}",
                              labelStyle: AppTextStyle.ts12MB,
                              valueStyle: AppTextStyle.ts12LB,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: CustomRichText(
                                    labelText: "Contact No : ",
                                    valueText: "${itemData.contactNo}",
                                    labelStyle: AppTextStyle.ts12MB,
                                    valueStyle: AppTextStyle.ts12LB,
                                  ),
                                ),
                                SizedBox(width: 10),
                                InkWell(
                                  onTap: () async {
                                    final numbers = itemData.contactNo!.split(',').map((e) => e.trim()).toList();

                                    if (numbers.length > 1) {
                                      // Show dialog or bottom sheet to pick one
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return ListView(
                                            shrinkWrap: true,
                                            children:
                                                numbers.map((number) {
                                                  return ListTile(
                                                    leading: Icon(Icons.phone, color: Colors.green),
                                                    title: Text(number),
                                                    onTap: () async {
                                                      Navigator.pop(context); // close the sheet
                                                      final Uri url = Uri(scheme: 'tel', path: number);
                                                      if (await canLaunchUrl(url)) {
                                                        await launchUrl(url);
                                                      } else {
                                                        if (!context.mounted) return;
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            backgroundColor: Colors.red,
                                                            content: Text(
                                                              'Could not launch $url',
                                                              style: TextStyle(color: Colors.white),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  );
                                                }).toList(),
                                          );
                                        },
                                      );
                                    } else {
                                      // Only one number — just call directly
                                      final Uri url = Uri(scheme: 'tel', path: numbers.first);
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      } else {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.red,
                                            content: Text(
                                              'Could not launch $url',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Icon(Icons.call_rounded, size: 18, color: Colors.green),
                                ),
                              ],
                            ),
                            CustomRichText(
                              labelText: "Appointment Date Time : ",
                              valueText: "${itemData.appointmentDatetime}",
                              labelStyle: AppTextStyle.ts12MB,
                              valueStyle: AppTextStyle.ts12LB,
                            ),
                            CustomRichText(
                              labelText: "Appointment Remarks : ",
                              valueText: "${itemData.appointmentRemarks}",
                              labelStyle: AppTextStyle.ts12MB,
                              valueStyle: AppTextStyle.ts12LB,
                            ),
                            CustomRichText(
                              labelText: "Distance Travelled : ",
                              valueText: "",
                              labelStyle: AppTextStyle.ts12MB,
                              valueStyle: AppTextStyle.ts12LB,
                            ),

                            Row(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Image Sync Count :",
                                      style: AppTextStyle.ts12MB.copyWith(color: Colors.blueAccent),
                                    ),

                                    Text(
                                      "${syncImageList.length}/${imageList.length}",
                                      style: AppTextStyle.ts12MB.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 10),
                                imageList.isEmpty
                                    ? SizedBox.shrink()
                                    : Expanded(
                                      child: LinearProgressIndicator(
                                        minHeight: 10.0,
                                        value: syncImageList.length / imageList.length,
                                        backgroundColor: Colors.red,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                      ),
                                    ),
                                imageList.isEmpty ? SizedBox.shrink() : SizedBox(width: 10),
                                unSyncImageList.isEmpty
                                    ? SizedBox.shrink()
                                    : IconButton(
                                      visualDensity: VisualDensity(vertical: -4, horizontal: -4),
                                      onPressed: () {
                                        context.read<CustomCardCubit>().imageSync(unSyncImageList);
                                      },
                                      icon: RefreshIcon(isSyncing: refreshList[index]),
                                    ),
                              ],
                            ),
                            SizedBox(height: 10.0),
                            itemData.siteEngAccepted == 1
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          CustomCardDialgoues.acceptCaseDialogue(
                                            context: context,
                                            basicDetails: itemData,
                                          );
                                        },
                                        child: Container(
                                          // width: width * 0.45,
                                          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                          decoration: BoxDecoration(border: Border.all(color: AppColors.blue)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle_outline, color: AppColors.green),
                                              SizedBox(width: 10.0),
                                              Text("Accept", style: AppTextStyle.ts16BB),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          CustomCardDialgoues.rejectCaseDialogue(
                                            context: context,
                                            rejectC: rejectC,
                                            siteId: itemData.siteId!,
                                            initId: itemData.initId!,
                                            siteEngineerId: itemData.siteEngAccepted!,
                                          );
                                        },
                                        child: Container(
                                          // width: width * 0.45,
                                          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                          decoration: BoxDecoration(border: Border.all(color: AppColors.blue)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.block_rounded, color: AppColors.red),
                                              SizedBox(width: 10.0),
                                              Text("Reject", style: AppTextStyle.ts16BB),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                : itemData.appointmentStatus == 0
                                ? SizedBox(
                                  width: width,
                                  child: CustomElevatedButton(
                                    textStyle: AppTextStyle.ts14BW,
                                    borderRadius: 0.0,
                                    text: "FIXED APPOINMENT",
                                    onPressed: () {
                                      CustomCardDialgoues.fixedAppointment(
                                        context: context,
                                        appointmentDateC: appointmentDateC,
                                        appointmentTimeC: appointmentTimeC,
                                        siteId: itemData.siteId!,
                                        initId: itemData.initId!,
                                        siteEngineerId: itemData.siteEngineerId!,
                                        basicDetails: itemData,
                                      );
                                    },
                                  ),
                                )
                                : ButtonActions(
                                  rejectC: rejectC,
                                  itemData: itemData,
                                  width: width,
                                  appointmentRemarkC: appointmentRemarkC,
                                  appointmentDateC: appointmentDateC,
                                  appointmentTimeC: appointmentTimeC,
                                  selfieList: selfieList,
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return Container();
        },
        listener: (BuildContext context, state) {
          if (state is CustomCardErrorState) {
            showDialog(
              context: context,
              builder:
                  (context) => CustomAlertDialog(
                    title: "",
                    content: state.message,
                    onConfirm: () {},
                    confirmText: "OK",
                    confirmTextStyle: AppTextStyle.ts14MB.copyWith(color: Colors.teal),
                  ),
            );
          } else if (state is CustomCardSyncState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(backgroundColor: Colors.grey, content: Text(state.message, style: AppTextStyle.ts14MW)),
            );
          } else if (state is CustomCardSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(backgroundColor: Colors.green, content: Text(state.message, style: AppTextStyle.ts14MW)),
            );
          }
        },
      ),
    );
  }
}

class ButtonActions extends StatelessWidget {
  const ButtonActions({
    super.key,
    required this.rejectC,
    required this.itemData,
    required this.width,
    required this.appointmentRemarkC,
    required this.appointmentDateC,
    required this.appointmentTimeC,
    required this.selfieList,
  });

  final TextEditingController rejectC;
  final BasicDetails itemData;
  final double width;
  final TextEditingController appointmentRemarkC;
  final TextEditingController appointmentDateC;
  final TextEditingController appointmentTimeC;
  final List<ImageEntity> selfieList;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            itemData.siteSubmitted == 1
                ? SizedBox.shrink()
                : Expanded(
                  child: CustomElevatedButton(
                    backgroundColor: AppColors.red,
                    borderRadius: 0,
                    onPressed: () {
                      CustomCardDialgoues.removeDialogue(
                        context: context,
                        rejectC: rejectC,
                        siteId: itemData.siteId!,
                        initId: itemData.initId!,
                        siteEngineerId: itemData.siteEngineerId!,
                      );
                    },
                    text: "REMOVE FROM LIST",
                  ),
                ),
            SizedBox(width: 5.0),
            GestureDetector(
              onTap: () async {
                final p = await CheckLocationPermission.checkPermissionGps(context: context);
                if (!p) return;
                if (!context.mounted) return;
                final response = await Navigator.pushNamed(
                  context,
                  AppRoutesName.survayDetailsPage,
                  arguments: {
                    "siteId": itemData.siteId,
                    "index": 1,
                    "initId": itemData.initId,
                    "siteEngId": itemData.siteEngineerId,
                    "siteSubmitted": itemData.siteSubmitted,
                    "bankId": itemData.bankId,
                    "applicantName": itemData.applicantNameSite,
                  },
                );
                if (response == true) {
                  if (!context.mounted) return;
                  context.read<CustomCardCubit>().fetchDataWithDB();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2.0)),
                child: Row(
                  children: [
                    Text("SELFI", style: AppTextStyle.ts14RB),
                    SizedBox(width: 12.0),
                    selfieList.isEmpty
                        ? Icon(Icons.block_outlined, color: AppColors.red)
                        : Icon(Icons.check_circle_outline, color: AppColors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
        itemData.siteEngAccepted == 3
            ? SizedBox.shrink()
            : SizedBox(
              width: width,
              child: CustomElevatedButton(
                borderRadius: 0,
                text: "CHANGE APPOINMENT",
                onPressed: () {
                  CustomCardDialgoues.changeAppointmentDialogue(
                    context: context,
                    appointmentRemarkC: appointmentRemarkC,
                    appointmentDateC: appointmentDateC,
                    appointmentTimeC: appointmentTimeC,
                    siteEngId: itemData.siteEngineerId!,
                    siteId: itemData.siteId!,
                    initId: itemData.initId!,
                    basicDetails: itemData,
                  );
                },
              ),
            ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: width * 0.6,
              child: CustomElevatedButton(
                borderRadius: 2,
                text: "OPEN CASE/FROM",
                textStyle: AppTextStyle.ts14MW,
                onPressed: () async {
                  final p = await CheckLocationPermission.checkPermissionGps(context: context);
                  if (!p) return;
                  if (!context.mounted) return;
                  final response = await Navigator.pushNamed(
                    context,
                    AppRoutesName.survayDetailsPage,
                    arguments: {
                      "siteId": itemData.siteId,
                      "index": 0,
                      "initId": itemData.initId,
                      "siteEngId": itemData.siteEngineerId,
                      "siteSubmitted": itemData.siteSubmitted,
                      "bankId": itemData.bankId,
                      "applicantName": itemData.applicantNameSite,
                    },
                  );

                  if (response == true) {
                    if (!context.mounted) return;
                    context.read<CustomCardCubit>().fetchDataWithDB();
                  }
                },
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                  decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(4.0)),
                  child: Icon(Icons.image, color: AppColors.blue),
                ),
                SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => CustomAlertDialog(
                            isShowCancelBtn: true,
                            title: "Delete Case",
                            content: "Click Yes to Delete the Case",
                            onConfirm: () {
                              context.read<CustomCardCubit>().deleteData(itemData.siteId!);
                            },
                            cancelTextStyle: AppTextStyle.ts14MB.copyWith(color: Colors.teal),
                            confirmTextStyle: AppTextStyle.ts14MB.copyWith(color: Colors.teal),
                          ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                    decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(4.0)),
                    child: Icon(Icons.delete, color: AppColors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
        itemData.siteSubmitted == 1
            ? SizedBox.shrink()
            : SizedBox(
              width: width,
              child: CustomElevatedButton(
                borderRadius: 2,
                text: "FINAL SUBMIT CASE",
                textStyle: AppTextStyle.ts14MW,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (_) => CustomAlertDialog(
                          isShowCancelBtn: true,
                          title: "Final Submit Data",
                          content: "Are you sure? You want to Final Submit Data.",
                          onConfirm: () {
                            context.read<CustomCardCubit>().finalSubmitMethod(
                              siteId: itemData.siteId!,
                              initId: itemData.initId!,
                              siteEngId: itemData.siteEngineerId!,
                            );
                          },
                        ),
                  );
                },
              ),
            ),
      ],
    );
  }
}
