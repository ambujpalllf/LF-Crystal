import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';

class CustomTextformField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final TextStyle? lableTextStyle;
  final TextStyle? hintTextStyle;
  final bool obscureText;
  final bool readOnly;
  final bool? filled;
  final Color? fillColor;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? suffix;
  final BoxConstraints? suffixIconConstraints;
  final Function(String)? onChanged;
  final Color? borderColor;
  final Color? lableTextColor;
  final Color? hintTextColor;
  final Color? cursorColor;
  final VoidCallback? onTap;
  final int? maxHintLines;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function(String)? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
  final double? borderRadius;

  const CustomTextformField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.lableTextStyle,
    this.hintTextStyle,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.filled,
    this.fillColor,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.suffixIconConstraints,
    this.onChanged,
    this.borderColor,
    this.hintTextColor,
    this.lableTextColor,
    this.cursorColor,
    this.onTap,
    this.maxHintLines,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      cursorColor: cursorColor,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        suffixIconConstraints: suffixIconConstraints,
        filled: filled,
        fillColor: fillColor,
        labelText: labelText,
        labelStyle: lableTextStyle ?? AppTextStyle.ts14MB.copyWith(color: lableTextColor ?? AppColors.black),
        hintText: hintText,
        errorText: errorText,
        hintMaxLines: maxHintLines,
        hintStyle: hintTextStyle ?? AppTextStyle.ts14RB.copyWith(color: hintTextColor ?? AppColors.black),
        prefixIcon: prefixIcon,
        suffix: suffix,
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
          borderSide: BorderSide(color: borderColor ?? AppColors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
          borderSide: BorderSide(color: borderColor ?? AppColors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
          borderSide: BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
          borderSide: BorderSide(color: AppColors.red),
        ),
      ),
    );
  }
}
