import 'dart:convert';
import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../../logger.dart';

class ScanReceipts {
  // Extraction related fields
  String extractedText = '';
  String language = '';
  String merchantName = '';
  String receiptDate = '';
  String currency = '';
  String totalPrice = '';

  // Function to resize the image and convert it to Base64
  Future<String?> processImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    // Resize image
    if (image != null) {
      image = img.copyResize(image, width: 640);

      // Convert to JPEG and then to Base64
      final resizedBytes = img.encodeJpg(image);
      final base64Image = base64Encode(resizedBytes);
      logger.i("Base64 Image Length: ${base64Image.length}");
      return base64Image;
    }
    return null;
  }

  Future<String> extractTextWithMlKit(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();
    final result = await textRecognizer.processImage(inputImage);
    textRecognizer.close();

    final List<TextLine> lines = [];

    for (final block in result.blocks) {
      lines.addAll(block.lines);
    }

    // Sort lines: top to bottom, then left to right within a row
    lines.sort((a, b) {
      final dy = (a.boundingBox.top - b.boundingBox.top).abs();
      if (dy < 10) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      } else {
        return a.boundingBox.top.compareTo(b.boundingBox.top);
      }
    });

    final sortedText = lines.map((line) => line.text).join('\n');
    return sortedText;
  }

  void extractMerchantName(String text) {
    // Split the text into individual lines
    List<String> lines = text.split('\n');
    // Keywords or patterns to help identify merchant names
    RegExp merchantRegex = RegExp(
        r'^[A-Za-zäöÄÖ\s,.\-()&*⭑]+$'); // Looks for lines with alphabetic characters
    int minMerchantNameLength = 5;

    // Iterate over each line
    for (String line in lines) {
      // Trim any leading or trailing whitespace from the line
      line = line.trim();
      // Skip lines that are too short to be merchant names
      if (line.length < minMerchantNameLength) continue;

      // Check if the line is not empty after trimming
      if (line.isNotEmpty && merchantRegex.hasMatch(line)) {
        // Set the merchant name to the first non-empty line found
        merchantName = line;
        logger.i('Extracted Merchant Name: $merchantName');
        break; // Exit the loop after finding the first non-empty line
      }
    }

    // If no non-empty line was found, set a default value and log a warning
    if (merchantName.isEmpty) {
      logger.w("Merchant name could not be identified.");
      merchantName = "Not Found";
    }
  }

  String detectLanguage(String text) {
    // Define possible keywords for Finnish and English receipts
    List<String> finnishKeywords = [
      "yhteensä",
      "summa",
      "osto",
      "käteinen",
      "korttiautomaatti",
      "osuuskauppa",
      "kuitti",
      "verollinen"
    ];
    List<String> englishKeywords = [
      "total",
      "amount due",
      "balance",
      "receipt",
      "subtotal",
      "sales tax"
    ];

    // Check if any Finnish keywords are present
    for (var word in finnishKeywords) {
      if (text.toLowerCase().contains(word)) {
        return "Finnish";
      }
    }

    // Check if any English keywords are present
    for (var word in englishKeywords) {
      if (text.toLowerCase().contains(word)) {
        return "English";
      }
    }

    // Return Unknown if no keywords matched
    return "Unknown";
  }

  void findHighestPlausibleTotal(String text) {
    List<String> lines = text.split('\n');
    double highestAmount = 0.0;
    String highestAmountStr = '';
    String detectedCurrency = '';

    // Regex to match amounts with optional currency
    RegExp amountRegex = RegExp(
      r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?|\d+(?:\.\d{2})?)\s*(?:EGP|USD|EUR)?',
      caseSensitive: false,
    );

    // Words that suggest this is not a total amount
    List<String> excludeKeywords = [
      'qty',
      'quantity',
      'unit',
      'price',
      'subtotal',
      'discount',
      'tax',
      'vat',
      '@',
      'x',
      'items',
      'pieces',
      'pcs',
    ];

    for (int i = 0; i < lines.length; i++) {
      String originalLine = lines[i].trim();
      String lowerLine = originalLine.toLowerCase();

      // Skip lines with exclude keywords
      if (excludeKeywords.any((keyword) => lowerLine.contains(keyword))) {
        continue;
      }

      Match? match = amountRegex.firstMatch(originalLine);
      if (match != null) {
        String amountStr = match.group(1)!.trim();
        try {
          double amount = double.parse(amountStr.replaceAll(',', ''));
          // Only consider amounts that are significantly larger
          if (amount > highestAmount && amount > 10) {
            highestAmount = amount;
            highestAmountStr = amountStr;
            if (originalLine.contains('EGP')) {
              detectedCurrency = 'EGP';
            }
            logger.i('Found potential total amount: $amount');
          }
        } catch (e) {
          logger.w('Failed to parse amount in fallback: $amountStr');
        }
      }
    }

    if (highestAmount > 0) {
      totalPrice = highestAmountStr;
      currency = detectedCurrency.isNotEmpty ? detectedCurrency : 'EGP';
      logger.i('Fallback found highest amount: $totalPrice $currency');
    }
  }

  void extractTotalAmountAndCurrency(String text) {
    language = detectLanguage(text);
    logger.i('Detected receipt language: $language');

    List<String> lines = text.split('\n');

    // Enhanced regex pattern to handle amounts with currency and commas
    RegExp amountRegex = RegExp(
      r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?|\d+(?:\.\d{2})?)\s*(?:EGP|USD|EUR)?',
      caseSensitive: false,
    );

    List<String> totalKeywords;
    String assumedCurrency;

    if (language == 'Finnish') {
      totalKeywords = ['yhteensä', 'summa', 'osto'];
      assumedCurrency = 'EUR';
    } else {
      totalKeywords = [
        'total duo',
        'total due',
        'balance due',
        'balance duo',
        'total amount',
        'grand total',
        'total',
        'amount due'
      ];
      assumedCurrency = 'EGP';
    }

    double highestAmount = 0.0;
    String highestAmountStr = '';
    String detectedCurrency = '';

    // Process each line to find the total amount
    for (int i = 0; i < lines.length; i++) {
      String originalLine = lines[i].trim();
      String line = originalLine.toLowerCase();
      logger.i('Processing line: "$originalLine"');

      if (line.contains('subtotal')) {
        logger.i('Skipping subtotal line: "$originalLine"');
        continue;
      }

      bool containsKeyword =
          totalKeywords.any((keyword) => line.contains(keyword));
      if (containsKeyword) {
        logger.i('Found total keyword in line: "$originalLine"');

        Match? match = amountRegex.firstMatch(originalLine);
        if (match != null) {
          String amountStr = match.group(1)!.trim();
          logger.i('Found amount in current line: $amountStr');

          try {
            double amount = double.parse(amountStr.replaceAll(',', ''));
            if (amount > highestAmount) {
              highestAmount = amount;
              highestAmountStr = amountStr;
              if (originalLine.contains('EGP')) {
                detectedCurrency = 'EGP';
              }
              logger.i('Updated highest amount to: $highestAmount');
            }
          } catch (e) {
            logger.w('Failed to parse amount: $amountStr');
          }
        }

        // Check the next few lines
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          String nextLine = lines[j].trim();
          logger.i('Checking next line for amount: "$nextLine"');

          match = amountRegex.firstMatch(nextLine);
          if (match != null) {
            String amountStr = match.group(1)!.trim();
            logger.i('Found amount in next line: $amountStr');

            try {
              double amount = double.parse(amountStr.replaceAll(',', ''));
              if (amount > highestAmount) {
                highestAmount = amount;
                highestAmountStr = amountStr;
                if (nextLine.contains('EGP')) {
                  detectedCurrency = 'EGP';
                }
                logger.i('Updated highest amount to: $highestAmount');
              }
            } catch (e) {
              logger.w('Failed to parse amount: $amountStr');
            }
          }
        }
      }
    }

    if (highestAmount > 0) {
      totalPrice = highestAmountStr;
      currency =
          detectedCurrency.isNotEmpty ? detectedCurrency : assumedCurrency;
      logger
          .i('Final Extracted Total Amount: $totalPrice, Currency: $currency');
    } else {
      logger.w('No total price found with keywords, trying fallback method...');
      findHighestPlausibleTotal(text);
      if (totalPrice == "Not Found") {
        logger.w('No total price found in fallback either');
      }
    }
  }

  void extractDate(String text) {
    RegExp dateRegex = RegExp(
      r'(?<!\d)(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})(?!\d)',
      caseSensitive: false,
    );

    DateTime? closestDate;
    DateTime today = DateTime.now();

    Iterable<Match> dateMatches = dateRegex.allMatches(text);
    if (dateMatches.isEmpty) {
      logger.w('No date pattern matched in the text.');
    }

    for (Match match in dateMatches) {
      String rawDate = match.group(0)!;
      DateTime? parsedDate;
      logger.i('Found potential date string: "$rawDate"');

      try {
        if (rawDate.contains('/') && rawDate.length == 10) {
          parsedDate = DateFormat("dd/MM/yyyy").parse(rawDate);
        } else if (rawDate.contains('.') && rawDate.length >= 8) {
          parsedDate = rawDate.length == 10
              ? DateFormat("d.M.yyyy").parse(rawDate)
              : DateFormat("d.M.yy").parse(rawDate);
        } else if (rawDate.contains('-') && rawDate.length >= 8) {
          if (rawDate.split('-')[0].length == 4) {
            parsedDate = DateFormat("yyyy-M-d").parse(rawDate);
          } else {
            parsedDate = rawDate.length == 10
                ? DateFormat("d-M-yyyy").parse(rawDate)
                : DateFormat("d-M-yy").parse(rawDate);
          }
        } else if (rawDate.contains('/') && rawDate.length == 8) {
          parsedDate = DateFormat("MM/dd/yy").parse(rawDate);
        } else {
          throw FormatException("Unrecognized date format");
        }

        if (parsedDate.isAfter(today)) {
          logger.w('Discarded future date: $parsedDate');
          continue;
        }

        if (closestDate == null ||
            (parsedDate.difference(today).abs() <
                closestDate.difference(today).abs())) {
          closestDate = parsedDate;
        }
      } catch (e) {
        logger.e('Failed to parse date "$rawDate": $e');
      }
    }

    if (closestDate != null) {
      receiptDate = DateFormat('yyyy-MM-dd').format(closestDate);
      logger.i('Extracted Date: $receiptDate');
    } else {
      logger.w('No valid date found');
      receiptDate = "Not Found";
    }
  }

  Future<Map<String, String>> processReceiptImage(File imageFile) async {
    final text = await extractTextWithMlKit(imageFile);
    extractedText = text;

    extractMerchantName(text);
    extractTotalAmountAndCurrency(text);
    extractDate(text);

    return {
      'merchant': merchantName,
      'date': receiptDate,
      'currency': currency,
      'amount': totalPrice,
      'text': extractedText,
    };
  }
}
