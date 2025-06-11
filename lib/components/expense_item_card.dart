import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/receipt_provider.dart';

class ExpenseItem extends StatelessWidget {
  final dynamic categoryIcon; // Use dynamic to accept both String and IconData
  final String categoryName;
  final Color categoryColor;
  final String merchantName;
  final String receiptDate;
  final String currencySymbol; // Still keeping this parameter for compatibility
  final String amount;
  final String paymentMethod;
  final VoidCallback onTap;
  final String? itemName; // Add itemName parameter
  final String receiptId; // Add receiptId parameter
  final bool isQuickAdd; // Add isQuickAdd parameter

  const ExpenseItem({
    super.key,
    required this.categoryIcon,
    required this.categoryName,
    required this.categoryColor,
    required this.merchantName,
    required this.receiptDate,
    required this.currencySymbol,
    required this.amount,
    required this.paymentMethod,
    required this.onTap,
    required this.receiptId,
    this.itemName, // Make it optional
    this.isQuickAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Trigger onTap when the item is tapped
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFD9EAFD),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3), // Shadow position
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: categoryColor, // Background color for the icon
                borderRadius: BorderRadius.circular(10),
              ),
              child: categoryIcon is IconData
                  ? Icon(categoryIcon,
                      size: 22.0, // Slightly smaller icon
                      color: Colors.black)
                  : Text(
                      categoryIcon.toString(), // Display as Text if String
                      style: const TextStyle(fontSize: 22.0),
                    ),
            ),
            const SizedBox(width: 12),
            // Title and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          itemName ??
                              merchantName, // Show item name if available, otherwise merchant name
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        receiptDate,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (isQuickAdd)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Icon(
                            Icons.bolt,
                            size: 15.4,
                            color: Colors.amber[700],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount with static EGP text
            Row(
              children: [
                Text(
                  '-' + amount,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'Inter',
                  ),
                ),
                const Text(
                  ' EGP',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            // Quick Add toggle
            IconButton(
              icon: Icon(
                isQuickAdd ? Icons.star : Icons.star_border,
                color: isQuickAdd ? Colors.amber : Colors.grey,
                size: 20,
              ),
              onPressed: () async {
                // Show loading indicator in place of the star icon
                final receiptProvider =
                    Provider.of<ReceiptProvider>(context, listen: false);

                // Use ScaffoldMessenger to show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isQuickAdd
                        ? 'Removing from Quick Add...'
                        : 'Adding to Quick Add...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                // Mark receipt as quick add
                await receiptProvider.markAsQuickAdd(
                  receiptId: receiptId,
                  isQuickAdd: !isQuickAdd,
                );
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
      ),
    );
  }
}
