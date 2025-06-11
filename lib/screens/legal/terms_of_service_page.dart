import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  static const String id = 'terms_of_service_page';

  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light gray background
      appBar: AppBar(
        title: const Text("Terms of Service"),
        centerTitle: true,
        backgroundColor: Colors.white,
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
              "Welcome to Receipt Manager. By using our application, you agree to comply with these terms and conditions. Please read them carefully before using our services.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20), // Space before first section
            const Text(
              "1. Acceptance of Terms",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "By accessing or using Receipt Manager, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree, you may not use our application.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              "2. User Responsibilities",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "- You are responsible for maintaining the confidentiality of your account information.\n"
                  "- You must not use the application for any illegal or unauthorized purpose.\n"
                  "- You agree to provide accurate and up-to-date information during registration and usage.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              "3. Intellectual Property",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "All content, logos, and trademarks associated with Receipt Manager are owned by Lightspeed Oy. You may not reproduce, distribute, or create derivative works without explicit permission.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              "4. Limitation of Liability",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Lightspeed Oy is not responsible for any direct or indirect damages arising from the use of Receipt Manager, including but not limited to data loss, financial discrepancies, or unauthorized access.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              "5. Changes to the Terms",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We reserve the right to modify these Terms of Service at any time. Changes will be effective immediately upon posting. Continued use of the application signifies acceptance of the revised terms.",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              "6. Contact Information",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "If you have questions or concerns regarding these terms, please contact us at:\n\n"
                  "Lightspeed Oy\n"
                  "Address: Kuntokatu 3, 33520 Tampere, Finland\n"
                  "Phone: +358 123456789\n"
                  "Email: support@lightspeed.fi",
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 40), // Extra bottom space
          ],
        ),
      ),
    );
  }
}
