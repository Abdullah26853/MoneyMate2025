import 'package:flutter/material.dart';
import 'package:receipt_manager/constants/app_colors.dart';
import 'package:receipt_manager/screens/login_page.dart';
import 'package:receipt_manager/screens/signup_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../components/custom_button.dart';

class WelcomePage extends StatefulWidget {
  static const String id = 'welcome_page';

  const WelcomePage({super.key});

  @override
  WelcomePageState createState() => WelcomePageState();
}

class WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                buildPage(
                  image: "assets/images/control.png",
                  title: "Gain total control of your money",
                  subtitle:
                      "Become your own money manager and make every cent count",
                ),
                buildPage(
                  image: "assets/images/track.png",
                  title: "Know where your money goes",
                  subtitle:
                      "Track your transaction easily, with categories and financial report",
                ),
                buildPage(
                  image: "assets/images/plan.png",
                  title: "Planning ahead",
                  subtitle:
                      "Setup your budget for each category so you stay in control",
                ),
              ],
            ),
          ),
          SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: WormEffect(
              dotColor: purple20, // Inactive dot color
              activeDotColor: purple100, // Active dot color
              dotHeight: 8,
              dotWidth: 8,
            ),
          ),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                CustomButton(
                  text: "Sign Up",
                  backgroundColor: purple100,
                  textColor: light80,
                  onPressed: () {
                    // Navigate to Sign Up page
                    Navigator.pushNamed(context, SignUpPage.id);
                  },
                ),
                SizedBox(height: 12),
                CustomButton(
                  text: "Login",
                  backgroundColor: purple100,
                  textColor: light80,
                  onPressed: () {
                    // Navigate to Login page
                    Navigator.pushNamed(context, LogInPage.id);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget buildPage({
    required String image,
    required String title,
    required String subtitle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight, // Ensure it fills available space
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2, // Add flexibility for scaling
                      child: Image.asset(image, height: 250), // Page's image
                    ),
                    SizedBox(height: 24),
                    Expanded(
                      flex: 1, // Add flexibility for title
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.w700, // Bold
                            color: dark50),
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      flex: 1, // Add flexibility for subtitle
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w500, // ExtraLight
                            color: purple200),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
