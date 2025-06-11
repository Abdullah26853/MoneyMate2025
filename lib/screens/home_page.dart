import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:receipt_manager/providers/category_provider.dart';
import 'package:receipt_manager/screens/summary_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:receipt_manager/components/expense_item_card.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
//import 'dart:io';
import 'dart:convert';

import '../constants/app_colors.dart';
import '../providers/budget_provider.dart';
import '../providers/receipt_provider.dart';
import '../providers/user_provider.dart';
import '../components/sms_transactions_popup.dart';
import '../services/sms_service.dart';
import 'add_update_receipt_page.dart';
import 'budget_page.dart';
import 'receipt_list_page.dart';
import 'base_page.dart';

class HomePage extends StatefulWidget {
  static const String id = 'home_page';

  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    categoryProvider.loadUserCategories();

    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    budgetProvider.loadUserBudgets();

    // Initial data load
    receiptProvider.fetchAllReceipts();
    receiptProvider.loadReceiptCount();
    receiptProvider.loadOldestAndNewestDates();

    // Calculate total spending for current month
    Future.microtask(() {
      if (mounted) {
        receiptProvider.groupReceiptsByCategoryOneMonth(
            _currentMonth, _currentYear);
        receiptProvider.calculateTotalSpending(
            receiptProvider.groupedReceiptsByCategoryOneMonth ?? {});
      }
    });

