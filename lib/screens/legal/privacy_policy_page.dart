import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  static const String id = 'privacy_policy_page';

  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light gray background
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
        backgroundColor: Colors.white, // Modern app bar style
        elevation: 1,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10), // Space below AppBar
            const Text(
              "Lightspeed Oy respects your privacy and is committed to protecting your personal data. "
                  "This Privacy Policy explains how we collect, use, and share your information when you use the Receipt Manager application.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20), // Space before first section
            const Text(
              "1. Information We Collect",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8), // Space before list
            const Text(
              "- Account Data: Name, email address, and password provided during registration.\n"
                  "- Financial Data: Data related to receipts and expense tracking.\n"
                  "- Device Information: Details about the device, such as operating system and IP address.\n"
                  "- Usage Data: Interaction with the app, including preferences and feature usage.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              "2. How We Use Your Information",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "- Provide and improve the Receipt Manager application.\n"
                  "- Personalize your experience and offer tailored features.\n"
                  "- Comply with legal obligations.\n"
                  "- Respond to user inquiries and provide customer support.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              "3. Sharing Your Information",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We do not sell your personal information. However, we may share your data with third parties under these circumstances:\n\n"
                  "- With your explicit consent.\n"
                  "- To comply with legal obligations.\n"
                  "- With service providers who assist us in operating the app.\n"
                  "- In the event of a merger, acquisition, or asset sale.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              "4. Your Rights",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Under Finnish law, you have the following rights:\n\n"
                  "- Access and review your data.\n"
                  "- Request corrections to incorrect or outdated information.\n"
                  "- Request deletion of your data (right to be forgotten).\n"
                  "- Withdraw consent at any time for processing of your data.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              "5. Contact Us",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "If you have questions or concerns about your privacy, please contact us at:\n\n"
                  "Lightspeed Oy\n"
                  "Address: Kuntokatu 3, 33520 Tampere, Finland\n"
                  "Phone: +358 123456789\n"
                  "Email: privacy@lightspeed.fi",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 40), // Add extra bottom padding
          ],
        ),
      ),
    );
  }
}