import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/category_provider.dart';
import 'custom_button.dart';
import 'custom_divider.dart';

class CategorySelectPopup extends StatefulWidget {
  const CategorySelectPopup({super.key});

  @override
  CategorySelectPopupState createState() => CategorySelectPopupState();
}

class CategorySelectPopupState extends State<CategorySelectPopup> {
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    Provider.of<CategoryProvider>(context, listen: false).loadUserCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, _) {
          final userCategories = categoryProvider.categories;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomDivider(),
              SizedBox(
                  height:
                      8), // Set a fixed height for the grid, allowing it to scroll if there are too many items
              Container(
                height: 400, // Fixed height for the grid container
                decoration: BoxDecoration(
                  color: light90,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(18), // Optional padding for the grid
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: userCategories.length,
                  itemBuilder: (context, index) {
                    String categoryId = userCategories[index]['id'] ?? '';
                    String categoryName =
                        userCategories[index]['name']?.trim() ?? '';
                    bool isSelected = categoryId == selectedCategoryId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryId = categoryId;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? purple60 // Active background color
                              : light40, // Inactive background color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userCategories[index]['icon'] ?? '',
                              style: TextStyle(
                                fontSize: 32,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              CustomButton(
                  text: "Confirm",
                  backgroundColor: purple100,
                  textColor: light80,
                  onPressed: () {
                    Navigator.of(context)
                        .pop(selectedCategoryId); // Return selected category ID
                  } // Close the popup},
                  ),
            ],
          );
        },
      ),
    );
  }
}
