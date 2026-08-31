import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/cubit/open_case/open_case_cubit.dart';
import 'package:lf_crystal/cubit/photo/photo_cubit.dart';
import 'package:lf_crystal/presentation/open_case_form_page.dart';
import 'package:lf_crystal/presentation/photos_page.dart';
import 'package:lf_crystal/presentation/selfie_page.dart';

class SurveyDetailsPage extends StatefulWidget {
  final int siteId;
  final int index;
  final int initId;
  final int siteEngId;
  final int siteSubmitted;
  final String applicantName;
  final int bankId;
  const SurveyDetailsPage({
    super.key,
    required this.siteId,
    required this.index,
    required this.initId,
    required this.siteEngId,
    required this.siteSubmitted,
    required this.applicantName,
    required this.bankId,
  });

  @override
  State<SurveyDetailsPage> createState() => _SurveyDetailsPageState();
}

class _SurveyDetailsPageState extends State<SurveyDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<OpenCaseCubit>().fetchOpenCaseBySiteId(widget.siteId);
    context.read<PhotoCubit>().fetchCategoryData();
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return; // Prevent premature calls

    // Trigger the desired Cubit methods when a tab is changed
    context.read<OpenCaseCubit>().fetchOpenCaseBySiteId(widget.siteId);
    context.read<PhotoCubit>().fetchCategoryData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange); // Always clean up listeners
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, true),
          icon: Icon(Icons.arrow_back, color: AppColors.white),
        ),
        title: Text("Survey Detail (${widget.siteId})", style: AppTextStyle.ts18BW),
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          initialIndex: widget.index,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(color: AppColors.black),
                child: TabBar(
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 4.0, color: AppColors.blue),
                    insets: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.21),
                  ),
                  indicatorColor: AppColors.blue,
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.white,
                  labelStyle: AppTextStyle.ts16BW,
                  tabs: [Tab(text: "Survey"), Tab(text: "Selfie"), Tab(text: "Photos")],
                ),
              ),
              const SizedBox(height: 10.0),
              Expanded(
                child: TabBarView(
                  clipBehavior: Clip.none,
                  children: [
                    OpenCaseFormPage(
                      siteId: widget.siteId,
                      initId: widget.initId,
                      siteEngId: widget.siteId,
                      siteSubmitted: widget.siteSubmitted,
                    ),
                    SelfiePage(
                      siteId: widget.siteId,
                      initId: widget.initId,
                      siteEngId: widget.siteId,
                      siteSubmitted: widget.siteSubmitted,
                    ),
                    PhotosPage(
                      siteId: widget.siteId,
                      initId: widget.initId,
                      siteEngId: widget.siteId,
                      siteSubmitted: widget.siteSubmitted,
                      bankId: widget.bankId,
                      applicantName: widget.applicantName,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
