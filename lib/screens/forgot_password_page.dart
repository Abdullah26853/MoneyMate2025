import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/constants/app_colors.dart';
import 'package:receipt_manager/screens/email_sent_page.dart';

import '../components/custom_button.dart';
import '../components/custom_input_field.dart'; // Replace with your color definitions file

class ForgotPasswordPage extends StatefulWidget {
  static const String id = 'forgot_password_page';

  const ForgotPasswordPage({super.key});

  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  String email = '';
  String errorMessage = '';

  // Method to handle password reset
  Future<void> _resetPassword() async {
    if (!mounted) return;

    setState(() {
      errorMessage = ''; // Clear any previous error message
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Check if the widget is still mounted before navigating
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailSentPage(email: email),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: light80,
      appBar: AppBar(
        backgroundColor: light80,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: dark50),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Forgot Password",
          style: TextStyle(
            color: dark50,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Text(
              "Don’t worry.",
              style: TextStyle(
                color: dark50,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Enter your email and we’ll send you a link to reset your password.",
              style: TextStyle(
                color: purple200,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 24),
            CustomTextFormField(
              labelText: "Email",
              onChanged: (value) {
                email = value;
              },
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 24),
            CustomButton(
              text: "Continue",
              backgroundColor: purple100,
              textColor: light80,
              onPressed: () {
                if (email.isEmpty) {
                  setState(() {
                    errorMessage = 'Please enter your email address.';
                  });
                } else {
                  _resetPassword();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
