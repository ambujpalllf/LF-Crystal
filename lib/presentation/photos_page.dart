import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/constants/check_location_permission.dart';
import 'package:lf_crystal/cubit/photo/photo_cubit.dart';
import 'package:lf_crystal/cubit/photo/photo_state.dart';
import 'package:lf_crystal/model/photo_category_model.dart';
import 'package:lf_crystal/presentation/image_list_page.dart';
import 'package:lf_crystal/widget/custom_elevated_btn.dart';

class PhotosPage extends StatefulWidget {
  final int siteId;
  final int initId;
  final int siteEngId;
  final int siteSubmitted;
  final String applicantName;
  final int bankId;
  const PhotosPage({
    super.key,
    required this.siteId,
    required this.initId,
    required this.siteEngId,
    required this.siteSubmitted,
    required this.applicantName,
    required this.bankId,
  });

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  TextEditingController categoryC = TextEditingController();
  List<SubCategory> subCategoryList = [];
  List<String> categoryList = [];
  String selectedCategory = "";
  @override
  void initState() {
    super.initState();
    context.read<PhotoCubit>().fetchCategoryData();
  }

  @override
  void dispose() {
    super.dispose();
    categoryC.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BlocConsumer<PhotoCubit, PhotoState>(
                builder: (context, state) {
                  if (state is PhotoLoadingState) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (state is PhotoLoadedState) {
                    final categoryDatum = state.photoCategoryResponse.data!;
                    categoryList =
                        categoryDatum.map((item) => item.categoryType ?? "").where((e) => e.isNotEmpty).toList();
                    subCategoryList = state.subcategory;
                    if (state.initialValue.isNotEmpty && state.initialValue != "") {
                      selectedCategory = state.initialValue;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  icon: SizedBox.shrink(),
                                  decoration: InputDecoration(
                                    labelText: 'Select Category',
                                    labelStyle: AppTextStyle.ts14MB,
                                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.grey)),
                                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.grey)),
                                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.grey)),
                                  ),
                                  items:
                                      categoryList.map<DropdownMenuItem<String>>((category) {
                                        return DropdownMenuItem<String>(value: category, child: Text(category));
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategory = value!;
                                    });
                                    context.read<PhotoCubit>().selectDropdown(value!);
                                  },
                                  initialValue: categoryList.contains(selectedCategory) ? selectedCategory : null,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(2.0),
                                decoration: BoxDecoration(border: Border.all(color: AppColors.blue)),
                                child: IconButton(
                                  onPressed: () {
                                    _showAddCategoryDialog(
                                      context: context,
                                      categoryController: categoryC,
                                      categoryList: categoryList,
                                    );
                                  },
                                  icon: Icon(Icons.add, color: AppColors.blue),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15.0),
                          subCategoryList.isEmpty
                              ? SizedBox.shrink()
                              : Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: subCategoryList.length,
                                  itemBuilder: (context, index) {
                                    var itemData = subCategoryList[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10.0),
                                      child: Container(
                                        decoration: BoxDecoration(color: Colors.grey.shade300),
                                        padding: EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(itemData.subCategoryType ?? "", style: AppTextStyle.ts14MB),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.3,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  selectedCategory == "Selfie"
                                                      ? SizedBox()
                                                      : InkWell(
                                                        onTap: () {
                                                          context.read<PhotoCubit>().takePictureFromGallery(
                                                            widget.siteId,
                                                            selectedCategory,
                                                            itemData.subCategoryType!,
                                                          );
                                                        },
                                                        child: Icon(Icons.image, color: AppColors.blue),
                                                      ),

                                                  InkWell(
                                                    onTap: () {
                                                      context.read<PhotoCubit>().takePicture(
                                                        siteId: widget.siteId,
                                                        imageTitle: selectedCategory,
                                                        imageSubTitle: itemData.subCategoryType!,
                                                        context: context,
                                                        bankId: widget.bankId,
                                                        applicantName: widget.applicantName,
                                                      );
                                                    },
                                                    child: Icon(Icons.camera_alt, color: AppColors.blue),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
                listener: (BuildContext context, state) {
                  if (state is PhotoErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.red,
                        content: Text(state.message, style: TextStyle(color: AppColors.white)),
                      ),
                    );
                  } else if (state is PhotoSuccessState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: Colors.green, content: Text(state.message, style: AppTextStyle.ts14MW)),
                    );
                  }
                },
                buildWhen: (previous, current) => current is PhotoLoadedState || current is StopLoadingState,
              ),
            ),
            widget.siteSubmitted == 1
                ? SizedBox.shrink()
                : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: CustomElevatedButton(
                      text: "FINAL SUBMIT CASE",
                      onPressed: () {
                        context.read<PhotoCubit>().finalSubmitMethod(
                          siteId: widget.siteId,
                          initId: widget.initId,
                          siteEngId: widget.siteEngId,
                        );
                      },
                      borderRadius: 2,
                    ),
                  ),
                ),
            SizedBox(height: 5.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(color: AppColors.black),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () async {
                      bool permission = await CheckLocationPermission.checkPermissionGps(context: context);
                      if (!permission) return;
                      if (!context.mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ImageListPage(siteId: widget.siteId)));
                    },
                    child: Column(
                      children: [
                        Icon(Icons.menu, color: AppColors.blue, size: 28.0),
                        SizedBox(height: 5.0),
                        Text("List View", style: AppTextStyle.ts14RW),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      bool permission = await CheckLocationPermission.checkPermissionGps(context: context);
                      if (!permission) return;
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ImageListPage(siteId: widget.siteId, listType: "Grid")),
                      );
                    },
                    child: Column(
                      children: [
                        Icon(Icons.camera_alt, color: AppColors.blue, size: 28.0),
                        SizedBox(height: 5.0),
                        Text("Photo View", style: AppTextStyle.ts14RW),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog({
    required BuildContext context,
    required TextEditingController categoryController,
    required List<String> categoryList,
  }) {
    bool showError = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: categoryController,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\- ]'))],
                    decoration: InputDecoration(
                      hintText: "New Category",
                      isDense: true,
                      suffixIcon: showError ? Icon(Icons.error, color: Colors.red) : null,
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: CustomElevatedButton(
                      borderRadius: 0,
                      onPressed: () {
                        final text = categoryController.text;
                        if (text.isEmpty) {
                          setState(() {
                            showError = true;
                          });
                          return;
                        }

                        // Call cubit to add category
                        // context.read<PhotoCubit>().addCategory(text);
                        context.read<PhotoCubit>().addCategory(category: text, categoryList: categoryList);

                        // Close dialog
                        Navigator.pop(context);
                      },
                      text: "Add",
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
