import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic indent based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final indent = screenWidth * 0.4; // Adjust this percentage as needed

    return Divider(
      thickness: 3,
      color: purple40,
      indent: indent,
      endIndent: indent,
    );
  }
}
