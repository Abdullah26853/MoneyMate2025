import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/constants/app_colors.dart';

import 'custom_button.dart';
import 'custom_divider.dart';

class DatePickerPopup extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onConfirm;

  const DatePickerPopup({
    required this.initialDate,
    required this.onConfirm,
    super.key,
  });

  @override
  State<DatePickerPopup> createState() => _DatePickerPopupState();
}

class _DatePickerPopupState extends State<DatePickerPopup> {
  late DateTime tempPickedDate;

  @override
  void initState() {
    super.initState();
    tempPickedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 20, vertical: 12), // Reduced vertical padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomDivider(),
          SizedBox(height: 8),
          SizedBox(
            height: 200, // Set a fixed height for the date picker
            child: CupertinoDatePicker(
              initialDateTime: widget.initialDate,
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (DateTime newDate) {
                setState(() {
                  tempPickedDate = newDate;
                });
              },
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CustomButton(
                      text: "Cancel",
                      backgroundColor: purple20,
                      textColor: purple100,
                      onPressed: () {
                        Navigator.pop(context); // Close the popup
                      } // Close the popup},
                      ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CustomButton(
                    text: "Confirm",
                    backgroundColor: purple100,
                    textColor: light80,
                    onPressed: () {
                      widget.onConfirm(tempPickedDate);
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
