import 'package:flutter/material.dart';

import '../services/budget_service.dart';
import 'authentication_provider.dart';
import 'category_provider.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();
  AuthenticationProvider? _authProvider;
  CategoryProvider? _categoryProvider;

  List<Map<String, dynamic>> _budgets = [];
  Map<String, dynamic>? _budgetByCategory;
  double _monthlyBudget = 0.0;
  double _alertPercentage = 80.0; // Default alert at 80% of budget

  // Getter for budgets with category information
  List<Map<String, dynamic>> get budgets {
    // Add a special "Monthly Budget" item at the beginning of the list
    List<Map<String, dynamic>> allBudgets = [
      {
        'categoryId': 'monthly_budget',
        'categoryName': 'Monthly Budget',
        'categoryIcon': '📅',
        'amount': _monthlyBudget,
        'alertPercentage': _alertPercentage,
        'period': 'monthly',
        'isMonthlyBudget': true,
      }
    ];

    // Add category budgets
    allBudgets.addAll(_budgets.map((budget) {
      final categoryId = budget['categoryId'];
      final category = _categoryProvider?.categories.firstWhere(
        (cat) => cat['id'] == categoryId,
        orElse: () => {'name': 'Unknown', 'icon': '❓'},
      );
      return {
        ...budget,
        'categoryName': category?['name'] ?? 'Unknown',
        'categoryIcon': category?['icon'] ?? '❓',
        'isMonthlyBudget': false,
      };
    }));

    return allBudgets;
  }

  // Getter for just the monthly budget amount
  double get monthlyBudget => _monthlyBudget;
  double get alertPercentage => _alertPercentage;

  Map<String, dynamic>? get budgetByCategory => _budgetByCategory;

  // Setters for AuthenticationProvider and CategoryProvider
  set authProvider(AuthenticationProvider authProvider) {
    _authProvider = authProvider;
    notifyListeners();
  }

  set categoryProvider(CategoryProvider categoryProvider) {
    _categoryProvider = categoryProvider;
    updateCategories(); // Update categories whenever CategoryProvider changes
  }

  // Helper to get user email from AuthenticationProvider
  String? get _userEmail => _authProvider?.user?.email;

  // Load user budgets
  Future<void> loadUserBudgets() async {
    if (_authProvider?.user?.email == null) return;

    try {
      final result = await _budgetService
          .fetchUserBudgetsWithMonthly(_authProvider!.user!.email!);

      _monthlyBudget = result['monthlyBudget'] ?? 0.0;
      _alertPercentage = result['alertPercentage'] ?? 80.0;

      // Update category budgets
      _budgets = (result['categoryBudgets'] as List<dynamic>).map((budget) {
        return {
          'categoryId': budget['categoryId'] ?? '',
          'amount': (budget['amount'] ?? 0.0).toDouble(),
          'period': budget['period'] ?? 'monthly',
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error loading user budgets: $e');
    }
  }

  // Refresh budget data
  Future<void> refreshBudgetData() async {
    await loadUserBudgets();
  }

  // Method to update budgets based on updated categories from CategoryProvider
  void updateCategories() {
    if (_categoryProvider != null) {
      List<Map<String, dynamic>> categories = _categoryProvider!.categories;

      // Update _budgets to align with the new categories
      _budgets = categories.map((category) {
        Map<String, dynamic>? existingBudget = _budgets.firstWhere(
          (budget) => budget['categoryId'] == category['id'],
          orElse: () => {'amount': 0.0, 'period': 'monthly'},
        );

        return {
          'categoryId': category['id'],
          'categoryName': category['name'],
          'categoryIcon': category['icon'],
          'amount': existingBudget['amount'] ?? 0.0,
          'period': existingBudget['period'] ?? 'monthly',
        };
      }).toList();

      notifyListeners();
    }
  }

  // Update budgets for the current user
  Future<void> updateUserBudgets(List<Map<String, dynamic>> budgetList) async {
    if (_userEmail != null) {
      // Extract monthly budget from the list if present
      Map<String, dynamic>? monthlyBudgetItem = budgetList.firstWhere(
        (budget) => budget['categoryId'] == 'monthly_budget',
        orElse: () =>
            {'amount': _monthlyBudget, 'alertPercentage': _alertPercentage},
      );

      // Remove monthly budget from category budgets list
      List<Map<String, dynamic>> categoryBudgets = budgetList
          .where((budget) => budget['categoryId'] != 'monthly_budget')
          .toList();

      // Update monthly budget value and alert percentage
      _monthlyBudget = monthlyBudgetItem['amount'] ?? _monthlyBudget;
      _alertPercentage =
          monthlyBudgetItem['alertPercentage'] ?? _alertPercentage;

      // Save to Firestore
      await _budgetService.updateUserBudgets(
          _userEmail!, categoryBudgets, _monthlyBudget, _alertPercentage);
      await loadUserBudgets(); // Refresh after updating
    }
  }

  // Set just the monthly budget
  Future<void> setMonthlyBudget(double amount) async {
    if (_userEmail != null) {
      _monthlyBudget = amount;
      await _budgetService.updateUserBudgets(
          _userEmail!, _budgets, _monthlyBudget, _alertPercentage);
      notifyListeners();
    }
  }

  // Set alert percentage
  Future<void> setAlertPercentage(double percentage) async {
    if (_userEmail != null) {
      _alertPercentage = percentage;
      await _budgetService.updateUserBudgets(
          _userEmail!, _budgets, _monthlyBudget, _alertPercentage);
      notifyListeners();
    }
  }
}
