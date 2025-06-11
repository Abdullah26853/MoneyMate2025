import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipt_manager/screens/login_page.dart';

import '../components/custom_button.dart';
import '../components/underline_text.dart';
import '../constants/app_colors.dart';

class VerificationLinkPage extends StatefulWidget {
  static const String id = 'verification_link_page';
  final User user;

  const VerificationLinkPage({super.key, required this.user});

  @override
  VerificationLinkPageState createState() => VerificationLinkPageState();
}

class VerificationLinkPageState extends State<VerificationLinkPage> {
  String getMaskedEmail(String email) {
    final emailParts = email.split('@');
    final maskedName = '${emailParts[0].substring(0, 5)}*****';
    return '$maskedName@${emailParts[1]}';
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await widget.user.sendEmailVerification();

      // Check if the widget is still mounted before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Verification link sent again to ${widget.user.email}"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send verification email. Try again."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verification',
          style: TextStyle(
            color: dark50,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              'Please verify your email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              DateFormat('HH:mm').format(DateTime.now()),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: purple100,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: dark50,
                ),
                children: [
                  TextSpan(text: 'We sent a verification link to your email '),
                  TextSpan(
                    text: getMaskedEmail(widget.user.email ?? ''),
                    style: TextStyle(color: purple100),
                  ),
                  TextSpan(text: '. Please check your inbox.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  underlineTextSpan(
                    text: "I didn’t receive the link? Send again",
                    onTap: _resendVerificationEmail,
                  ),
                ],
              ),
            ),
            Spacer(),
            CustomButton(
              text: "Continue",
              backgroundColor: purple100,
              textColor: light80,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LogInPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
