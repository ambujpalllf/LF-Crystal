import 'package:flutter/material.dart';
import 'package:lf_crystal/constants/app_colors.dart';

class MultiSelectDropdown extends StatefulWidget {
  final List<String> options;
  final List<String> selectedValues;
  final String label;
  final TextStyle? labelStyle;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  const MultiSelectDropdown({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.label,
    required this.onChanged,
    this.labelStyle,
    this.enabled = true,
  });

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  late List<String> selectedItems;

  @override
  void initState() {
    super.initState();
    selectedItems = List.from(widget.selectedValues);
  }

  void _showMultiSelectDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        // Temporary list to track changes inside the dialog
        List<String> tempSelectedItems = List.from(selectedItems);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Select ${widget.label}"),
              content: SingleChildScrollView(
                child: ListBody(
                  children:
                      widget.options.map((item) {
                        final isSelected = tempSelectedItems.contains(item);
                        return CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          value: isSelected,
                          title: Text(item),
                          onChanged: (checked) {
                            setStateDialog(() {
                              if (checked == true) {
                                tempSelectedItems.add(item);
                              } else {
                                tempSelectedItems.remove(item);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed:
                      () => Navigator.pop(context, widget.selectedValues),
                ),
                TextButton(
                  child: const Text("OK"),
                  onPressed: () => Navigator.pop(context, tempSelectedItems),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => selectedItems = result);
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _showMultiSelectDialog : null,
      child: AbsorbPointer(
        child: TextFormField(
          maxLines: null,
          minLines: 1,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 12,
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            labelText: widget.label,
            labelStyle: widget.labelStyle,
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
          ),
          controller: TextEditingController(text: selectedItems.join(', ')),
        ),
      ),
    );
  }
}
