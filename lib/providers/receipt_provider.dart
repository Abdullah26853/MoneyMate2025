import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipt_manager/providers/user_provider.dart';
import 'package:provider/provider.dart';

import '../logger.dart';
import '../services/receipt_service.dart';
import 'authentication_provider.dart';
import 'category_provider.dart';
import 'currency_provider.dart';
import 'budget_provider.dart';
import '../models/category_score.dart';

// Global navigator key for showing snackbars
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

enum TimeInterval { day, week, month, year }

enum ChartType { pie, bar, line }

class ReceiptProvider extends ChangeNotifier {
  // Services and Providers
  final ReceiptService _receiptService = ReceiptService();
  AuthenticationProvider? _authProvider;
  UserProvider? _userProvider;
  CategoryProvider? _categoryProvider;
  CurrencyProvider? _currencyProvider;

  String? _currencySymbolToDisplay;
  // Date Range default as current year
  DateTime? _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime? _endDate = DateTime.now();
  // Sorting and Filtering Options
  String _sortOption = "Newest";
  List<String> _selectedPaymentMethods = [
    'Credit Card',
    'Debit Card',
    'Cash',
    'Others'
  ];
  List<String> _selectedCategoryIds = [];

  String? get currencySymbolToDisplay => _currencySymbolToDisplay;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get sortOption => _sortOption;
  List<String> get selectedPaymentMethods => _selectedPaymentMethods;
  List<String> get selectedCategoryIds => _selectedCategoryIds;

  // Receipts Data
  List<Map<String, dynamic>> _allReceipts = [];
  List<Map<String, dynamic>> _filteredReceipts = [];
  int? _receiptCount;
  DateTime? _oldestDate;
  DateTime? _newestDate;

  List<Map<String, dynamic>> get allReceipts => _allReceipts;
  List<Map<String, dynamic>> get filteredReceipts => _filteredReceipts;
  int? get receiptCount => _receiptCount;
  DateTime? get oldestDate => _oldestDate;
  DateTime? get newestDate => _newestDate;

  ChartType currentChartType = ChartType.pie;

  // Grouped Receipts
  Map<String, Map<String, dynamic>>? _groupedReceiptsByCategory;
  Map<String, Map<String, dynamic>>? _groupedReceiptsByInterval;
  Map<String, Map<String, dynamic>>? _groupedReceiptsByCategoryOneMonth;
  Map<String, Map<String, dynamic>>? _groupedReceiptsByMonthAndCategory;

  Map<String, Map<String, dynamic>>? get groupedReceiptsByCategory =>
      _groupedReceiptsByCategory;
  Map<String, Map<String, dynamic>>? get groupedReceiptsByInterval =>
      _groupedReceiptsByInterval;
  Map<String, Map<String, dynamic>>? get groupedReceiptsByCategoryOneMonth =>
      _groupedReceiptsByCategoryOneMonth;
  Map<String, Map<String, dynamic>>? get groupedReceiptsByMonthAndCategory =>
      _groupedReceiptsByMonthAndCategory;

  // Spending and Currency
  double _totalSpending = 0.0;

  double get totalSpending => _totalSpending;

  // Time Interval
  TimeInterval _selectedInterval = TimeInterval.month;
  TimeInterval get selectedInterval => _selectedInterval;

  // User Email
  String? get _userEmail => _authProvider?.user?.email;

  // Inject AuthenticationProvider and CategoryProvider
  set authProvider(AuthenticationProvider authProvider) {
    _authProvider = authProvider;
    notifyListeners();
  }

  set userProvider(UserProvider userProvider) {
    _userProvider = userProvider;
    notifyListeners();
  }

  set categoryProvider(CategoryProvider categoryProvider) {
    _categoryProvider = categoryProvider;

    // Generate _selectedCategoryIds from the current categories in the provider
    final allCategoryIds = _categoryProvider!.categories
        .map((cat) => cat['id'] as String)
        .toList();

    // Add "null" for uncategorized items if not already present
    if (!allCategoryIds.contains('null')) {
      allCategoryIds.add('null');
    }

    // Assign to _selectedCategoryIds
    if (_selectedCategoryIds.isEmpty) {
      // If this is the first initialization, use all available categories
      _selectedCategoryIds = allCategoryIds;
    } else {
      // Otherwise, retain only those IDs that still exist in the updated categories
      _selectedCategoryIds = _selectedCategoryIds
          .where((id) => allCategoryIds.contains(id))
          .toList();
    }

    // Notify listeners to rebuild dependent widgets
    notifyListeners();
  }

