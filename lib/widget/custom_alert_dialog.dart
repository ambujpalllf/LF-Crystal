import 'package:flutter/material.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final TextStyle? titleStyle;
  final TextStyle? confirmTextStyle;
  final TextStyle? cancelTextStyle;
  final TextStyle? contentTextStyle;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isShowCancelBtn;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.titleStyle,
    this.confirmTextStyle,
    this.cancelTextStyle,
    this.contentTextStyle,
    this.onCancel,
    this.confirmText = "Yes",
    this.cancelText = "No",
    this.isShowCancelBtn = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
      actionsPadding: EdgeInsets.zero,
      // contentPadding: EdgeInsets.only(left: 26.0, top: 8.0, right: 12.0, bottom: 8.0),
      title:
          title.isEmpty
              ? SizedBox.shrink()
              : Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8.0,
                children: [
                  Icon(Icons.info, color: Colors.blueGrey.shade300),
                  Expanded(child: Text(title, style: titleStyle ?? AppTextStyle.ts16MB)),
                ],
              ),
      content: Text(content, style: contentTextStyle ?? AppTextStyle.ts14RB),
      actions: [
        isShowCancelBtn == true
            ? TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(
                cancelText,
                style: cancelTextStyle ?? AppTextStyle.ts16MB.copyWith(color: AppColors.calenderColor),
              ),
            )
            : SizedBox.shrink(),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: Text(
            confirmText,
            style: confirmTextStyle ?? AppTextStyle.ts16MB.copyWith(color: AppColors.calenderColor),
          ),
        ),
      ],
    );
  }
}
