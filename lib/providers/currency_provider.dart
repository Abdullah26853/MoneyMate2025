import 'package:flutter/material.dart';

import '../logger.dart';
import '../services/currency_service.dart';

class CurrencyProvider with ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService();

  Map<String, double>? _conversionRates;
  DateTime? _lastFetched;
  String _baseCurrency = 'USD';
  bool _isLoading = false;

  Map<String, double>? get conversionRates => _conversionRates;
  String get baseCurrency => _baseCurrency;
  bool get isLoading => _isLoading;

  // Fetch conversion rates and cache them
  Future<void> fetchConversionRates() async {
    if (_isLoading) return; // Avoid duplicate calls
    _isLoading = true;
    notifyListeners();

    try {
      await _currencyService.fetchConversionRates();
      _conversionRates = _currencyService.conversionRates;
      _lastFetched = DateTime.now();
    } catch (e) {
      logger.e('Error fetching conversion rates: $e');
      _conversionRates = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert an amount from one currency to another
  Future<double> convertCurrency(
      double amount, String fromCurrency, String toCurrency) async {
    if (_conversionRates == null) {
      await fetchConversionRates(); // Ensure rates are fetched
    }

    return _currencyService.convertCurrency(amount, fromCurrency, toCurrency);
  }

  // Update the base currency
  void setBaseCurrency(String currencyCode) {
    _baseCurrency = currencyCode;
    notifyListeners();
  }

  // Get the symbol of a currency
  Future<String> getCurrencySymbol(String currencyCode) {
    return CurrencyService
        .getApiKey(); // Or use a similar method to get the symbol
  }

  // Check if rates are cached and valid
  bool areRatesCachedAndValid() {
    return _conversionRates != null &&
        _lastFetched != null &&
        DateTime.now().difference(_lastFetched!) <
            _currencyService.cacheDuration;
  }
}
