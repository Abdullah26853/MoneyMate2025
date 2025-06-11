import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/constants/app_colors.dart'; // Replace with your color definitions file
import 'package:receipt_manager/screens/signup_page.dart';
import 'package:receipt_manager/services/auth_service.dart';

import '../components/custom_button.dart';
import '../components/custom_input_field.dart';
import '../components/custom_password_input_field.dart';
import '../components/underline_text.dart';
import '../logger.dart';
import 'base_page.dart';
import 'forgot_password_page.dart';

class LogInPage extends StatefulWidget {
  static const String id = 'login_page';

  const LogInPage({super.key});

  @override
  LogInPageState createState() => LogInPageState();
}

class LogInPageState extends State<LogInPage> {
  String email = '';
  String password = '';
  String errorMessage = '';

  // Method to extract error message from FirebaseAuthException
  String extractErrorMessage(FirebaseAuthException e) {
    logger.e('FirebaseAuthException code: ${e.code}');
    logger.e('FirebaseAuthException error: ${e.toString()}');

    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your details.';
      default:
        return 'An unexpected error occurred. Please try again.';
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
          "Login",
          style: TextStyle(
            color: dark50,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              CustomTextFormField(
                labelText: "Email",
                onChanged: (value) {
                  email = value;
                },
              ),
              SizedBox(height: 16),
              CustomPasswordFormField(
                labelText: "Password",
                onChanged: (value) {
                  password = value;
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
                text: "Login",
                backgroundColor: purple100,
                textColor: light80,
                onPressed: () async {
                  setState(() {
                    errorMessage = ''; // Clear the error message
                  });

                  try {
                    final user =
                        await AuthService.signInWithEmail(email, password);

                    if (user != null) {
                      // Check if the email is verified
                      if (user.emailVerified) {
                        // Use a post-frame callback to handle navigation outside of async context
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushNamed(context, BasePage.id);
                          }
                        });
                      } else {
                        // Sign out if email is not verified
                        await AuthService.signOut();
                        if (mounted) {
                          setState(() {
                            errorMessage =
                                'Please verify your email before logging in.';
                          });
                        }
                      }
                    }
                  } on FirebaseAuthException catch (e) {
                    if (mounted) {
                      setState(() {
                        errorMessage = extractErrorMessage(e);
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        errorMessage =
                            'An error occurred. Please try again later.';
                      });
                    }
                  }
                },
              ),
              SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to Forgot Password screen
                    Navigator.pushNamed(context, ForgotPasswordPage.id);
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: purple100,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Don’t have an account yet? ",
                    style: TextStyle(color: purple200, fontSize: 16),
                    children: [
                      underlineTextSpan(
                        text: "Sign Up",
                        onTap: () {
                          Navigator.pushNamed(context, SignUpPage.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
