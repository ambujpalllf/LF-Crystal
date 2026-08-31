import 'package:flutter/material.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:lf_crystal/widget/custom_elevated_btn.dart';
import 'package:permission_handler/permission_handler.dart';

class DialogueHelper {
  static Future<String?> showAddDialog({
    required BuildContext context,
    required String applicantName,
    required String imageSubtitle,
  }) {
    TextEditingController notesC = TextEditingController();
    bool isApplicant = true;
    bool isImgSubTitle = true;
    // void updateText() {
    //   List<String> values = [];
    //   if (isApplicant) values.add(applicantName);
    //   if (isImgSubTitle) values.add(imageSubtitle);
    //   notesC.text = values.join(", ");
    // }
    void updateText() {
      List<String> values = [];

      if (isApplicant) values.add(applicantName);
      if (isImgSubTitle) values.add(imageSubtitle);

      // Set as "Notes:" prefix
      if (values.isNotEmpty) {
        notesC.text = "Notes:- ${values.join(", ")}";
      } else {
        notesC.clear();
      }
    }

    updateText();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    visualDensity: VisualDensity.compact,
                    activeColor: AppColors.calenderColor,
                    title: Text(applicantName, style: AppTextStyle.ts14RB),
                    value: isApplicant,
                    onChanged: (value) {
                      setState(() {
                        isApplicant = value!;
                        updateText();
                      });
                    },
                  ),
                  CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.calenderColor,
                    title: Text(imageSubtitle, style: AppTextStyle.ts14RB),
                    value: isImgSubTitle,
                    onChanged: (value) {
                      setState(() {
                        isImgSubTitle = value!;
                        updateText();
                      });
                    },
                  ),
                  TextField(
                    controller: notesC,
                    decoration: const InputDecoration(hintText: "Text to be added to image"),
                  ),
                  SizedBox(height: 15.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: CustomElevatedButton(
                      borderRadius: 0.0,
                      textColor: AppColors.black,
                      backgroundColor: Colors.grey.shade400,
                      text: "Add",
                      onPressed: () {
                        Navigator.pop(context, notesC.text);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> locPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(4.0)),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8.0,
            children: [
              Icon(Icons.info, color: Colors.blueGrey.shade300),
              Text('Location Permission Required', style: AppTextStyle.ts16MB),
            ],
          ),
          content: Text(
            'Location permission has been permanently denied.\n\n'
            'Please enable location permission from App Settings to continue using this feature.',
            style: AppTextStyle.ts14RB,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(100.0)),
                    child: Text("CANCEL", style: AppTextStyle.ts16MW),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await openAppSettings();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    decoration: BoxDecoration(color: Colors.blue.shade300, borderRadius: BorderRadius.circular(100.0)),
                    child: Text('Open Settings', style: AppTextStyle.ts16MW),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
