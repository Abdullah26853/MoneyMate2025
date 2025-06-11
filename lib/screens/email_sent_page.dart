import 'package:flutter/material.dart';
import 'package:receipt_manager/constants/app_colors.dart';

import '../components/custom_button.dart';
import 'login_page.dart';

class EmailSentPage extends StatelessWidget {
  static const String id = 'email_sent_page';
  final String email;

  const EmailSentPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon/Image Section
              Image.asset("assets/images/email_sent.png", height: 250),
              const SizedBox(height: 32),
              // Title Text
              Text(
                'Your email is on the way',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Subtitle Text
              Text(
                'Check your email $email and follow the instructions to reset your password',
                style: TextStyle(
                  fontSize: 16,
                  color: dark25,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Back to Login Button
              CustomButton(
                text: "Back to Login",
                backgroundColor: purple100,
                textColor: light80,
                onPressed: () {
                  Navigator.pushNamed(context, LogInPage.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
