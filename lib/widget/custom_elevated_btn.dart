import 'package:flutter/material.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double borderRadius;
  final Color textColor;
  final TextStyle? textStyle;
  final double? elevation;
  final bool isLoading;

  const CustomElevatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.borderRadius = 8.0,
    this.textStyle,
    this.elevation,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.blue,
        elevation: elevation,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: textStyle ?? AppTextStyle.ts16BW,
      ),
      onPressed: isLoading ? null : onPressed,
      child:
          isLoading
              ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              )
              : Text(text),
    );
  }
}
