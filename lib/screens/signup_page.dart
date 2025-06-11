import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/verification_link_page.dart';

import '../components/custom_button.dart';
import '../components/custom_input_field.dart';
import '../components/custom_password_input_field.dart';
import '../components/underline_text.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login_page.dart';

import 'package:receipt_manager/screens/legal/terms_of_service_page.dart';
import 'package:receipt_manager/screens/legal/privacy_policy_page.dart';


class SignUpPage extends StatefulWidget {
  static const String id = 'sign_up_page';

  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  bool _isChecked = false;
  String email = '';
  String password = '';
  String userName = '';
  String errorMessage = ''; // To display errors

  final TapGestureRecognizer _loginRecognizer = TapGestureRecognizer();
  final TextEditingController _userNameController = TextEditingController();

  // Create an instance of UserService
  final UserService _userService = UserService();

  // Function to extract error message from FirebaseAuthException
  String extractErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    _loginRecognizer.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_isChecked) return;

    try {
      setState(() {
        errorMessage = ''; // Clear previous errors
      });

      // Register the user using AuthService
      final newUser = await AuthService.registerWithEmail(email, password);

      if (newUser != null) {
        // Send email verification
        await newUser.sendEmailVerification();

        // Save username to the profile using UserService
        await _userService.addUserProfile(
          email: email,
          userName: userName,
        );

        // Check if the widget is still mounted before navigating
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationLinkPage(
                user: newUser,
              ),
            ),
          );
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
          errorMessage = 'An error occurred. Please try again later.';
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
          "Sign Up",
          style: TextStyle(
            color: dark50,
            fontSize: 24, // here was 20
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
              const SizedBox(height: 30), // Increase top spacing-SizedBox(height: 20),
              CustomTextFormField(
                labelText: "Name",
                onChanged: (value) {
                  userName = value;
                },
              ),
              const SizedBox(height: 20), // Increase the input box spacing - SizedBox(height: 16),
              CustomTextFormField(
                labelText: "Email",
                onChanged: (value) {
                  email = value;
                },
              ),
              const SizedBox(height: 20),//SizedBox(height: 16),
              CustomPasswordFormField(
                labelText: "Password",
                onChanged: (value) {
                  password = value;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _isChecked,
                    onChanged: (value) {
                      setState(() {
                        _isChecked = value ?? false;
                      });
                    },
                    activeColor: purple100,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4), // Checkbox rounded corners
                    ),

                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: "By signing up, you agree to the ",
                        style: TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Terms of Service",
                            style: TextStyle(color: purple100),

                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, TermsOfServicePage.id);
                              },
                          ),
                          TextSpan(
                            text: " and ",
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: TextStyle(color: purple100),

                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, PrivacyPolicyPage.id);
                              },


                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 30), // Increase the top spacing of the button - SizedBox(height: 20),

              CustomButton(
                text: "Sign Up",
                backgroundColor: _isChecked ? purple100 : Colors.grey.shade300,
                textColor: _isChecked ? light80 : Colors.black54,
                onPressed: _isChecked
                    ? () async {
                        await _registerUser();
                      }
                    : () {}, // No-op function when unchecked
              ),
              const SizedBox(height: 30),//SizedBox(height: 16),

              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: purple200, fontSize: 16),
                    children: [
                      underlineTextSpan(
                        text: "Login",
                        onTap: () {
                          Navigator.pushNamed(context, LogInPage.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40), // Increase bottom margin
            ],
          ),
        ),
      ),
    );
  }
}
