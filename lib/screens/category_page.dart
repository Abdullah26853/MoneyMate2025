import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/add_category_widget.dart';
import '../components/category_delete_popup.dart';
import '../constants/app_colors.dart';
import '../providers/authentication_provider.dart';
import '../providers/category_provider.dart';

class CategoryPage extends StatefulWidget {
  static const String id = 'category_page';

  const CategoryPage({super.key});

  @override
  CategoryPageState createState() => CategoryPageState();
}

class CategoryPageState extends State<CategoryPage> {
  late AuthenticationProvider authProvider;
  late CategoryProvider categoryProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch providers after the widget is added to the tree
      authProvider =
          Provider.of<AuthenticationProvider>(context, listen: false);
      categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

      // Load categories for the user once at the beginning
      loadCategoriesForUser();
    });
  }

  void loadCategoriesForUser() {
    final userEmail = authProvider.user?.email;
    if (userEmail != null) {
      categoryProvider.loadUserCategories();
    }
  }

  void _showAddCategoryDialog() {
    final userEmail = authProvider.user?.email;

    if (userEmail != null) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: AddCategoryWidget(
              onCategoryAdded: () {
                categoryProvider.loadUserCategories();
              },
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Manage Categories', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Divider(
            color: Colors.grey.shade300,
            thickness: 1,
            height: 1,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Consumer<CategoryProvider>(
                builder: (context, categoryProvider, _) {
                  final categories = categoryProvider.categories;

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                        bottom: 60), // Add padding to prevent FAB overlap
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      String categoryId = categories[index]['id'] ?? '';
                      String categoryName =
                          categories[index]['name']?.trim() ?? '';
                      Color categoryColor =
                          categories[index]['color'] ?? Colors.grey.shade200;

                      return ListTile(
                        leading: Container(
                          width: 40, // Set the width of the container
                          height: 40, // Set the height of the container
                          decoration: BoxDecoration(
                            color: categoryColor, // Set the background color
                            borderRadius: BorderRadius.circular(
                                8), // Set the border radius to 8
                          ),

                          alignment: Alignment
                              .center, // Center the text inside the container
                          child: Text(
                            categories[index]['icon'] ?? '',
                            style: TextStyle(
                                fontSize: 24), // Set text color and size
                          ),
                        ),
                        title: Text(
                          categoryName,
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        trailing: IconButton(
                          icon:
                              Icon(Icons.delete_outline, color: categoryColor),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (BuildContext context) {
                                return CategoryDeletePopup(
                                  categoryId:
                                      categoryId, // Pass categoryId here
                                  onConfirm: () async {
                                    await categoryProvider
                                        .deleteCategory(categoryId);
                                    Navigator.of(context)
                                        .pop(); // Close the popup
                                  },
                                  onCancel: () {
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            );
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: purple100,
        elevation: 6,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
