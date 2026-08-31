import 'package:flutter/material.dart';
import 'package:lf_crystal/constants/app_text_style.dart';

class CustomRichText extends StatelessWidget {
  final String labelText;
  final String valueText;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const CustomRichText({
    super.key,
    required this.labelText,
    required this.valueText,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: labelText,
        style: labelStyle ?? AppTextStyle.ts14LB,
        children: [
          TextSpan(text: valueText, style: valueStyle ?? AppTextStyle.ts14LB),
        ],
      ),
    );
  }
}
