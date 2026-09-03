import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/cubit/custom_card/custom_card_cubit.dart';
import 'package:lf_crystal/cubit/home/home_cubit.dart';
import 'package:lf_crystal/cubit/home/home_state.dart';
import 'package:lf_crystal/presentation/custom_card_widget.dart';
import 'package:lf_crystal/presentation/filter_page.dart';
import 'package:lf_crystal/presentation/image_list_page.dart';
import 'package:lf_crystal/routes/app_routes_name.dart';
import 'package:lf_crystal/services/foreground_task_handler.dart';
import 'package:lf_crystal/services/work_manager.dart';
import 'package:lf_crystal/services/work_manager_task_register.dart';
import 'package:lf_crystal/widget/custom_alert_dialog.dart';
import 'package:lf_crystal/widget/custom_textform_field.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? response;
  TextEditingController searchC = TextEditingController();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        debugPrint("Current tab index: ${_tabController.index}");
      }
    });
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WorkManagerTaskRegister.syncLocation();
        ForegroundTaskHandler.foregroundServiceInit(context);
        // syncLocation();
      });
    }
    Future.delayed(Duration(seconds: 1), () {
      syncLocation();
    });
  }

  @override
  void dispose() {
    super.dispose();
    searchC.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return BlocConsumer<HomeCubit, HomeState>(
      builder: (BuildContext context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.blue,
            leading: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => CustomAlertDialog(
                        title: "Log Out",
                        content: "Are you sure? Did you want to Log Out.",
                        onConfirm: () {
                          context.read<HomeCubit>().logoutUser();
                        },
                        cancelTextStyle: AppTextStyle.ts14MB.copyWith(color: Colors.teal),
                        confirmTextStyle: AppTextStyle.ts14MB.copyWith(color: Colors.teal),
                      ),
                );
              },
              icon: Icon(Icons.logout_outlined, size: 24, color: AppColors.white),
            ),
            title: Text("Survey List", style: AppTextStyle.ts18MW),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.black, // status bar black
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  response = await Navigator.push(context, MaterialPageRoute(builder: (_) => FilterPage()));
                  debugPrint("Filter Response: $response");
                  if (!context.mounted) return;
                  if (response != null) {
                    context.read<CustomCardCubit>().applyFilter(response!, _tabController.index);
                  } else {
                    context.read<CustomCardCubit>().fetchDataWithDB();
                  }
                  setState(() {});
                },
                icon: Icon(Icons.filter_alt, size: 24, color: response == null ? AppColors.white : AppColors.red),
              ),
              IconButton(
                onPressed: () {
                  context.read<HomeCubit>().downloadData();
                },
                icon: Icon(Icons.download, size: 24, color: AppColors.white),
              ),
              PopupMenuButton(
                iconColor: AppColors.white,
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<String>(
                      value: "Image Sync",
                      onTap: () async {
                        bool response = await Navigator.push(context, MaterialPageRoute(builder: (_) => ImageListPage(siteId: 0)));
                        if (response == true) {
                          if (!context.mounted) return;
                          context.read<CustomCardCubit>().fetchDataWithDB();
                        }
                      },
                      child: Text("Image Sync", style: AppTextStyle.ts14LB),
                    ),
                    PopupMenuItem<String>(
                      value: "Clear Data",
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (_) => CustomAlertDialog(
                                isShowCancelBtn: true,
                                title: "Clear Data",
                                content: "Are you sure? Did you want to clear data.",
                                onConfirm: () async {
                                  context.read<HomeCubit>().clearAllData();
                                },
                              ),
                        );
                      },
                      child: Text("Clear Data", style: AppTextStyle.ts14LB),
                    ),
                    PopupMenuItem<String>(
                      value: "Report",
                      onTap: () async {
                        try {
                          int? siteEng = await StorageFunction.readIntData(StorageKey.userId);
                          int? valuerId = await StorageFunction.readIntData(StorageKey.valuerId);
                          if (siteEng == null || valuerId == null) {
                            // throw Exception("Missing required IDs.");
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Missing required IDs.", style: TextStyle(color: Colors.white))));
                          }
                          String url = "https://valuation.liasesforas.com/Report/siteEngineer?site_eng_id=$siteEng&valuer_id=$valuerId";
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.inAppWebView);
                          } else {
                            // throw Exception("Could not launch URL.");
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Could not launch URL.", style: TextStyle(color: Colors.white))));
                          }
                        } catch (e) {
                          String errorMsg = e.toString().split(":").last;
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(errorMsg, style: TextStyle(color: Colors.white))));
                        }
                      },
                      child: Text("Report", style: AppTextStyle.ts14LB),
                    ),
                    if (!kIsWeb && Platform.isAndroid)
                      PopupMenuItem<String>(
                        value: "Exit",
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              builder:
                                  (_) => CustomAlertDialog(
                                    isShowCancelBtn: true,
                                    title: "Exit App",
                                    content: "Are you sure you want to exit the app?",
                                    onConfirm: () {
                                      SystemNavigator.pop();
                                    },
                                  ),
                            );
                          });
                        },
                        child: Text("Exit", style: AppTextStyle.ts14LB),
                      ),
                  ];
                },
              ),
            ],
          ),
          body: SafeArea(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(color: AppColors.black),
                    child: TabBar(
                      controller: _tabController,
                      indicator: UnderlineTabIndicator(borderSide: BorderSide(width: 4.0, color: AppColors.blue), insets: EdgeInsets.symmetric(horizontal: width * 0.35)),
                      indicatorColor: AppColors.blue,
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.white,
                      labelStyle: AppTextStyle.ts16BW,
                      tabs: [Tab(text: "Pending List"), Tab(text: "Complete List")],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CustomTextformField(
                        controller: searchC,
                        onChanged: (value) {
                          context.read<CustomCardCubit>().searchData(searchC.text);
                        },
                        hintText: "Search here...",
                        suffixIcon: IconButton(
                          onPressed: () {
                            if (searchC.text.isNotEmpty) {
                              searchC.clear();
                              context.read<CustomCardCubit>().fetchDataWithDB();
                            }
                          },
                          icon: Icon(Icons.close),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: TabBarView(controller: _tabController, children: [CustomCardWidget(tabIndex: 0), CustomCardWidget(tabIndex: 1)])),
                ],
              ),
            ),
          ),
        );
      },
      listener: (BuildContext context, state) {
        if (state is DownLoadingState) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(shape: RoundedRectangleBorder(), content: Row(children: [CircularProgressIndicator(), SizedBox(width: 10), Expanded(child: Text("Loading..."))]));
            },
          );
        } else if (state is DownLoadedState) {
          context.read<CustomCardCubit>().fetchDataWithDB();
          Navigator.of(context, rootNavigator: true).pop();
          showDialog(
            context: context,
            builder: (context) {
              return CustomAlertDialog(title: "", content: "${state.messase} Case Downloaded.", confirmText: "OK", onConfirm: () {});
            },
          );
        } else if (state is DownLoadedErrorState) {
          Navigator.of(context, rootNavigator: true).pop();
          showDialog(
            context: context,
            builder: (context) {
              return CustomAlertDialog(title: "", content: state.message, confirmText: "OK", onConfirm: () {});
            },
          );
        } else if (state is HomeDataClearedState) {
          context.read<CustomCardCubit>().fetchDataWithDB();
        } else if (state is LogoutState) {
          Navigator.pushReplacementNamed(context, AppRoutesName.loginPage);
        }
      },
    );
  }
}
