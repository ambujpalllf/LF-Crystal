import 'package:flutter/material.dart';
import 'package:lf_crystal/constants/app_text_style.dart';

class CustomAppDialogue {
  static Future<String?> mapTypeDialogue({
    required BuildContext context,
    required String selectedType,
  }) {
    List<String> mapTypes = ["Normal", "Satellite", "Terrain", "Hybrid"];

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Select Map Type", style: AppTextStyle.ts16BB),
                    const SizedBox(height: 10),
                    Column(
                      children:
                          mapTypes.map((type) {
                            return RadioListTile<String>(
                              title: Text(type),
                              value: type,
                              // ignore: deprecated_member_use
                              groupValue: selectedType,
                              // ignore: deprecated_member_use
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedType = value;
                                  });
                                  Navigator.pop(context, selectedType);
                                }
                              },
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
