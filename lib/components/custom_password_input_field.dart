import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CustomPasswordFormField extends StatefulWidget {
  final String labelText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const CustomPasswordFormField({
    super.key,
    required this.labelText,
    required this.onChanged,
    this.controller,
  });

  @override
  CustomPasswordFormFieldState createState() => CustomPasswordFormFieldState();
}

class CustomPasswordFormFieldState extends State<CustomPasswordFormField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: widget.onChanged,
      controller: widget.controller,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle:
            TextStyle(color: purple200), // Replace with your color variable
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide:
              BorderSide(color: purple100), // Replace with your color variable
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}
