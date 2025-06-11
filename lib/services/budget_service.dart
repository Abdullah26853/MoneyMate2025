import 'package:cloud_firestore/cloud_firestore.dart';

import '../logger.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all budgets for a user including monthly budget
  Future<Map<String, dynamic>> fetchUserBudgetsWithMonthly(String email) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('budgets').doc(email).get();

      if (!userDoc.exists) {
        // Document does not exist, create it with default data
        await _firestore.collection('budgets').doc(email).set({
          'budgetlist': [],
          'monthlyBudget': 0.0,
          'alertPercentage': 80.0, // Default alert at 80%
        });
        logger.i("Default document created for email: $email");
        return {
          'categoryBudgets': [],
          'monthlyBudget': 0.0,
          'alertPercentage': 80.0,
        };
      }

      // Document exists, return the budget list and monthly budget
      var data = userDoc.data() as Map<String, dynamic>;
      List<dynamic> budgetList = data['budgetlist'] ?? [];
      double monthlyBudget = (data['monthlyBudget'] ?? 0.0).toDouble();
      double alertPercentage = (data['alertPercentage'] ?? 80.0).toDouble();

      // Convert budget list to proper format
      List<Map<String, dynamic>> categoryBudgets = budgetList.map((budget) {
        return {
          'categoryId': budget['categoryId'] ?? '',
          'amount': (budget['amount'] ?? 0.0).toDouble(),
          'period': budget['period'] ?? 'monthly',
        };
      }).toList();

      return {
        'categoryBudgets': categoryBudgets,
        'monthlyBudget': monthlyBudget,
        'alertPercentage': alertPercentage,
      };
    } catch (e) {
      logger.e("Error fetching user budgets: $e");
      return {
        'categoryBudgets': [],
        'monthlyBudget': 0.0,
        'alertPercentage': 80.0,
      };
    }
  }

  // Legacy method for backward compatibility
  Future<List<Map<String, dynamic>>> fetchUserBudgets(String email) async {
    try {
      var result = await fetchUserBudgetsWithMonthly(email);
      return result['categoryBudgets'];
    } catch (e) {
      logger.e("Error fetching user budgets: $e");
      return [];
    }
  }

  // Update user budgets including monthly budget
  Future<void> updateUserBudgets(
      String email,
      List<Map<String, dynamic>> budgetList,
      double monthlyBudget,
      double alertPercentage) async {
    try {
      await _firestore.collection('budgets').doc(email).set(
          {
            'budgetlist': budgetList,
            'monthlyBudget': monthlyBudget,
            'alertPercentage': alertPercentage,
          },
          SetOptions(
              merge:
                  true)); // Use `set` with merge to ensure creation if missing
    } catch (e) {
      logger.e("Error updating user budgets: $e");
      rethrow;
    }
  }
}
