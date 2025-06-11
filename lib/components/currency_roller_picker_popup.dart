import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../logger.dart';
import '../services/currency_service.dart';
import 'custom_button.dart';
import 'custom_divider.dart';

class CurrencyPicker extends StatelessWidget {
  final String selectedCurrencyCode;
  final ValueChanged<String> onCurrencyCodeSelected;

  const CurrencyPicker({
    super.key,
    required this.selectedCurrencyCode,
    required this.onCurrencyCodeSelected,
  });

  Future<List<String>> fetchCurrencyCodes() async {
    try {
      return await CurrencyService.fetchCurrencyCodes();
    } catch (e) {
      logger.e('Failed to fetch available currencies: $e');
      return []; // Return an empty list on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: fetchCurrencyCodes(),
      builder: (context, snapshot) {
        final List<String> defaultCodelist = [
          'EGP',
          'USD',
          'EUR',
        ];

        // Use a default list until data loads
        final List<String> currencyList =
            snapshot.hasData && snapshot.data!.isNotEmpty
                ? snapshot.data!
                : defaultCodelist; // Default currencies

        int initialIndex = currencyList.indexOf(selectedCurrencyCode);
        if (initialIndex == -1) initialIndex = 0;

        // Track the selected currency locally
        String currentSelectedCurrency = currencyList[initialIndex];

        return Container(
          padding: EdgeInsets.all(16),
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomDivider(),
              SizedBox(height: 8),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: initialIndex == -1 ? 0 : initialIndex,
                        ),
                        itemExtent: 32.0,
                        onSelectedItemChanged: (int index) {
                          currentSelectedCurrency = currencyList[index];
                        },
                        children: currencyList
                            .map((currency) => Center(
                                  child: Text(
                                    currency,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                    CustomButton(
                      text: "Confirm",
                      backgroundColor: purple100,
                      textColor: light80,
                      onPressed: () {
                        onCurrencyCodeSelected(currentSelectedCurrency);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
