import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String label;
  final String? hintText;
  final ValueChanged<DateTime> onDateSelected;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final DateFormat? dateFormat;
  final TextEditingController textController;
  final bool enabled;

  const CustomDatePicker({
    super.key,
    required this.label,
    required this.onDateSelected,
    required this.textController,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.labelStyle,
    this.hintText,
    this.hintStyle,
    this.dateFormat,
    this.enabled = true,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? widget.initialDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(2000),
      lastDate: widget.lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.blue),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Update the controller with formatted date
        final dateFormat = widget.dateFormat ?? DateFormat('yyyy-MM-dd');
        widget.textController.text = dateFormat.format(picked);
      });
      widget.onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _pickDate : null,
      child: AbsorbPointer(
        child: TextFormField(
          controller: widget.textController,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: widget.hintStyle ?? AppTextStyle.ts14RB,
            labelText: widget.label,
            labelStyle: widget.labelStyle ?? AppTextStyle.ts12RB,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: AppColors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: AppColors.grey),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: AppColors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: AppColors.red),
            ),
            // suffixIcon: const Icon(Icons.calendar_today),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 12,
            ),
          ),
        ),
      ),
    );
  }
}
