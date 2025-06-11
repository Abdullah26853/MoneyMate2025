import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/constants/app_colors.dart';

TextSpan underlineTextSpan({
  required String text,
  required VoidCallback onTap,
  Color color = purple100, // Default color
  double fontSize = 14, // Default font size
}) {
  return TextSpan(
    text: text,
    style: TextStyle(
      color: color,
      fontSize: fontSize,
      decoration: TextDecoration.underline,
      decorationColor: color,
    ),
    recognizer: TapGestureRecognizer()..onTap = onTap,
  );
}
