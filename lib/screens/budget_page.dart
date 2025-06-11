import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/authentication_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';

class BudgetPage extends StatefulWidget {
  static const String id = 'budget_page';

  const BudgetPage({super.key});

  @override
  BudgetPageState createState() => BudgetPageState();
}

class BudgetPageState extends State<BudgetPage> {
  late AuthenticationProvider authProvider;
  late BudgetProvider budgetProvider;
  List<Map<String, dynamic>> updatedBudgets = []; // Local list to store changes
  Map<String, TextEditingController> controllers =
      {}; // Map to store controllers

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authProvider =
          Provider.of<AuthenticationProvider>(context, listen: false);
      budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      // Load budgets when the page is opened
      // Load categories for the user once at the beginning
      loadBudgetsForUser();
    });
  }

  @override
  void dispose() {
    // Dispose all controllers when the widget is disposed
    controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void loadBudgetsForUser() async {
    final userEmail = authProvider.user?.email;
    if (userEmail != null) {
      // Load categories first
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.loadUserCategories();

      // Then load budgets
      await budgetProvider.loadUserBudgets();
      if (mounted) {
        setState(() {
          // Only use categories that exist in CategoryProvider
          final currentCategories = categoryProvider.categories;
          updatedBudgets = currentCategories.map((category) {
            // Try to find an existing budget for this category
            final existingBudget = budgetProvider.budgets.firstWhere(
              (b) => b['categoryId'] == category['id'],
              orElse: () => <String, dynamic>{},
            );
            return {
              'categoryId': category['id'],
              'categoryName': category['name'],
              'categoryIcon': category['icon'],
              'amount': existingBudget != null ? existingBudget['amount'] : 0.0,
              'period':
                  existingBudget != null ? existingBudget['period'] : 'monthly',
              'isMonthlyBudget': false,
            };
          }).toList();
          // Add the monthly budget at the top
          updatedBudgets.insert(
              0,
              budgetProvider.budgets.firstWhere(
                (b) => b['categoryId'] == 'monthly_budget',
                orElse: () => {
                  'categoryId': 'monthly_budget',
                  'categoryName': 'Monthly Budget',
                  'categoryIcon': '📅',
                  'amount': budgetProvider.monthlyBudget,
                  'alertPercentage': budgetProvider.alertPercentage,
                  'period': 'monthly',
                  'isMonthlyBudget': true,
                },
              ));
          // Initialize controllers for each budget
          for (var budget in updatedBudgets) {
            final categoryId = budget['categoryId'];
            if (!controllers.containsKey(categoryId)) {
              controllers[categoryId] = TextEditingController(
                text: budget['amount'].toStringAsFixed(2),
              );
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Budgets', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Divider(color: Colors.grey.shade300, thickness: 1, height: 1),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Consumer<BudgetProvider>(
                builder: (context, budgetProvider, _) {
                  final budgets = budgetProvider.budgets;

                  // Initialize updatedBudgets when budgets are loaded
                  if (updatedBudgets.isEmpty) {
                    updatedBudgets =
                        budgets.map((budget) => {...budget}).toList();
                    // Initialize controllers for each budget
                    for (var budget in updatedBudgets) {
                      final categoryId = budget['categoryId'];
                      if (!controllers.containsKey(categoryId)) {
                        controllers[categoryId] = TextEditingController(
                          text: budget['amount'].toStringAsFixed(2),
                        );
                      }
                    }
                  }

                  return ListView.builder(
                    itemCount: updatedBudgets.length,
                    itemBuilder: (context, index) {
                      String categoryName =
                          updatedBudgets[index]['categoryName'] ?? '';
                      String categoryIcon =
                          updatedBudgets[index]['categoryIcon'] ?? '';
                      bool isMonthlyBudget =
                          updatedBudgets[index]['isMonthlyBudget'] ?? false;
                      String categoryId = updatedBudgets[index]['categoryId'];

                      // Get or create controller for this budget
                      if (!controllers.containsKey(categoryId)) {
                        controllers[categoryId] = TextEditingController(
                          text: updatedBudgets[index]['amount']
                              .toStringAsFixed(2),
                        );
                      }

                      // Special styling for monthly budget
                      if (isMonthlyBudget) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.025,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFE6F2FF), // Light blue background
                              borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.04,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.04,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Monthly Budget",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: purple100,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Set your total budget for the month. This will be used to calculate how much you have left to spend.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Text(
                                        "EGP",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: controllers[categoryId],
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                  decimal: true),
                                          decoration: InputDecoration(
                                            hintText:
                                                "Enter monthly budget amount",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              updatedBudgets[index]['amount'] =
                                                  double.tryParse(value) ?? 0.0;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "Alert Threshold",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Get notified when you reach this percentage of your monthly budget.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Slider(
                                          value: updatedBudgets[index]
                                                  ['alertPercentage'] ??
                                              80.0,
                                          min: 50.0,
                                          max: 95.0,
                                          divisions: 9,
                                          label:
                                              "${(updatedBudgets[index]['alertPercentage'] ?? 80.0).round()}%",
                                          onChanged: (value) {
                                            setState(() {
                                              updatedBudgets[index]
                                                  ['alertPercentage'] = value;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Container(
                                        width: 60,
                                        child: Text(
                                          "${(updatedBudgets[index]['alertPercentage'] ?? 80.0).round()}%",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: purple100,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Regular category budget
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.04,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.09,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.04,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  categoryIcon,
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.07,
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.04,
                                ),
                                Expanded(
                                  child: Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.045,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.25,
                                  child: TextFormField(
                                    controller: controllers[categoryId],
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      hintText: "0.00",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                        ),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                        ),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.03,
                                        vertical:
                                            MediaQuery.of(context).size.height *
                                                0.015,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.045,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        updatedBudgets[index]['amount'] =
                                            double.tryParse(value) ?? 0.0;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard on save

          // Create a list with only categoryId and amount for saving
          List<Map<String, dynamic>> budgetsToSave = updatedBudgets;

          try {
            final budgetProvider =
                Provider.of<BudgetProvider>(context, listen: false);
            await budgetProvider.updateUserBudgets(budgetsToSave);

            // Refresh the budgets after saving
            await budgetProvider.loadUserBudgets();

            // Update the local state
            if (mounted) {
              setState(() {
                updatedBudgets = budgetProvider.budgets
                    .map((budget) => {...budget})
                    .toList();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Budgets saved successfully")),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("Failed to save budgets. Please try again.")),
              );
            }
          }
        },
        backgroundColor: purple100,
        elevation: 6,
        child: Icon(Icons.save, color: Colors.white),
      ),
    );
  }
}
