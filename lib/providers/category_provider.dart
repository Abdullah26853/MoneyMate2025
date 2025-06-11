import 'package:flutter/material.dart';

import '../providers/authentication_provider.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  AuthenticationProvider? _authProvider;

  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _categoryDetails;

  List<Map<String, dynamic>> get categories => _categories;
  Map<String, dynamic>? get categoryDetails => _categoryDetails;

  // Predefined colors for categories
  final List<Color> _predefinedColors = [
    Color(0xFF42A5F5), // Soft Blue
    Color(0xFF66BB6A), // Soft Green
    Color(0xFFEF5350), // Soft Red
    Color(0xFFFFCA28), // Soft Yellow
    Color(0xFFAB47BC), // Soft Purple
    Color(0xFFFF7043), // Soft Orange
    Color(0xFF26C6DA), // Soft Cyan
    Color(0xFF8D6E63), // Soft Brown
    Color(0xFF5C6BC0), // Soft Indigo
    Color(0xFF26A69A), // Soft Teal
    Color(0xFFEC407A), // Soft Pink
    Color(0xFFD4E157), // Soft Lime Green
    Color(0xFF78909C), // Soft Blue Gray
  ];

  // Setter for AuthenticationProvider
  set authProvider(AuthenticationProvider authProvider) {
    _authProvider = authProvider;
    notifyListeners(); // Notify listeners if the authProvider changes
  }

  // Helper to get the user's email from AuthenticationProvider
  String? get _userEmail => _authProvider?.user?.email;

  // Fetch all categories for the current user and assign colors
  Future<void> loadUserCategories() async {
    if (_userEmail != null) {
      _categories = await _categoryService.fetchUserCategories(_userEmail!);

      // Assign colors to categories by cycling through the predefined colors
      for (int i = 0; i < _categories.length; i++) {
        _categories[i]['color'] =
            _predefinedColors[i % _predefinedColors.length];
      }

      notifyListeners();
    }
  }

  // Add a new category for the current user
  Future<void> addCategory(String name, String icon) async {
    if (_userEmail != null) {
      await _categoryService.addCategoryToFirestore(_userEmail!, name, icon);
      await loadUserCategories(); // Reload categories after adding
    }
  }

  // Delete a category for the current user
  Future<void> deleteCategory(String categoryId) async {
    if (_userEmail != null) {
      await _categoryService.deleteCategory(_userEmail!, categoryId);
      await loadUserCategories(); // Reload categories after deleting
    }
  }

  // Check if a category exists for the current user
  Future<bool> checkIfCategoryExists(String categoryName) async {
    if (_userEmail != null) {
      return await _categoryService.categoryExists(_userEmail!, categoryName);
    }
    return false;
  }
}
