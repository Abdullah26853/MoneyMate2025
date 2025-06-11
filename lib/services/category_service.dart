import 'package:cloud_firestore/cloud_firestore.dart';

import '../logger.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define default categories
  final List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Rent & Utilities', 'icon': '🏠'},
    {'name': 'Groceries', 'icon': '🥦'},
    {'name': 'Dining & Coffee', 'icon': '☕️'},
    {'name': 'Transportation & Fuel', 'icon': '🚗'},
    {'name': 'Entertainment & Subs', 'icon': '🎬'},
    {'name': 'Shopping & Personal Care', 'icon': '🛍️'},
    {'name': 'Savings & Investments', 'icon': '🐷'},
  ];

  // Fetch user categories
  Future<List<Map<String, dynamic>>> fetchUserCategories(String email) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(email).get();

      // If the document does not exist, or categorylist is missing or empty, create with defaults
      var data = userDoc.data() as Map<String, dynamic>?;
      List<dynamic> categoryList = data?['categorylist'] ?? [];

      if (!userDoc.exists || data == null || categoryList.isEmpty) {
        // Create or update with default categories
        final defaultWithIds = defaultCategories
            .map((category) => {
                  'id': _firestore.collection('categories').doc().id,
                  'name': category['name'],
                  'icon': category['icon'],
                })
            .toList();
        await _firestore.collection('categories').doc(email).set({
          'categorylist': defaultWithIds,
        });
        return defaultWithIds;
      }

      return categoryList
          .map((category) => {
                'id': category['id'] ?? '', // Keep the existing ID
                'name': category['name'] ?? 'Unknown',
                'icon': category['icon'] ?? '',
              })
          .toList();
    } catch (e) {
      logger.e("Error fetching user categories: $e");
      return [];
    }
  }

  // Add a new category with a random key
  Future<void> addCategoryToFirestore(
      String email, String categoryName, String categoryIcon) async {
    try {
      // Generate a unique random key for the category
      String categoryId = _firestore.collection('categories').doc().id;

      // Reference to the user's document
      DocumentReference userDocRef =
          _firestore.collection('categories').doc(email);

      // Fetch the user's document
      DocumentSnapshot userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // If the document doesn't exist, create it and initialize categorylist with the new category
        await userDocRef.set({
          'categorylist': [
            {'id': categoryId, 'name': categoryName, 'icon': categoryIcon}
          ],
        });
      } else {
        // If the document exists, add the new category to the existing categorylist
        await userDocRef.update({
          'categorylist': FieldValue.arrayUnion([
            {'id': categoryId, 'name': categoryName, 'icon': categoryIcon}
          ]),
        });
      }
    } catch (e) {
      logger.e("Error adding category: $e");
    }
  }

  // Delete category by its random key (id)
  Future<void> deleteCategory(String email, String categoryId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(email).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];

        // Find the category by its ID
        var categoryToDelete = categoryList.firstWhere(
            (category) => category['id'] == categoryId,
            orElse: () => null);

        if (categoryToDelete != null) {
          // Remove the category using FieldValue.arrayRemove
          await _firestore.collection('categories').doc(email).update({
            'categorylist': FieldValue.arrayRemove([categoryToDelete])
          });
        }
      }
    } catch (e) {
      logger.e("Error deleting category: $e");
    }
  }

  // Check if a category exists (by name) in the Firestore
  Future<bool> categoryExists(String email, String categoryName) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('categories').doc(email).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> categoryList = data['categorylist'] ?? [];

        return categoryList.any((category) =>
            category['name'].trim().toString() == categoryName.trim());
      }

      return false;
    } catch (e) {
      logger.e("Error checking if category exists: $e");
      return false;
    }
  }
}
