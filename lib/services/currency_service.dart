import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;

import '../logger.dart';

class CurrencyService {
  Map<String, double>? conversionRates;
  DateTime? _lastFetched; // To track when rates were last fetched
  static const Duration _cacheDuration = Duration(hours: 1); // Cache for 1 hour

  // Getter for cache duration
  Duration get cacheDuration => _cacheDuration;

  // Method to get the API key from Firebase Remote Config
  static Future<String> getApiKey() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    // Set default values for Remote Config
    await remoteConfig.setDefaults(<String, dynamic>{
      'API_KEY': 'default_api_key', // Provide a fallback API key or message
    });

    // Fetch the latest values from Firebase Remote Config
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      logger.e('Failed to fetch remote config: $e');
    }

    // Retrieve the API key from the Remote Config
    String apiKey = remoteConfig.getString('API_KEY');
    if (apiKey == 'default_api_key' || apiKey.isEmpty) {
      throw Exception('API key is not set in Remote Config');
    }

    return apiKey;
  }

  // Fetch the currency codes as a list
  static Future<List<String>> fetchCurrencyCodes() async {
    final String apiKey = await getApiKey();
    const String apiUrl = 'https://openexchangerates.org/api/currencies.json';

    try {
      final response = await http.get(Uri.parse('$apiUrl?app_id=$apiKey'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> currencies = json.decode(response.body);
        return currencies.keys.toList(); // Return the list of currency codes
      } else {
        throw Exception('Failed to load currency codes');
      }
    } catch (e) {
      throw Exception('Error fetching currency codes: $e');
    }
  }

  // Fetch conversion rates using the API key from Remote Config
  Future<void> fetchConversionRates() async {
    if (conversionRates != null &&
        _lastFetched != null &&
        DateTime.now().difference(_lastFetched!) < _cacheDuration) {
      logger.i('Using cached conversion rates.');
      return;
    }

    final String apiKey = await getApiKey();
    const String apiUrl = 'https://openexchangerates.org/api/latest.json';

    try {
      final response = await http.get(Uri.parse('$apiUrl?app_id=$apiKey'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> rates = data['rates'];

        // Convert rates to a Map<String, double>
        conversionRates = rates.map((key, value) {
          if (value is int) {
            return MapEntry(key, value.toDouble());
          } else if (value is double) {
            return MapEntry(key, value);
          } else {
            throw Exception("Unexpected type for rate value");
          }
        });

        _lastFetched = DateTime.now();
        logger.i('Fetched and cached new conversion rates.');
      } else {
        throw Exception('Failed to load conversion rates');
      }
    } catch (e) {
      logger.e('Error fetching conversion rates: $e');
      conversionRates = {}; // Clear cached rates on error
    }
  }

  // Method to convert an amount directly from baseCurrency to targetCurrency
  Future<double> convertCurrency(
      double amount, String baseCurrency, String targetCurrency) async {
    // Ensure conversion rates are fetched
    await fetchConversionRates();

    // If the base and target currencies are the same, return the amount as is
    if (baseCurrency == targetCurrency) {
      return amount;
    }

    // Get the exchange rates for the base and target currencies
    double rateBase =
        conversionRates![baseCurrency] ?? 1.0; // Default to 1.0 if not found
    double rateTarget =
        conversionRates![targetCurrency] ?? 1.0; // Default to 1.0 if not found

    // Direct conversion using the formula x * a = y * b
    return amount * (rateTarget / rateBase);
  }
}
