import 'package:another_telephony/telephony.dart';
import 'package:intl/intl.dart';
import '../logger.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;
  List<Map<String, dynamic>> credit_card_transactions = [];

  // Function to extract amount from SMS body
  double? extractAmountFromSmsBody(String body) {
    // Regular expression to match transaction amounts in both English and Arabic SMS
    // English format: "for EGP 4,000.00" or "EGP 31,709.87"
    // Arabic format: "تم خصم 678.00EGP" or "678.00EGP"
    final RegExp amountRegex = RegExp(
      r'(?:for\s+EGP\s*|EGP\s+)(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)|(?:\bتم\s+خصم\s+|\bخصم\s+)?(\d+(?:\.\d{2})?)(?:EGP)',
      caseSensitive: false,
    );

    // Try to find all matches in the message
    final matches = amountRegex.allMatches(body);
    if (matches.isNotEmpty) {
      // Get the first match (transaction amount)
      final match = matches.first;
      // Get the amount from either the first or second capture group
      String amountStr =
          (match.group(1) ?? match.group(2) ?? '').replaceAll(',', '');
      try {
        return double.parse(amountStr);
      } catch (e) {
        logger.e('Error parsing amount: $amountStr');
        return null;
      }
    }
    return null;
  }

  Future<void> queryAndPrintSms() async {
    try {
      // List of bank addresses to filter
      final List<String> bankAddresses = [
        "BanK-AlAhly",
        "Baraka bank",
        "QNB ALAHLI",
        "CIB",
        "HSBC",
        "NBK",
        "ADIB",
        "FAB",
        "ADCB",
        "Emirates NBD",
        "RAK Bank",
        "Mashreq",
        "DIB",
        "CBD",
        "ENBD",
        "SABB",
        "Arab Bank",
        "Bank of Alexandria",
        "Commercial International Bank",
        "National Bank of Egypt",
        "Banque Misr",
        "Suez Canal Bank",
        "Al Baraka Bank",
        "Abu Dhabi Islamic Bank",
        "Dubai Islamic Bank",
        "Emirates Islamic",
        "Sharjah Islamic Bank",
        "FAISAL BANK",
        "Al Hilal Bank",
        "Warba Bank",
        "Kuwait Finance House",
        "Al Rajhi Bank",
        "Arab National Bank",
        "Riyad Bank",
        "Saudi Investment Bank",
        "Bank Aljazira",
        "Bank Albilad",
        "Bank Alinma",
        "Saudi Awwal Bank",
        "Arab National Bank",
        "Bank of Jordan",
        "Cairo Amman Bank",
        "Jordan Kuwait Bank",
        "Jordan Islamic Bank",
        "Capital Bank",
        "Invest Bank",
        "Union National Bank",
        "United Arab Bank",
        "Commercial Bank of Dubai",
        "Mashreq Bank",
        "National Bank of Fujairah",
        "United Arab Bank",
        "Bank of Sharjah",
        "Commercial Bank International",
        "National Bank of Umm Al Qaiwain",
        "Bank of Baroda",
        "Bank of India",
        "State Bank of India",
        "ICICI Bank",
        "HDFC Bank",
        "Axis Bank",
        "Kotak Mahindra Bank",
        "Yes Bank",
        "Punjab National Bank",
        "Canara Bank",
        "Bank of Baroda",
        "Union Bank of India",
        "Bank of Maharashtra",
        "Indian Bank",
        "UCO Bank",
        "Punjab & Sind Bank",
        "Central Bank of India",
        "Indian Overseas Bank",
        "Bank of India",
        "State Bank of India",
        "IDBI Bank",
      ];

      logger.i('Fetching SMS messages...');
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
        sortOrder: [
          OrderBy(SmsColumn.DATE, sort: Sort.DESC),
        ],
      );

      logger.i('Found ${messages.length} total messages');

      // Filter messages by bank addresses
      messages = messages.where((sms) {
        final address = sms.address?.toLowerCase() ?? '';
        return bankAddresses
            .any((bank) => address.contains(bank.toLowerCase()));
      }).toList();

      logger.i('Filtered to ${messages.length} bank messages');

      // Clear previous transactions
      credit_card_transactions.clear();

      for (var sms in messages) {
        final date = DateTime.fromMillisecondsSinceEpoch(sms.date ?? 0);
        final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);

        // Extract amount from SMS body
        double? amount = extractAmountFromSmsBody(sms.body ?? '');

        logger.i(
            'Processing message - From: ${sms.address}, Body: ${sms.body}, Date: $formattedDate');

        if (amount != null) {
          credit_card_transactions.add({
            'amount': amount,
            'address': sms.address,
            'date': date,
            'body': sms.body,
          });
          logger.i(
              'Added transaction: ${sms.address} - EGP ${amount.toStringAsFixed(2)}');
        } else {
          logger.w('No amount found in message: ${sms.body}');
        }
      }

      // Log summary of all extracted transactions
      if (credit_card_transactions.isNotEmpty) {
        logger
            .i('Total transactions found: ${credit_card_transactions.length}');
        logger.i(
            'All extracted transactions: ${credit_card_transactions.map((t) => '${t['address']}: EGP ${t['amount'].toStringAsFixed(2)}').join(', ')}');
      } else {
        logger.i('No transaction amounts found in the messages');
      }
    } catch (e) {
      logger.e('Error in queryAndPrintSms: $e');
      rethrow;
    }
  }
}