  set currencyProvider(CurrencyProvider currencyProvider) {
    _currencyProvider = currencyProvider;
    notifyListeners();
  }

// Fetch all receipts
  Future<void> fetchAllReceipts() async {
    logger.i("fetchAllReceipts called");
    if (_categoryProvider != null) {
      await _categoryProvider!.loadUserCategories();
    }

    final userCurrencyCode =
        _userProvider?.userProfile?.data()?['currencyCode'];
    // Get the currency symbol using intl
    _currencySymbolToDisplay =
        NumberFormat.simpleCurrency(name: userCurrencyCode).currencySymbol;

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('receipts').doc(_userEmail);

      final snapshot = await userDoc.get();
      logger.i('Fetched Snapshot Data: ${snapshot.data()}');

      if (snapshot.data() == null) {
        logger.w('No receipts found.');
        _allReceipts = [];
        notifyListeners();
        return;
      }

      // Update _allReceipts and enrich with category data
      _allReceipts =
          (snapshot.data()?['receiptlist'] ?? []).cast<Map<String, dynamic>>();

      _allReceipts = _allReceipts.map((receipt) {
        final category = _categoryProvider?.categories.firstWhere(
          (cat) => cat['id'] == receipt['categoryId'],
          orElse: () => {'name': 'Unknown', 'icon': '❓'},
        );

        final rates = {
          "AED": 3.672993,
          "AFN": 67.750012,
          "ALL": 92.919261,
          "AMD": 386.478229,
          "ANG": 1.794078,
          "AOA": 911.660667,
          "ARS": 998.532296,
          "AUD": 1.536803,
          "AWG": 1.7975,
          "AZN": 1.7,
          "BAM": 1.84675,
          "BBD": 2,
          "BDT": 118.955666,
          "BGN": 1.84601,
          "BHD": 0.376922,
          "BIF": 2922.909691,
          "BMD": 1,
          "BND": 1.338288,
          "BOB": 6.878806,
          "BRL": 5.7479,
          "BSD": 1,
          "BTC": 0.00001095826,
          "BTN": 84.001401,
          "BWP": 13.581168,
          "BYN": 3.25729,
          "BZD": 2.00661,
          "CAD": 1.40189,
          "CDF": 2870,
          "CHF": 0.883407,
          "CLF": 0.035257,
          "CLP": 972.059515,
          "CNH": 7.229197,
          "CNY": 7.2367,
          "COP": 4406.373693,
          "CRC": 506.968701,
          "CUC": 1,
          "CUP": 25.75,
          "CVE": 104.290134,
          "CZK": 23.86715,
          "DJF": 177.316787,
          "DKK": 7.037833,
          "DOP": 60.207315,
          "DZD": 133.398467,
          "EGP": 49.4457,
          "ERN": 15,
          "ETB": 122.736291,
          "EUR": 0.943515,
          "FJD": 2.26815,
          "FKP": 0.788653,
          "GBP": 0.788653,
          "GEL": 2.735,
          "GGP": 0.788653,
          "GHS": 15.910462,
          "GIP": 0.788653,
          "GMD": 71,
          "GNF": 8599.414674,
          "GTQ": 7.690855,
          "GYD": 208.262166,
          "HKD": 7.78375,
          "HNL": 25.129083,
          "HRK": 7.116363,
          "HTG": 130.769368,
          "HUF": 383.6715,
          "IDR": 15845.176485,
          "ILS": 3.73932,
          "IMP": 0.788653,
          "INR": 84.403749,
          "IQD": 1310.5,
          "IRR": 42092.5,
          "ISK": 136.34,
          "JEP": 0.788653,
          "JMD": 157.99216,
          "JOD": 0.7091,
          "JPY": 154.647,
          "KES": 129.162936,
          "KGS": 86.5,
          "KHR": 4033.893966,
          "KMF": 464.75016,
          "KPW": 900,
          "KRW": 1391.912542,
          "KWD": 0.307486,
          "KYD": 0.829525,
          "KZT": 496.694873,
          "LAK": 21950,
          "LBP": 89600,
          "LKR": 290.02681,
          "LRD": 182.672335,
          "LSL": 18.085,
          "LYD": 4.871281,
          "MAD": 10.002,
          "MDL": 18.103695,
          "MGA": 4657.960896,
          "MKD": 58.059012,
          "MMK": 2098,
          "MNT": 3398,
          "MOP": 7.982058,
          "MRU": 39.925,
          "MUR": 47.045,
          "MVR": 15.455,
          "MWK": 1735,
          "MXN": 20.2116,
          "MYR": 4.4705,
          "MZN": 63.924991,
          "NAD": 18.085,
          "NGN": 1662.683481,
          "NIO": 36.688175,
          "NOK": 11.008475,
          "NPR": 134.397176,
          "NZD": 1.697451,
          "OMR": 0.38498,
          "PAB": 1,
          "PEN": 3.795,
          "PGK": 4.00457,
          "PHP": 58.644994,
          "PKR": 277.8,
          "PLN": 4.076623,
          "PYG": 7759.250026,
          "QAR": 3.6405,
          "RON": 4.6956,
          "RSD": 110.381,
          "RUB": 99.750629,
          "RWF": 1370,
          "SAR": 3.753934,
          "SBD": 8.390419,
          "SCR": 14.014926,
          "SDG": 601.5,
          "SEK": 10.91669,
          "SGD": 1.339345,
          "SHP": 0.788653,
          "SLL": 20969.5,
          "SOS": 571,
          "SRD": 35.405,
          "SSP": 130.26,
          "STD": 22281.8,
          "STN": 23.134159,
          "SVC": 8.710719,
          "SYP": 2512.53,
          "SZL": 18.085,
          "THB": 34.636903,
          "TJS": 10.592163,
          "TMT": 3.505,
          "TND": 3.16,
          "TOP": 2.39966,
          "TRY": 34.584861,
          "TTD": 6.758007,
          "TWD": 32.470801,
          "TZS": 2650.381657,
          "UAH": 41.227244,
          "UGX": 3655.17998,
          "USD": 1,
          "UYU": 42.924219,
          "UZS": 12786.647399,
          "VES": 45.733164,
          "VND": 25416.193807,
          "VUV": 118.722,
          "WST": 2.8,
          "XAF": 618.905212,
          "XAG": 0.03208503,
          "XAU": 0.00038287,
          "XCD": 2.70255,
          "XDR": 0.75729,
          "XOF": 618.905212,
          "XPD": 0.0009963,
          "XPF": 112.591278,
          "XPT": 0.00103494,
          "YER": 249.850133,
          "ZAR": 17.94915,
          "ZMW": 27.451369,
          "ZWL": 322
        };

        // Calculate the converted amount
        final baseCurrency = receipt['currencyCode'];
        final amount = receipt['amount'] as double? ?? 0.0;

        double amountToDisplay = amount; // Default is the same amount
        if (rates.containsKey(baseCurrency) &&
            rates.containsKey(userCurrencyCode)) {
          logger.i(rates[baseCurrency]);
          logger.i(rates[userCurrencyCode]);
          final rate = rates[baseCurrency]! / rates[userCurrencyCode]!;
          amountToDisplay = amount / rate;
        } else {
          logger
              .w("Currency code not found: $baseCurrency or $userCurrencyCode");
        }

        return {
          ...receipt,
          'categoryName': category?['name'],
          'categoryIcon': category?['icon'],
          'categoryColor': category?['color'],
          'amountToDisplay': amountToDisplay,
        };
      }).toList();

      // Debug log: print mapping of receipts to category names
      for (final r in _allReceipts) {
        logger.i(
            'Receipt ID: \'${r['id']}\', categoryId: \'${r['categoryId']}\', categoryName: \'${r['categoryName']}\'');
      }

      logger.i(
          "Receipts fetched and enriched (${_allReceipts.length}): $_allReceipts");

      // Sort receipts by date (newest first)
      _allReceipts.sort((a, b) {
        final dateA = (a['date'] as Timestamp).toDate();
        final dateB = (b['date'] as Timestamp).toDate();
        return dateB.compareTo(dateA);
      });

      // Notify listeners
      notifyListeners();
    } catch (e) {
      logger.e("Error fetching receipts: $e");
    }
  }

  void setChartType(ChartType type) {
    currentChartType = type;
    applyFilters(); // Ensure grouping matches the new chart type
  }

  void applyFilters() {
    logger.i("applyFilters called");

    const primaryMethods = ['Credit Card', 'Debit Card', 'Cash'];
    logger.i(
        "Applying filters on Receipts (${_allReceipts.length}): $_allReceipts");

    // If category or payment method filters are empty, return an empty list
    if (_selectedCategoryIds.isEmpty || _selectedPaymentMethods.isEmpty) {
      _filteredReceipts = [];
      _clearGroupedData(); // Clear all grouped data
      notifyListeners();
      return;
    }

    // Apply filtering logic
    _filteredReceipts = _allReceipts.where((receipt) {
      final categoryId = receipt['categoryId'];
      final paymentMethod = receipt['paymentMethod'] ?? 'unknown';
      final date = (receipt['date'] as Timestamp?)?.toDate() ?? DateTime(2000);

      // Match categories
      final matchesCategory = _selectedCategoryIds.isEmpty ||
          _selectedCategoryIds.contains(categoryId) ||
          (categoryId == null && _selectedCategoryIds.contains('null'));

      // Match payment methods
      final matchesPaymentMethod = _selectedPaymentMethods.isEmpty ||
          _selectedPaymentMethods.contains(paymentMethod) ||
          (_selectedPaymentMethods.contains('Others') &&
              !primaryMethods.contains(paymentMethod));

      // Match date range
      final matchesDate = (_startDate == null || !date.isBefore(_startDate!)) &&
          (_endDate == null || !date.isAfter(_endDate!));

      logger.i(
          "Receipt: $receipt, Matches - Category: $matchesCategory, Payment: $matchesPaymentMethod, Date: $matchesDate");

      return matchesCategory && matchesPaymentMethod && matchesDate;
    }).toList();

    // Sort the filtered receipts
    _filteredReceipts.sort((a, b) {
      final dateA = (a['date'] as Timestamp).toDate();
      final dateB = (b['date'] as Timestamp).toDate();
      final amountA = (a['amountToDisplay'] as num?)?.toDouble() ?? 0.0;
      final amountB = (b['amountToDisplay'] as num?)?.toDouble() ?? 0.0;

      if (_sortOption == 'Newest') return dateB.compareTo(dateA);
      if (_sortOption == 'Oldest') return dateA.compareTo(dateB);
      if (_sortOption == 'Highest') return amountB.compareTo(amountA);
      if (_sortOption == 'Lowest') return amountA.compareTo(amountB);
      return 0;
    });

    logger.i(
        "Filtered and Sorted Receipts (${_filteredReceipts.length}): $_filteredReceipts");

    // Call appropriate grouping based on the current chart type
    if (currentChartType == ChartType.pie) {
      groupByCategory();
    } else if (currentChartType == ChartType.bar) {
      groupByInterval(selectedInterval);
    } else if (currentChartType == ChartType.line) {
      groupByMonthAndCategory();
    }

    notifyListeners();
  }

  void _clearGroupedData() {
    _groupedReceiptsByCategory = {};
    _groupedReceiptsByInterval = {};
    _groupedReceiptsByMonthAndCategory = {};
  }

  // Update filters
  void updateFilters({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _startDate = startDate;
    _endDate = endDate;
    applyFilters();
    notifyListeners();
  }

  // Group receipts by category
  void groupByCategory() {
    _groupedReceiptsByCategory = {};
    for (var receipt in _filteredReceipts) {
      final categoryId = receipt['categoryId'] ?? 'null';

      final amount = (receipt['amountToDisplay'] as num?)?.toDouble() ?? 0.0;
      // If the categoryId already exists, update the amount
      if (_groupedReceiptsByCategory!.containsKey(categoryId)) {
        _groupedReceiptsByCategory![categoryId]!['total'] += amount;
      } else {
        // If the categoryId does not exist, initialize with name, icon, and amount
        _groupedReceiptsByCategory![categoryId] = {
          'total': amount,
          'categoryName': receipt['categoryName'],
          'categoryIcon': receipt['categoryIcon'],
          'categoryColor': receipt['categoryColor'],
        };
      }
    }

    notifyListeners();
  }

  void updateInterval(TimeInterval interval) {
    _selectedInterval = interval;
    groupByInterval(interval); // Regroup receipts based on the new interval
    notifyListeners();
  }

  // Group receipts by interval
  void groupByInterval(TimeInterval interval) {
    _groupedReceiptsByInterval = {};
    for (var receipt in _filteredReceipts) {
      final date = (receipt['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final amount = (receipt['amountToDisplay'] as num?)?.toDouble() ?? 0.0;

      // Generate group key based on interval
      String groupKey;
      switch (interval) {
        case TimeInterval.day:
          groupKey = DateFormat('yyyy-MM-dd').format(date);
          break;
        case TimeInterval.week:
          groupKey = '${date.year}-W${getWeekNumber(date)}';
          break;
        case TimeInterval.month:
          groupKey = DateFormat('yyyy-MM').format(date);
          break;
        case TimeInterval.year:
          groupKey = DateFormat('yyyy').format(date);
          break;
      }

      _groupedReceiptsByInterval![groupKey] = {
        'total':
            ((_groupedReceiptsByInterval![groupKey]?['total'] ?? 0.0) + amount),
        'categoryName': receipt['categoryName'],
        'categoryIcon': receipt['categoryIcon'],
        'categoryColor': receipt['categoryColor'],
      };
    }

    notifyListeners();
  }

// Helper function to calculate the week number
  int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  void groupReceiptsByCategoryOneMonth(int month, int year) {
    final groupedReceiptsByCategoryOneMonth = <String, Map<String, dynamic>>{};

    // Filter receipts for the selected month and year
    final filteredReceipts = _allReceipts.where((receipt) {
      final date = (receipt['date'] as Timestamp?)?.toDate();
      return date?.month == month && date?.year == year;
    }).toList();

    // Log the selected month, year, and filtered receipts
    logger.i("Selected Month: $month, Year: $year");
    logger.i("Filtered Receipts for Month and Year: $filteredReceipts");

    // Group receipts by category
    for (var receipt in filteredReceipts) {
      final categoryId = receipt['categoryId'] ?? 'null';
      final amount = (receipt['amountToDisplay'] as num?)?.toDouble() ?? 0.0;

      if (groupedReceiptsByCategoryOneMonth.containsKey(categoryId)) {
        groupedReceiptsByCategoryOneMonth[categoryId]!['total'] += amount;
        // Update other fields if needed (e.g., overwrite or ensure they are set correctly)
        groupedReceiptsByCategoryOneMonth[categoryId]!['categoryName'] =
            receipt['categoryName'];
        groupedReceiptsByCategoryOneMonth[categoryId]!['categoryIcon'] =
            receipt['categoryIcon'];
        groupedReceiptsByCategoryOneMonth[categoryId]!['categoryColor'] =
            receipt['categoryColor'];
      } else {
        groupedReceiptsByCategoryOneMonth[categoryId] = {
          'categoryId': receipt['categoryId'],
          'total': amount,
          'categoryName': receipt['categoryName'],
          'categoryIcon': receipt['categoryIcon'],
          'categoryColor': receipt['categoryColor'],
        };
      }
    }

    // Log grouped data
    logger
        .i("Grouped Receipts by Category: $groupedReceiptsByCategoryOneMonth");

    _groupedReceiptsByCategoryOneMonth = groupedReceiptsByCategoryOneMonth;
    notifyListeners();
  }

  void calculateTotalSpending(Map<String, Map<String, dynamic>> groupedData) {
    double totalSpending = 0.0;

    groupedData.forEach((_, value) {
      totalSpending += value['total'] ?? 0.0;
    });

    // Update state and notify listeners
    _totalSpending = totalSpending;
    notifyListeners();
  }

  void groupByMonthAndCategory() {
    final Map<String, Map<String, Map<String, dynamic>>> groupedData = {};

    for (var receipt in _filteredReceipts) {
      // Parse the date and amount
      final date = (receipt['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final amount = (receipt['amountToDisplay'] as num?)?.toDouble() ?? 0.0;

      // Always group by month
      final intervalKey = DateFormat('yyyy-MM').format(date); // Group by month

      // Get the category ID and name
      final categoryId = receipt['categoryId'] ?? 'null';
      final categoryName = receipt['categoryName'] ?? 'Uncategorized';
      final categoryColor = receipt['categoryColor'] ?? Colors.grey;
      final categoryIcon = receipt['categoryIcon'] ?? '❓';

      // Initialize the interval if not already present
      groupedData[intervalKey] ??= {};

      // Add data to the category within the interval
      if (groupedData[intervalKey]!.containsKey(categoryId)) {
        groupedData[intervalKey]![categoryId]!['total'] += amount;
      } else {
        groupedData[intervalKey]![categoryId] = {
          'categoryName': categoryName,
          'categoryColor': categoryColor,
          'categoryIcon': categoryIcon,
          'total': amount,
        };
      }
    }

    // Store the grouped data in the provider variable
    _groupedReceiptsByMonthAndCategory = groupedData;

    // Log or debug the grouped data
    logger.i("Grouped Data by Month: $groupedData");

    // Notify listeners of changes
    notifyListeners();
  }

  // Check if adding a new expense would exceed budget threshold
  Future<bool> wouldExceedBudgetThreshold(double amount) async {
    if (_authProvider == null) return false;

    final userEmail = _authProvider!.user?.email;
    if (userEmail == null) return false;

    // Get current month's total spending
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    // Calculate total spent this month
    final totalSpent = (_groupedReceiptsByCategoryOneMonth ?? {}).values.fold(
        0.0, (sum, category) => sum + (category['total'] as double? ?? 0.0));

    // Get monthly budget and alert threshold
    final budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc(userEmail)
        .get();

    if (!budgetDoc.exists) return false;

    final monthlyBudget =
        (budgetDoc.data()?['monthlyBudget'] ?? 0.0).toDouble();
    final alertPercentage =
        (budgetDoc.data()?['alertPercentage'] ?? 80.0).toDouble();

    // Calculate new total with the potential expense
    final newTotal = totalSpent + amount;
    final percentageSpent =
        monthlyBudget > 0 ? (newTotal / monthlyBudget) * 100 : 0;

    return percentageSpent >= alertPercentage;
  }

  // Add a new receipt with budget threshold check
  Future<void> addReceipt({required Map<String, dynamic> receiptData}) async {
    if (_userEmail == null) return;

    try {
      // Add the receipt
      await _receiptService.addReceipt(
          email: _userEmail!, receiptData: receiptData);

      // Refresh all receipts
      await fetchAllReceipts();

      // Update grouped receipts for current month
      final now = DateTime.now();
      groupReceiptsByCategoryOneMonth(now.month, now.year);

      // Calculate total spending
      calculateTotalSpending(groupedReceiptsByCategoryOneMonth ?? {});

      // Refresh budget data
      final budgetProvider = Provider.of<BudgetProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      await budgetProvider.refreshBudgetData();

      // Notify listeners to update UI
      notifyListeners();

      logger.i("Receipt added and UI updated successfully");
    } catch (e) {
      logger.e("Error adding receipt: $e");
      rethrow;
    }
  }

  // Mark receipt as quick add
  Future<void> markAsQuickAdd(
      {required String receiptId, required bool isQuickAdd}) async {
    if (_userEmail != null) {
      try {
        // Get a reference to the user's receipts document
        final userDocRef =
            FirebaseFirestore.instance.collection('receipts').doc(_userEmail);

        // Get the current document
        final docSnapshot = await userDocRef.get();

        if (docSnapshot.exists) {
          // Get the receipt list
          List<dynamic> receiptList = docSnapshot.data()?['receiptlist'] ?? [];

          // Find the receipt with the matching ID
          int receiptIndex =
              receiptList.indexWhere((receipt) => receipt['id'] == receiptId);

          if (receiptIndex != -1) {
            // Update the isQuickAdd field in the receipt
            receiptList[receiptIndex]['isQuickAdd'] = isQuickAdd;

            // Update the receipt list in Firestore
            await userDocRef.update({'receiptlist': receiptList});

            // Update the local list
            final localIndex = _allReceipts
                .indexWhere((receipt) => receipt['id'] == receiptId);
            if (localIndex != -1) {
              _allReceipts[localIndex]['isQuickAdd'] = isQuickAdd;
              notifyListeners();
            }

            logger.i('Receipt $receiptId marked as quickAdd: $isQuickAdd');
          } else {
            logger.e('Receipt with ID $receiptId not found in receipt list');
          }
        } else {
          logger.e('User document not found');
        }
      } catch (e) {
        logger.e('Error marking receipt as quick add: $e');
      }
    }
  }

  // Quick add a receipt (duplicate with today's date)
  Future<void> quickAddReceipt({required String receiptId}) async {
    if (_userEmail == null) return;

    try {
      logger.i('Starting quickAddReceipt for receipt ID: $receiptId');

      // Step 1: Get the current receipt list from Firestore
      final userDocRef =
          FirebaseFirestore.instance.collection('receipts').doc(_userEmail);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        logger.e('User document not found');
        return;
      }

      // Step 2: Find the receipt to duplicate in the Firestore data
      List<dynamic> receiptList = docSnapshot.data()?['receiptlist'] ?? [];
      final receiptToDuplicateIndex =
          receiptList.indexWhere((receipt) => receipt['id'] == receiptId);

      if (receiptToDuplicateIndex == -1) {
        logger.e('Receipt with ID $receiptId not found in Firestore');
        return;
      }

      // Step 3: Create a deep copy of the receipt
      Map<String, dynamic> originalReceipt =
          Map<String, dynamic>.from(receiptList[receiptToDuplicateIndex]);
      Map<String, dynamic> newReceipt =
          Map<String, dynamic>.from(originalReceipt);

      // Step 4: Update fields in the new receipt
      String newReceiptId =
          FirebaseFirestore.instance.collection('receipts').doc().id;
      newReceipt['id'] = newReceiptId;

      // Create a new timestamp with the current time, preserving hours, minutes, and seconds
      final now = DateTime.now();
      final timestamp =
          Timestamp.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);
      newReceipt['date'] = timestamp;

      logger.i(
          'Created new receipt with ID: $newReceiptId based on receipt: ${originalReceipt['merchant']}');
      logger.i('New receipt timestamp: ${now.toIso8601String()}');

      // Step 5: Add the new receipt to the list
      receiptList.add(newReceipt);

      // Step 6: Update Firestore with the new list
      await userDocRef.update({
        'receiptlist': receiptList,
        'receiptCount': FieldValue.increment(1),
      });

      logger.i('Successfully added new receipt to Firestore');

      // Step 7: Refresh local data
      await fetchAllReceipts();

      // Step 8: Update grouped receipts for current month
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;
      groupReceiptsByCategoryOneMonth(currentMonth, currentYear);

      // Step 9: Calculate total spending
      calculateTotalSpending(groupedReceiptsByCategoryOneMonth ?? {});

      // Step 10: Refresh budget data
      final budgetProvider = Provider.of<BudgetProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      await budgetProvider.refreshBudgetData();

      // Step 11: Notify listeners to update UI
      notifyListeners();

      logger.i('Quick add receipt completed successfully');
    } catch (e) {
      logger.e('Error in quickAddReceipt: $e');
      rethrow;
    }
  }

  // Update receipt
  Future<void> updateReceipt({
    required String receiptId,
    required Map<String, dynamic> updatedData,
  }) async {
    if (_userEmail != null) {
      await _receiptService.updateReceipt(
        email: _userEmail!,
        receiptId: receiptId,
        updatedData: updatedData,
      );

      // Update oldest and newest dates
      loadOldestAndNewestDates();

      notifyListeners();
    }
  }

  // Delete receipt
  Future<void> deleteReceipt(String receiptId) async {
    if (_userEmail != null) {
      await _receiptService.deleteReceipt(_userEmail!, receiptId);

      // Update oldest and newest dates
      loadOldestAndNewestDates();

      notifyListeners();
    }
  }

  // Set receipts' category ID to null
  Future<void> setReceiptsCategoryToNull(String categoryId) async {
    if (_userEmail != null) {
      await _receiptService.setReceiptsCategoryToNull(_userEmail!, categoryId);
      notifyListeners();
    }
  }

  // Fetch receipt count
  Future<void> loadReceiptCount() async {
    if (_userEmail != null) {
      _receiptCount = _allReceipts.length;
      notifyListeners();
    }
  }

  // Get oldest and newest dates of receipts
  Future<void> loadOldestAndNewestDates() async {
    DateTime? oldestDate;
    DateTime? newestDate;

    for (var receipt in _allReceipts) {
      DateTime receiptDate = (receipt['date'] as Timestamp).toDate();

      // Check for the oldest date
      if (oldestDate == null || receiptDate.isBefore(oldestDate)) {
        oldestDate = receiptDate;
      }

      // Check for the newest date
      if (newestDate == null || receiptDate.isAfter(newestDate)) {
        newestDate = receiptDate;
      }
    }

    // Update the provider's state with the oldest and newest dates
    _oldestDate = oldestDate ?? DateTime.now();
    _newestDate = newestDate ?? DateTime.now();
    notifyListeners();
  }

  // Remove from quick add favorites
  Future<void> removeFromQuickAdd({required String receiptId}) async {
    if (_userEmail == null) return;

    try {
      // Get a reference to the user's receipts document
      final userDocRef =
          FirebaseFirestore.instance.collection('receipts').doc(_userEmail);

      // Get the current document
      final docSnapshot = await userDocRef.get();

      if (docSnapshot.exists) {
        // Get the receipt list
        List<dynamic> receiptList = docSnapshot.data()?['receiptlist'] ?? [];

        // Find the receipt with the matching ID
        int receiptIndex =
            receiptList.indexWhere((receipt) => receipt['id'] == receiptId);

        if (receiptIndex != -1) {
          // Update the isQuickAdd field in the receipt
          receiptList[receiptIndex]['isQuickAdd'] = false;

          // Update the receipt list in Firestore
          await userDocRef.update({'receiptlist': receiptList});

          // Update the local list
          final localIndex =
              _allReceipts.indexWhere((receipt) => receipt['id'] == receiptId);
          if (localIndex != -1) {
            _allReceipts[localIndex]['isQuickAdd'] = false;
            notifyListeners();
          }

          logger.i('Receipt $receiptId removed from quick add favorites');
        } else {
          logger.e('Receipt with ID $receiptId not found in receipt list');
        }
      } else {
        logger.e('User document not found');
      }
    } catch (e) {
      logger.e('Error removing receipt from quick add favorites: $e');
      rethrow;
    }
  }

  /// Calculates the Weekly Financial Wellness Score for the most recent full week.
  /// Returns a map: { 'weekRange': String, 'totalScore': int, 'categoryScores': List<CategoryScore> }
  Map<String, dynamic> calculateWeeklyWellnessScore(double monthlyBudget,
      {int weekOffset = 0}) {
    // --- 1. Define the 7 key categories and their rules ---
    final List<_WellnessCategoryRule> rules = [
      _WellnessCategoryRule(
        displayName: 'Rent & Utilities',
        icon: Icons.home,
        idealMin: 25,
        idealMax: 35,
        maxScore: 20,
        color: const Color(0xFF4CAF50),
      ),
      _WellnessCategoryRule(
        displayName: 'Groceries',
        icon: Icons.restaurant,
        idealMin: 10,
        idealMax: 15,
        maxScore: 15,
        color: const Color(0xFF43A047),
      ),
      _WellnessCategoryRule(
        displayName: 'Dining & Coffee',
        icon: Icons.local_cafe,
        idealMin: 0,
        idealMax: 10,
        maxScore: 15,
        color: const Color(0xFF388E3C),
      ),
      _WellnessCategoryRule(
        displayName: 'Transportation & Fuel',
        icon: Icons.directions_car,
        idealMin: 10,
        idealMax: 12,
        maxScore: 15,
        color: const Color(0xFF1976D2),
      ),
      _WellnessCategoryRule(
        displayName: 'Entertainment & Subs',
        icon: Icons.movie,
        idealMin: 0,
        idealMax: 6,
        maxScore: 10,
        color: const Color(0xFFFFA726),
      ),
      _WellnessCategoryRule(
        displayName: 'Shopping & Personal Care',
        icon: Icons.shopping_bag,
        idealMin: 0,
        idealMax: 7,
        maxScore: 15,
        color: const Color(0xFFFF7043),
      ),
      _WellnessCategoryRule(
        displayName: 'Savings & Investments',
        icon: Icons.savings,
        idealMin: 15,
        idealMax: 25,
        maxScore: 20,
        color: const Color(0xFF00BFAE),
      ),
    ];

    // --- 1b. Map display names to category IDs from user's categories ---
    final Map<String, String> displayNameToCategoryId = {};
    if (_categoryProvider != null && _categoryProvider!.categories.isNotEmpty) {
      for (final rule in rules) {
        final match = _categoryProvider!.categories.firstWhere(
          (cat) =>
              (cat['name'] as String).trim().toLowerCase() ==
              rule.displayName.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        if (match.isNotEmpty) {
          displayNameToCategoryId[rule.displayName] = match['id'];
        } else {
          // Fallback: use the first available categoryId if mapping fails
          if (_categoryProvider!.categories.isNotEmpty) {
            displayNameToCategoryId[rule.displayName] =
                _categoryProvider!.categories.first['id'];
          }
        }
      }
    }
    logger.i(
        'WELLNESS: displayNameToCategoryId mapping: $displayNameToCategoryId');
    // If mapping is still empty, return no data
    if (displayNameToCategoryId.isEmpty) {
      logger
          .w('WELLNESS: No categoryId mapping found for wellness categories.');
      return {
        'weekRange': 'No Data',
        'totalScore': 0,
        'categoryScores': rules.map((r) => r.toCategoryScore(0, 0)).toList(),
      };
    }

    // --- 2. Find the most recent full week (Monday-Sunday) ---
    if (_allReceipts.isEmpty || monthlyBudget == 0) {
      return {
        'weekRange': 'No Data',
        'totalScore': 0,
        'categoryScores': rules.map((r) => r.toCategoryScore(0, 0)).toList(),
      };
    }
    // Find the latest receipt date
    DateTime latest = _allReceipts
        .map((r) => (r['date'] as Timestamp).toDate())
        .reduce((a, b) => a.isAfter(b) ? a : b);
    // Find the last Sunday before or on latest, then shift by weekOffset
    DateTime lastSunday = latest
        .subtract(Duration(days: latest.weekday % 7))
        .subtract(Duration(days: 7 * weekOffset));
    // The week starts on Monday
    DateTime weekStart = lastSunday.subtract(const Duration(days: 6));
    DateTime weekEnd = lastSunday;
    // Filter receipts in this week
    final weekReceipts = _allReceipts.where((r) {
      final d = (r['date'] as Timestamp).toDate();
      return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
    }).toList();
    logger.i('WELLNESS: weekReceipts count: ${weekReceipts.length}');
    for (final r in weekReceipts) {
      logger.i(
          'WELLNESS: Receipt ID: ${r['id']}, categoryId: ${r['categoryId']}, amount: ${r['amountToDisplay']}');
    }
    if (weekReceipts.isEmpty) {
      return {
        'weekRange': 'No Data',
        'totalScore': 0,
        'categoryScores': rules.map((r) => r.toCategoryScore(0, 0)).toList(),
      };
    }
    // --- 3. Calculate weekly budget ---
    final weeklyBudget = monthlyBudget / 4.345; // average weeks per month
    // --- 4. Sum spending per category group by categoryId ---
    Map<String, double> categoryTotals = {
      for (var r in rules) r.displayName: 0.0
    };
    double totalSavings = 0.0;
    for (final receipt in weekReceipts) {
      final receiptCategoryId = receipt['categoryId'] as String?;
      final amount = (receipt['amountToDisplay'] as num?)?.toDouble() ?? 0.0;
      bool matched = false;
      for (final rule in rules) {
        final ruleCategoryId = displayNameToCategoryId[rule.displayName];
        if (ruleCategoryId != null && receiptCategoryId == ruleCategoryId) {
          if (rule.displayName == 'Savings & Investments') {
            totalSavings += amount;
          } else {
            categoryTotals[rule.displayName] =
                (categoryTotals[rule.displayName] ?? 0) + amount;
          }
          matched = true;
          logger.i(
              'WELLNESS: Matched receipt ${receipt['id']} to ${rule.displayName} (categoryId: $ruleCategoryId), amount: $amount');
          break;
        }
      }
      // Optionally, handle uncategorized or unmatched as needed
      if (!matched &&
          receiptCategoryId == displayNameToCategoryId['Savings & Investments'])
        totalSavings += amount;
    }
    logger.i(
        'WELLNESS: categoryTotals: $categoryTotals, totalSavings: $totalSavings');
    categoryTotals['Savings & Investments'] = totalSavings;
    // --- 5. Calculate percent and score for each category ---
    List<CategoryScore> categoryScores = [];
    int totalScore = 0;
    for (final rule in rules) {
      final spent = categoryTotals[rule.displayName] ?? 0.0;
      final percent = ((spent / weeklyBudget) * 100).round();
      int points = 0;
      // Scoring logic
      if (rule.displayName == 'Savings & Investments') {
        if (percent >= rule.idealMin && percent <= rule.idealMax) {
          points = rule.maxScore;
        } else if (percent > rule.idealMax) {
          // Bonus: 1 extra point for every 2% above max, up to double maxScore
          points = rule.maxScore + ((percent - rule.idealMax) ~/ 2);
          if (points > rule.maxScore * 2) points = rule.maxScore * 2;
        } else if (percent >= rule.idealMin - 5) {
          points = (rule.maxScore * 0.7).round();
        } else {
          points = (rule.maxScore * 0.4).round();
        }
      } else if (percent >= rule.idealMin && percent <= rule.idealMax) {
        points = rule.maxScore;
      } else if (percent < rule.idealMin) {
        points = (rule.maxScore * 0.7).round();
      } else {
        // Over budget: heavier penalty for Dining, Shopping
        if (rule.displayName == 'Dining & Coffee' ||
            rule.displayName == 'Shopping & Personal Care') {
          points = (rule.maxScore * 0.3).round();
        } else if (rule.displayName == 'Entertainment & Subs') {
          points = (rule.maxScore * 0.5 * 0.85).round(); // 15% more negative
        } else {
          points = (rule.maxScore * 0.5).round();
        }
      }
      if (points < 0) points = 0;
      if (points > rule.maxScore * 2) points = rule.maxScore * 2;
      totalScore += points > rule.maxScore ? rule.maxScore : points;
      categoryScores.add(rule.toCategoryScore(percent, points));
    }
    // --- 6. Format week range ---
    final weekRange =
        '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d, yyyy').format(weekEnd)}';
    return {
      'weekRange': weekRange,
      'totalScore': totalScore > 100 ? 100 : totalScore,
      'categoryScores': categoryScores,
    };
  }
}

// Helper class for category rules
class _WellnessCategoryRule {
  final IconData icon;
  final String displayName;
  final int idealMin;
  final int idealMax;
  final int maxScore;
  final Color color;
  const _WellnessCategoryRule({
    required this.icon,
    required this.displayName,
    required this.idealMin,
    required this.idealMax,
    required this.maxScore,
    required this.color,
  });
  CategoryScore toCategoryScore(int percent, int points) => CategoryScore(
        icon: icon,
        name: displayName,
        percent: percent,
        maxPercent: idealMin == 0 ? '<$idealMax%' : '$idealMin–$idealMax%',
        points: points,
        maxPoints: maxScore,
        color: color,
      );
}
