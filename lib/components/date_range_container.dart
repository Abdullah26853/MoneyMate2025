import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';

class DateRangeContainer extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onCalendarPressed;

  const DateRangeContainer({
    required this.startDate,
    required this.endDate,
    required this.onCalendarPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: purple80), // Add border color
        borderRadius: BorderRadius.circular(8), // Rounded borders
      ),
      padding: EdgeInsets.all(0), // Add padding
      child: Row(
        mainAxisSize: MainAxisSize.min, // Minimize the size of the Row
        children: [
          SizedBox(width: 10),
          Text(
            '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
            style: TextStyle(color: purple80),
          ),
          IconButton(
            icon: Icon(Icons.calendar_month, color: purple80),
            onPressed: onCalendarPressed, // Calendar button callback
          ),
        ],
      ),
    );
  }
}
