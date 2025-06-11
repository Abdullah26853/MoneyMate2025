import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/date_range_container.dart';
import '../constants/app_colors.dart';
import '../logger.dart';
import '../providers/category_provider.dart';
import '../providers/receipt_provider.dart';
import 'date_range_picker_popup.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  CustomAppBarState createState() => CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomAppBarState extends State<CustomAppBar> {
  @override
  void initState() {
    super.initState();
    // Load user categories when the app bar is initialized
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    categoryProvider.loadUserCategories();
    logger.i('User categories loaded');
  }

  @override
  Widget build(BuildContext context) {
    final receiptProvider = Provider.of<ReceiptProvider>(context);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: light90,
      elevation: 0,
      centerTitle: true,
      actions: [
        // Date Range Picker Button
        DateRangeContainer(
          startDate:
              receiptProvider.startDate ?? DateTime(DateTime.now().year, 1, 1),
          endDate: receiptProvider.endDate ?? DateTime.now(),
          onCalendarPressed: () => _showCalendarFilterDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Show Calendar Filter Dialog
  void _showCalendarFilterDialog(BuildContext context) {
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return CalendarFilterWidget(
          initialStartDate:
              receiptProvider.startDate ?? DateTime(DateTime.now().year, 1, 1),
          initialEndDate: receiptProvider.endDate ?? DateTime.now(),
          onApply: (start, end) {
            logger.i('Applying date range filter: Start: $start, End: $end');
            receiptProvider.updateFilters(
              startDate: start,
              endDate: end,
            );
          },
        );
      },
    );
  }
}
