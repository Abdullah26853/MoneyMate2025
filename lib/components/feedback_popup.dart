import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'custom_button.dart';
import 'custom_divider.dart';

class FeedbackDialog extends StatelessWidget {
  FeedbackDialog({super.key});

  final TextEditingController _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              12, // Adjust for keyboard
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomDivider(),
            SizedBox(height: 18),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey, // Default border color
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors
                        .grey, // Border color when enabled but not focused
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: purple60, // Border color when the field is focused
                    width: 2.0,
                  ),
                ),
                hintText:
                    'We value your feedback! Please share your thoughts here...',
                hintStyle: TextStyle(
                  color: Colors.grey, // Set hint text color to grey
                  fontSize: 16, // Optional: Adjust font size
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: CustomButton(
                      text: "Cancel",
                      backgroundColor: purple20,
                      textColor: purple100,
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: CustomButton(
                      text: "Submit",
                      backgroundColor: purple100,
                      textColor: light80,
                      onPressed: () async {
                        final feedback = _feedbackController.text.trim();
                        if (feedback.isNotEmpty) {
                          Navigator.of(context).pop(); // Close the dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Thank you for your feedback!')),
                          );
                          // Handle your feedback submission logic here
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Feedback cannot be empty!')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Static method to show the feedback dialog
  static Future<void> showFeedbackDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FeedbackDialog();
      },
    );
  }
}
