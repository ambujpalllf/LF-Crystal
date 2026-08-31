import 'package:flutter/material.dart';
import 'package:lf_crystal/constants/app_text_style.dart';

class CustomLoadingAlertDialog extends StatelessWidget {
  const CustomLoadingAlertDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 12.0),
          Text("Processing...", style: AppTextStyle.ts14RB),
        ],
      ),
    );
  }
}
