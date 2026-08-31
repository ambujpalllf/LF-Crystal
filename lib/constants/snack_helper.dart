import 'package:flutter/material.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';

class CustomSnackBarHelper {
  static succesSnackbar({required BuildContext context, required String message}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: AppColors.green, content: Text(message, style: AppTextStyle.ts14MW)));
  }

  static errorSnackbar({required BuildContext context, required String message}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: AppColors.red, content: Text(message, style: AppTextStyle.ts14MW)));
  }

  static warningSnackbar({required BuildContext context, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.amber.shade400, content: Text(message, style: AppTextStyle.ts14MW)),
    );
  }
}