    // Fetch user profile
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: light90,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddOrUpdateReceiptPage(),
            ),
          ).then((result) {
            // If the receipt was saved successfully, refresh the UI
            if (result == true) {
              final receiptProvider =
                  Provider.of<ReceiptProvider>(context, listen: false);
              receiptProvider.fetchAllReceipts();
            }
          });
        },
        backgroundColor: Color.fromARGB(255, 221, 235, 157),
        child: Icon(Icons.add, color: Colors.black),
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Static content
            Padding(
              padding: const EdgeInsets.only(bottom: 12.8, top: 6.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserWelcome(),
                  const SizedBox(height: 6),
                  _buildTotalSpending(),
                  const SizedBox(height: 8),
                  _buildActionButtons(context),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            // Scrollable Recent Transactions
            Expanded(
              child: _buildRecentReceipts(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserWelcome() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Padding(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 3, bottom: 3),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      width: 2),
                ),
                child: ClipOval(
                  child: (userProvider.profileImagePath != null &&
                          userProvider.profileImagePath!.isNotEmpty &&
                          userProvider.profileImagePath!.contains(','))
                      ? Image.memory(
                          base64Decode(
                              userProvider.profileImagePath!.split(',')[1]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 30,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    userProvider.userName ?? 'User',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalSpending() {
    return Consumer2<ReceiptProvider, BudgetProvider>(
      builder: (context, receiptProvider, budgetProvider, child) {
        // Get the monthly budget amount directly from the provider
        final monthlyBudget = budgetProvider.monthlyBudget;
        final alertPercentage = budgetProvider.alertPercentage;

        // Calculate left to spend
        final totalSpent = (receiptProvider.groupedReceiptsByCategoryOneMonth ??
                {})
            .values
            .fold(0.0,
                (sum, category) => sum + (category['total'] as double? ?? 0.0));
        final leftToSpend = monthlyBudget - totalSpent;

        // Calculate percentage spent
        final percentageSpent =
            monthlyBudget > 0 ? (totalSpent / monthlyBudget) * 100 : 0;
        final isAlertThresholdReached = percentageSpent >= alertPercentage;

        // Force a rebuild when budget changes
        budgetProvider.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Budget Alert Banner
              if (isAlertThresholdReached)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have reached ${percentageSpent.toStringAsFixed(1)}% of your monthly budget!',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Total Spent Section
              Column(
                children: [
                  Text(
                    'Total Spent ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C2646),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'EGP ',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2646),
                          fontFamily: 'Inter',
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            NumberFormat('#,###').format(totalSpent.toInt()),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2646),
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            '.${((totalSpent - totalSpent.toInt()) * 100).round().toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 25.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2646),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Budget Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left to spend
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Left to spend',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'EGP ${leftToSpend < 0 ? '-' : ''}${NumberFormat('#,###').format(leftToSpend.abs().toInt())}.${((leftToSpend.abs() - leftToSpend.abs().toInt()) * 100).round().toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: leftToSpend < 0
                                  ? Colors.red.shade700
                                  : Color(0xFF2C2646),
                            ),
                          ),
                        ],
                      ),
                      // Monthly budget
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Monthly budget',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'EGP ${NumberFormat('#,###').format(monthlyBudget.toInt())}.${((monthlyBudget - monthlyBudget.toInt()) * 100).round().toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2646),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color iconColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          children: [
            Container(
              width: 53,
              height: 53,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 202, 224, 105).withOpacity(0.55),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6.4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Scan',
            iconColor: Colors.blue,
            onPressed: _openCamera,
          ),
          const SizedBox(width: 5),
          _buildActionButton(
            icon: Icons.sms_outlined,
            label: 'Check SMS',
            iconColor: purple100,
            onPressed: () async {
              final smsService = SmsService();
              try {
                bool? permissionsGranted =
                    await smsService.telephony.requestPhoneAndSmsPermissions;
                if (permissionsGranted != true) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'SMS permission denied. Please grant permission in settings.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                await smsService.queryAndPrintSms();
                if (mounted) {
                  if (smsService.credit_card_transactions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No transactions found in SMS'),
                      ),
                    );
                  } else {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (BuildContext context) {
                        return SmsTransactionsPopup(
                          smsService: smsService,
                        );
                      },
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error checking SMS: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 6.4),
          _buildActionButton(
            icon: Icons.account_balance_wallet,
            label: 'Budget',
            iconColor: Colors.green,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BudgetPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 6.4),
          _buildActionButton(
            icon: Icons.bolt,
            label: 'Quick Add',
            iconColor: Colors.amber[700]!,
            onPressed: () {
              _showQuickAddOptions(context);
            },
          ),
          const SizedBox(width: 6.4),
          _buildActionButton(
            icon: Icons.analytics,
            label: 'Summary',
            iconColor: Colors.purple,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SummaryPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReceipts() {
    return Consumer<ReceiptProvider>(
      builder: (context, receiptProvider, _) {
        // Create a new list to avoid modifying the original
        final recentReceipts =
            List<Map<String, dynamic>>.from(receiptProvider.allReceipts);

        // Sort by timestamp in descending order (newest first)
        recentReceipts.sort((a, b) {
          final timestampA = a['date'] as Timestamp;
          final timestampB = b['date'] as Timestamp;

          // Compare seconds first (higher value means newer)
          if (timestampB.seconds != timestampA.seconds) {
            return timestampB.seconds.compareTo(timestampA.seconds);
          }

          // If seconds are equal, compare nanoseconds
          return timestampB.nanoseconds.compareTo(timestampA.nanoseconds);
        });

        final limitedReceipts = recentReceipts.take(10).toList();

        if (limitedReceipts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No receipts yet!',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Add your first receipt to get started.',
                  style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReceiptListPage(),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: limitedReceipts
                        .map((receipt) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.4),
                              child: ExpenseItem(
                                categoryIcon:
                                    receipt['categoryIcon'] ?? Icons.category,
                                categoryName: receipt['categoryName'] ??
                                    'Unknown Category',
                                categoryColor: receipt['categoryColor'] ??
                                    Colors.grey.shade200,
                                merchantName:
                                    receipt['merchant'] ?? 'Unknown Merchant',
                                receiptDate: receipt['date'] != null
                                    ? DateFormat('MMM d, yyyy').format(
                                        (receipt['date'] as Timestamp).toDate())
                                    : 'Unknown',
                                currencySymbol:
                                    receiptProvider.currencySymbolToDisplay ??
                                        'EGP',
                                amount: receipt['amountToDisplay']
                                    .toStringAsFixed(2),
                                paymentMethod: receipt['paymentMethod'] ??
                                    'Unknown Payment Method',
                                itemName:
                                    receipt['itemName'] ?? receipt['merchant'],
                                receiptId: receipt['id'],
                                isQuickAdd: receipt['isQuickAdd'] ?? false,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddOrUpdateReceiptPage(
                                        existingReceipt: receipt,
                                        receiptId: receipt['id'],
                                      ),
                                    ),
                                  ).then((_) {
                                    receiptProvider.fetchAllReceipts();
                                  });
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to directly open the camera
  Future<void> _openCamera() async {
    try {
      PermissionStatus cameraStatus = await Permission.camera.request();

      if (cameraStatus.isGranted) {
        try {
          final pickedFile = await _picker.pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.rear,
          );

          if (pickedFile != null && mounted) {
            // Process the image and extract data
            //File imageFile = File(pickedFile.path);

            // Navigate directly to AddOrUpdateReceiptPage with the image
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddOrUpdateReceiptPage(
                  extract: {
                    'imagePath': pickedFile.path,
                    'isDirectScan': true, // Flag to indicate direct scan
                  },
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error accessing camera: $e")),
            );
          }
        }
      } else if (cameraStatus.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Camera permission denied. Please grant permission in settings."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (cameraStatus.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Camera permission permanently denied. Please enable it in settings."),
              backgroundColor: Colors.red,
            ),
          );
          // Open app settings
          await openAppSettings();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error requesting camera permission: $e")),
        );
      }
    }
  }

  // Function to show quick add options
  void _showQuickAddOptions(BuildContext context) async {
    try {
      final receiptProvider =
          Provider.of<ReceiptProvider>(context, listen: false);

      // Ensure we have the latest data
      await receiptProvider.fetchAllReceipts();

      // Filter receipts marked for quick add
      final allQuickAddReceipts = receiptProvider.allReceipts
          .where((receipt) => receipt['isQuickAdd'] == true)
          .toList();

      if (allQuickAddReceipts.isEmpty) {
        // Show message if no quick add receipts are available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No quick add transactions available. Mark transactions as quick add first.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Group transactions by merchant and item name to find duplicates
      final Map<String, Map<String, dynamic>> uniqueTransactions = {};

      // Sort by date first (newest first) to ensure we keep the most recent
      allQuickAddReceipts.sort((a, b) {
        final dateA = (a['date'] as Timestamp).toDate();
        final dateB = (b['date'] as Timestamp).toDate();
        return dateB.compareTo(dateA);
      });

      // Create a unique key for each transaction type and keep only the most recent
      for (var receipt in allQuickAddReceipts) {
        // Create a unique key combining merchant and item name (if available)
        final String merchantName = receipt['merchant'] ?? 'Unknown';
        final String itemName = receipt['itemName'] ?? merchantName;
        final String categoryId = receipt['categoryId'] ?? 'unknown';
        final double amount = receipt['amount'] ?? 0.0;

        // Create a unique identifier for this transaction type
        final String uniqueKey = '$merchantName-$itemName-$categoryId-$amount';

        // Only add if we haven't seen this transaction type before
        // Since we sorted by date, the first one we encounter is the most recent
        if (!uniqueTransactions.containsKey(uniqueKey)) {
          uniqueTransactions[uniqueKey] = receipt;
        }
      }

      // Convert back to a list for display
      final quickAddReceipts = uniqueTransactions.values.toList();

      // Show bottom sheet with quick add options
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Quick Add Transaction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(),
                Text(
                  'Select a transaction to quickly add with today\'s date:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: quickAddReceipts.length,
                    itemBuilder: (context, index) {
                      final receipt = quickAddReceipts[index];
                      return ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: receipt['categoryColor'] ?? Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: receipt['categoryIcon'] is IconData
                              ? Icon(receipt['categoryIcon'], size: 20)
                              : Text(receipt['categoryIcon']?.toString() ?? '❓',
                                  style: TextStyle(fontSize: 20)),
                        ),
                        title: Text(receipt['itemName'] ??
                            receipt['merchant'] ??
                            'Unknown'),
                        subtitle: Text(
                            '${receipt['amountToDisplay'].toStringAsFixed(2)} EGP'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () =>
                                  _removeFromQuickAdd(context, receipt['id']),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () =>
                                  _handleQuickAdd(context, receipt['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error in _showQuickAddOptions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle quick add transaction
  Future<void> _handleQuickAdd(BuildContext context, String receiptId) async {
    try {
      // Close the bottom sheet
      Navigator.pop(context);

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(width: 16),
              Text('Adding transaction...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final receiptProvider =
          Provider.of<ReceiptProvider>(context, listen: false);

      // Add the transaction
      await receiptProvider.quickAddReceipt(receiptId: receiptId);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Force a complete UI refresh by navigating to BasePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BasePage(),
          ),
        );
      }
    } catch (e) {
      print('Error in _handleQuickAdd: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add transaction. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this new method to handle removing from quick add
  Future<void> _removeFromQuickAdd(
      BuildContext context, String receiptId) async {
    try {
      // Close the bottom sheet
      Navigator.pop(context);

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(width: 16),
              Text('Removing from favorites...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final receiptProvider =
          Provider.of<ReceiptProvider>(context, listen: false);

      // Remove from quick add
      await receiptProvider.removeFromQuickAdd(receiptId: receiptId);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from favorites successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Force a complete UI refresh by navigating to BasePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BasePage(),
          ),
        );
      }
    } catch (e) {
      print('Error in _removeFromQuickAdd: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from favorites. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
