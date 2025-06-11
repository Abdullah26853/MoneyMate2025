import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:receipt_manager/screens/budget_page.dart';

import '../components/currency_roller_picker_popup.dart';
import '../components/feedback_popup.dart';
import '../components/logout_popup.dart';
import '../constants/app_colors.dart';
import '../logger.dart';
import '../providers/authentication_provider.dart';
import '../providers/user_provider.dart';
import 'category_page.dart';

class SettingsPage extends StatefulWidget {
  static const String id = 'settings_page';

  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final _picker = ImagePicker();
  XFile? _profileImage;
  late TextEditingController _nameController;
  late UserProvider userProvider;
  bool _isEditingName = false;

  String? currencyCode;
  String? currencySymbol;

  @override
  void initState() {
    super.initState();

    // Access the UserProvider instance
    userProvider = Provider.of<UserProvider>(context, listen: false);

    // Fetch the user profile data
    userProvider.fetchUserProfile();

    // Initialize the name controller
    _nameController = TextEditingController(text: userProvider.userName);

    // Initialize currency code and symbol
    currencyCode = userProvider.currencyCode;
    if (currencyCode != null && currencyCode!.isNotEmpty) {
      currencySymbol =
          NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
    } else {
      currencySymbol = '€'; // Default symbol
    }

    // Wait for user profile to fetch and reflect updates after widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Fetch updated profile image from Firestore
        final profileImagePath = userProvider.profileImagePath;
        if (profileImagePath != null && profileImagePath.isNotEmpty) {
          _profileImage = null; // Ensure local path is not used
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose(); // Dispose controller when the widget is disposed
    debugPrint('Disposing SettingsPage widget...');
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      if (!mounted) return;
      setState(() {
        _profileImage = image; // Temporarily show the image
      });

      try {
        // Upload the image and update the profile image path
        await userProvider.updateProfileImage(image.path);
        if (mounted) {
          // Check again before showing the Snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile image updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile image: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveUserName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != userProvider.userName) {
      // Save the updated name to the UserProvider
      await userProvider.updateUserProfile(userName: newName);
    }
    if (mounted) {
      setState(() {
        _isEditingName = false;
      });
    }
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CurrencyPicker(
          selectedCurrencyCode: 'EUR', // Provide a default,
          onCurrencyCodeSelected: (String newCurrencyCode) async {
            // Proceed with the update if the new name is different from the current name, even if empty
            if (newCurrencyCode != userProvider.currencyCode) {
              logger.i("Updating currency to $newCurrencyCode");
              await userProvider.updateUserProfile(
                  currencyCode: newCurrencyCode);
              // Update the state to reflect the new currency immediately
              setState(() {
                currencyCode = newCurrencyCode;
                currencySymbol =
                    NumberFormat.simpleCurrency(name: newCurrencyCode)
                        .currencySymbol;
              });
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    final userEmail = authProvider.user?.email;

    // Get screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: light90,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the default back arrow
        backgroundColor: light90,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01), // Dynamic padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap:
                            _pickImage, // Opens the image picker for changing the profile picture
                        child: Container(
                          width: screenWidth *
                              0.2, // Adjust size dynamically based on screen width
                          height: screenWidth *
                              0.2, // Adjust size dynamically based on screen width
                          padding: EdgeInsets.all(screenWidth *
                              0.01), // Dynamic padding based on screen size
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: purple80,
                                width: screenWidth *
                                    0.005), // Dynamic border width
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            backgroundImage: _profileImage != null
                                ? FileImage(File(_profileImage!.path))
                                : (userProvider.profileImagePath != null &&
                                        userProvider
                                            .profileImagePath!.isNotEmpty &&
                                        userProvider.profileImagePath!
                                            .contains(','))
                                    ? MemoryImage(
                                        base64Decode(userProvider
                                            .profileImagePath!
                                            .split(',')[1]),
                                      )
                                    : null,
                            radius: screenWidth *
                                0.075, // Dynamic radius for CircleAvatar
                            child: (userProvider.profileImagePath == null ||
                                    userProvider.profileImagePath!.isEmpty)
                                ? Icon(Icons.person,
                                    size: screenWidth * 0.075,
                                    color: Colors.grey)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: screenWidth * 0.03), // Dynamic spacing
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userEmail ?? "Email not available",
                          style: TextStyle(
                              color: purple200,
                              fontSize:
                                  screenWidth * 0.04), // Dynamic font size
                        ),
                        _isEditingName
                            ? TextFormField(
                                controller: _nameController,
                                style: TextStyle(
                                  color: dark75,
                                  fontSize:
                                      screenWidth * 0.05, // Dynamic font size
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: 'Your Name',
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              )
                            : Text(
                                (userProvider.userName == null ||
                                        userProvider.userName!.isEmpty)
                                    ? 'Your Name'
                                    : userProvider.userName!,
                                style: TextStyle(
                                  color: dark75,
                                  fontSize:
                                      screenWidth * 0.05, // Dynamic font size
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ),
                  _isEditingName
                      ? Row(
                          mainAxisSize:
                              MainAxisSize.min, // Shrink row to fit content
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Check Button
                            SizedBox(
                              height: screenHeight * 0.04, // Dynamic height
                              width: screenHeight * 0.04, // Dynamic width
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.zero, // No extra padding
                                  backgroundColor: Colors
                                      .green, // Green background for "Save"
                                  elevation: 3, // Slight 3D effect
                                ),
                                onPressed: () async {
                                  await _saveUserName();
                                  setState(() {
                                    _isEditingName = false;
                                  });
                                },
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18, // Small icon size
                                ),
                              ),
                            ),
                            SizedBox(
                                width: screenWidth *
                                    0.02), // Adjust gap dynamically
                            // Cross Button
                            SizedBox(
                              height: screenHeight * 0.04, // Dynamic height
                              width: screenHeight * 0.04, // Dynamic width
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.zero, // No extra padding
                                  backgroundColor:
                                      Colors.red, // Red background for "Cancel"
                                  elevation: 3, // Slight 3D effect
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isEditingName = false;
                                    _nameController.text =
                                        userProvider.userName ?? '';
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18, // Small icon size
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: purple100, // Purple background
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                offset:
                                    Offset(2, 2), // Shadow offset for 3D effect
                                blurRadius: 4, // Blur for soft shadow edges
                              ),
                            ],
                          ),
                          width: screenWidth * 0.1, // Dynamic size
                          height: screenWidth * 0.1, // Dynamic size
                          child: IconButton(
                            icon: Icon(Icons.edit,
                                color: Colors.white,
                                size: 18), // Smaller icon size
                            onPressed: () {
                              setState(() {
                                _isEditingName = true;
                              });
                            },
                          ),
                        ),
                ],
              ),
            ),

            // Settings Section
            Container(
              margin: EdgeInsets.only(top: screenHeight * 0.01),
              decoration: BoxDecoration(
                color: light80,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsMenuItem(
                      icon: Icons.category_outlined,
                      text: "Manage Categories",
                      iconBackgroundColor: purple20,
                      iconColor: purple100,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CategoryPage()),
                        );
                      },
                    ),
                    SettingsMenuItem(
                      icon: Icons.savings_outlined,
                      text: "Manage Budgets",
                      iconBackgroundColor: purple20,
                      iconColor: purple100,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BudgetPage()),
                        );
                      },
                    ),
                    SettingsMenuItem(
                      icon: Icons.attach_money,
                      text: "Choose Currency",
                      iconBackgroundColor: purple20,
                      iconColor: purple100,
                      onTap: () => _showCurrencyPicker(context),
                      trailingTextBuilder: () =>
                          "$currencyCode $currencySymbol",
                    ),
                    SettingsMenuItem(
                      icon: Icons.feedback_outlined,
                      text: "Feedback",
                      iconBackgroundColor: purple20,
                      iconColor: purple100,
                      onTap: () {
                        FeedbackDialog.showFeedbackDialog(context);
                      },
                    ),
                    SettingsMenuItem(
                      icon: Icons.logout,
                      text: "Logout",
                      iconBackgroundColor: red20,
                      iconColor: red100,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return LogoutPopup(
                              onConfirm: () {
                                Navigator.of(context).pop();
                              },
                              onCancel: () {
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for Profile Menu Item
class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  final String Function()? trailingTextBuilder; // Callback for dynamic text

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.text,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.onTap,
    this.trailingTextBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen size for dynamic adjustment
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.0075), // Dynamic vertical padding
        child: Container(
          padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.008), // Dynamic vertical padding
          decoration: BoxDecoration(
            color: Colors.white, // White background for cards
            borderRadius: BorderRadius.circular(
                screenWidth * 0.03), // Dynamic rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200, // Light shadow
                blurRadius: 6, // Soften edges
                offset: Offset(0, 4), // Vertical shadow
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              height: screenWidth * 0.12, // Dynamic icon size
              width: screenWidth * 0.12, // Dynamic icon size
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: iconColor,
                  size: screenWidth * 0.06), // Dynamic icon size
            ),
            title: Text(
              text,
              style: TextStyle(
                fontSize: screenWidth * 0.045, // Dynamic font size for text
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: trailingTextBuilder != null
                ? Text(
                    trailingTextBuilder!(),
                    style: TextStyle(
                      fontSize: screenWidth *
                          0.04, // Dynamic font size for trailing text
                      color: Colors.grey.shade600,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
