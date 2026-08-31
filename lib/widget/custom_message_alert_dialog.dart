import 'package:flutter/material.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';

class CustomMessageAlertDialog extends StatelessWidget {
  final String content;
  final String confirmText;
  final TextStyle? confirmTextStyle;
  final TextStyle? contentTextStyle;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const CustomMessageAlertDialog({
    super.key,
    required this.content,
    required this.onConfirm,
    this.confirmTextStyle,
    this.contentTextStyle,
    this.onCancel,
    this.confirmText = "OK",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsPadding: EdgeInsets.zero,
      insetPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      iconPadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.only(top: 22, left: 20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      content: Text(content, style: contentTextStyle ?? AppTextStyle.ts16LB),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: Text(
            confirmText,
            style:
                confirmTextStyle ??
                AppTextStyle.ts16LB.copyWith(color: AppColors.calenderColor),
          ),
        ),
      ],
    );
  }
}
