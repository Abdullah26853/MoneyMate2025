import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/receipt_provider.dart';
import '../providers/category_provider.dart';
import '../services/sms_service.dart';
import '../constants/app_colors.dart';
import '../screens/base_page.dart';
//import 'custom_button.dart';
import 'custom_divider.dart';

class SmsTransactionsPopup extends StatelessWidget {
  final SmsService smsService;

  const SmsTransactionsPopup({
    required this.smsService,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'SMS Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'Select a transaction to add:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: smsService.credit_card_transactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No transactions found in SMS',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: smsService.credit_card_transactions.length,
                    itemBuilder: (context, index) {
                      final transaction =
                          smsService.credit_card_transactions[index];
                      final date = transaction['date'] as DateTime;
                      final formattedDate =
                          DateFormat('MMM dd, yyyy hh:mm a').format(date);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: purple20,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.credit_card,
                                  size: 20, color: purple100),
                            ),
                            title: Text(
                              transaction['address'] ?? 'Unknown Bank',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EGP ${transaction['amount'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  transaction['body'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing:
                                Icon(Icons.add_circle, color: Colors.green),
                            onTap: () =>
                                _handleAddTransaction(context, transaction),
                          ),
                          if (index <
                              smsService.credit_card_transactions.length - 1)
                            Divider(height: 1),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddTransaction(
      BuildContext context, Map<String, dynamic> transaction) async {
    try {
      // Close the popup
      Navigator.pop(context);

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(width: 16),
              Text('Adding transaction...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final receiptProvider =
          Provider.of<ReceiptProvider>(context, listen: false);
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);

      // Ensure categories are loaded
      await categoryProvider.loadUserCategories();

      // Find the Credit Card category
      final creditCardCategory = categoryProvider.categories.firstWhere(
        (category) => category['name'] == 'Credit Card',
        orElse: () => {
          'id': 'credit_card',
          'name': 'Credit Card',
          'icon': 'credit_card',
          'color': 0xFF42A5F5, // Use integer value for color
        },
      );

      print('Found credit card category: $creditCardCategory'); // Debug log

      // Create receipt data with the found category
      Map<String, dynamic> receiptData = {
        'merchant': transaction['address'],
        'itemName': transaction['address'],
        'amount': transaction['amount'],
        'date': transaction['date'],
        'paymentMethod': 'Credit Card',
        'categoryId': creditCardCategory['id'],
        'categoryName': creditCardCategory['name'],
        'categoryIcon': creditCardCategory['icon'],
        'categoryColor': creditCardCategory['color'] is Color
            ? (creditCardCategory['color'] as Color).value
            : creditCardCategory['color'],
        'currencyCode': 'EGP',
      };

      print('Attempting to add receipt with data: $receiptData'); // Debug log

      // Add the receipt
      await receiptProvider.addReceipt(receiptData: receiptData);

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
    } catch (e, stackTrace) {
      print('Error in _handleAddTransaction: $e');
      print('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
