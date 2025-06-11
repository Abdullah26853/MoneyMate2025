import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:receipt_manager/constants/app_colors.dart';
import 'package:receipt_manager/providers/receipt_provider.dart';
import 'package:fl_chart/fl_chart.dart';

//import '../components/custom_app_bar.dart';
import '../components/expense_item_card.dart';
import 'add_update_receipt_page.dart';

//implement a search bar that updates dynamically
class ReceiptListPage extends StatefulWidget {
  static const String id = 'receipt_list_page';

  const ReceiptListPage({super.key});

  @override
  ReceiptListPageState createState() => ReceiptListPageState();
}

class ReceiptListPageState extends State<ReceiptListPage> {
  // Added State Variables for Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  // Inside ReceiptListPageState
  List<Map<String, dynamic>> _searchedReceipts =
      []; // Local list for search results

  // Filter state
  String _activeFilter = 'Day'; // Changed from 'All' to 'Day' as default

  String _currencySymbolToDisplay = ' ';

  late VoidCallback _receiptProviderListener;

  // Helper function to sort receipts by timestamp (newest first)
  void _sortReceiptsByTimestamp(List<Map<String, dynamic>> receipts) {
    receipts.sort((a, b) {
      // Get the full timestamp including time
      final timestampA = a['date'] as Timestamp;
      final timestampB = b['date'] as Timestamp;

      // Compare seconds first (higher value means newer)
      if (timestampB.seconds != timestampA.seconds) {
        return timestampB.seconds.compareTo(timestampA.seconds);
      }

      // If seconds are equal, compare nanoseconds
      return timestampB.nanoseconds.compareTo(timestampA.nanoseconds);
    });
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final receiptProvider =
          Provider.of<ReceiptProvider>(context, listen: false);

      // Fetch receipts and apply filters initially
      receiptProvider.fetchAllReceipts();

      // Set initial search results - using allReceipts instead of filteredReceipts
      if (mounted) {
        setState(() {
          _currencySymbolToDisplay = receiptProvider.currencySymbolToDisplay!;
          _searchedReceipts =
              List<Map<String, dynamic>>.from(receiptProvider.allReceipts);
          // Sort by timestamp (newest first)
          _sortReceiptsByTimestamp(_searchedReceipts);

          // Apply Day filter by default
          _applyDateFilter('Day');
        });
      }
    });

    // Add listener to update receipts dynamically
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);

    _receiptProviderListener = () {
      if (mounted) {
        setState(() {
          // Use allReceipts instead of filteredReceipts
          _searchedReceipts =
              List<Map<String, dynamic>>.from(receiptProvider.allReceipts);
          // Sort by timestamp (newest first)
          _sortReceiptsByTimestamp(_searchedReceipts);

          // Apply search filtering if there's a search query
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }

          // Apply date filter
          _applyDateFilter(_activeFilter);
        });
      }
    };

    receiptProvider.addListener(_receiptProviderListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures the page refreshes data when it becomes visible again
    // but only when it's actually needed (not on every rebuild)
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);

    // Only refresh if we have no receipts yet or if we're coming back to this page
    if (_searchedReceipts.isEmpty ||
        ModalRoute.of(context)?.isCurrent == true) {
      receiptProvider.fetchAllReceipts().then((_) {
        if (mounted) {
          setState(() {
            _currencySymbolToDisplay = receiptProvider.currencySymbolToDisplay!;

            // Get all receipts and sort them by timestamp (newest first)
            _searchedReceipts =
                List<Map<String, dynamic>>.from(receiptProvider.allReceipts);
            _sortReceiptsByTimestamp(_searchedReceipts);

            // Apply search filtering if there's a search query
            if (_searchController.text.isNotEmpty) {
              _performSearch(_searchController.text);
            }

            // Apply date filter
            _applyDateFilter(_activeFilter);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // Remove the listener to prevent calls after dispose
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);
    receiptProvider.removeListener(_receiptProviderListener);

    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Builds each receipt section
  Widget _buildReceiptSection(
    BuildContext context, {
    required String sectionTitle,
    required List<Map<String, dynamic>> receipts,
  }) {
    return receipts.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  sectionTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2646),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...receipts.map((receipt) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ExpenseItem(
                      categoryIcon: receipt['categoryIcon'] ?? Icons.category,
                      categoryName:
                          receipt['categoryName'] ?? 'Unknown Category',
                      categoryColor:
                          receipt['categoryColor'] ?? Colors.grey.shade200,
                      merchantName: receipt['merchant'] ?? 'Unknown Merchant',
                      receiptDate: receipt['date'] != null
                          ? DateFormat('MMM d, yyyy')
                              .format((receipt['date'] as Timestamp).toDate())
                          : 'Unknown',
                      currencySymbol: _currencySymbolToDisplay,
                      amount: receipt['amountToDisplay'].toStringAsFixed(2),
                      paymentMethod:
                          receipt['paymentMethod'] ?? 'Unknown Payment Method',
                      itemName: receipt['itemName'] ?? receipt['merchant'],
                      receiptId: receipt['id'],
                      isQuickAdd: receipt['isQuickAdd'] ?? false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddOrUpdateReceiptPage(
                              existingReceipt: receipt,
                              receiptId: receipt['id'],
                            ),
                          ),
                        ).then((_) {
                          Provider.of<ReceiptProvider>(context, listen: false)
                              .fetchAllReceipts();
                        });
                      },
                    ),
                  )),
            ],
          )
        : const SizedBox.shrink();
  }

  Widget buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 80,
            color: purple80,
          ),
          const SizedBox(height: 20),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Try adjusting your search and filters to find what you are looking for.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simplified search method without filters
  void _performSearch(String query) {
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);

    // Get all receipts
    final allReceipts = receiptProvider.allReceipts;

    setState(() {
      final lowerCaseQuery = query.toLowerCase();

      // Filter receipts based on search query
      if (query.isEmpty) {
        // If no query, show all receipts
        _searchedReceipts = List<Map<String, dynamic>>.from(allReceipts);
      } else {
        // Otherwise, filter based on query
        _searchedReceipts = allReceipts.where((receipt) {
          // Check common searchable fields
          if (receipt['merchant']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerCaseQuery) ==
              true) {
            return true;
          }

          if (receipt['itemName']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerCaseQuery) ==
              true) {
            return true;
          }

          if (receipt['categoryName']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerCaseQuery) ==
              true) {
            return true;
          }

          if (receipt['paymentMethod']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerCaseQuery) ==
              true) {
            return true;
          }

          if (receipt['description']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerCaseQuery) ==
              true) {
            return true;
          }

          // Check amount
          if (receipt['amountToDisplay'] is num) {
            if (receipt['amountToDisplay']
                .toStringAsFixed(2)
                .contains(lowerCaseQuery)) {
              return true;
            }
          }

          // Check date
          if (receipt['date'] is Timestamp) {
            final date = (receipt['date'] as Timestamp).toDate();
            final formattedDate =
                "${date.day} ${DateFormat.MMMM().format(date)} ${date.year}";
            if (formattedDate.toLowerCase().contains(lowerCaseQuery)) {
              return true;
            }
          }

          return false;
        }).toList();
      }

      // Sort by timestamp (newest first)
      _sortReceiptsByTimestamp(_searchedReceipts);

      // Only apply date filter if there's no search query
      if (query.isEmpty) {
        _applyDateFilter(_activeFilter);
      }
    });
  }

  // Apply date filter based on selected filter
  void _applyDateFilter(String filter) {
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);
    final allReceipts = _searchController.text.isEmpty
        ? List<Map<String, dynamic>>.from(receiptProvider.allReceipts)
        : _searchedReceipts;

    setState(() {
      _activeFilter = filter;

      // If there's an active search, don't apply date filter
      if (_searchController.text.isNotEmpty) {
        return;
      }

      if (filter == 'All') {
        // No date filtering needed
        if (_searchController.text.isEmpty) {
          _searchedReceipts =
              List<Map<String, dynamic>>.from(receiptProvider.allReceipts);
        }
        return;
      }

      final now = DateTime.now();
      DateTime startDate;

      switch (filter) {
        case 'Day':
          // Current day (today)
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Week':
          // Past 7 days including today
          startDate = now.subtract(Duration(days: 6));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'Month':
          // Current month
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'Year':
          // Current year
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          return;
      }

      // Filter receipts by date
      _searchedReceipts = allReceipts.where((receipt) {
        if (receipt['date'] is Timestamp) {
          final receiptDate = (receipt['date'] as Timestamp).toDate();
          return receiptDate.isAfter(startDate) ||
              receiptDate.isAtSameMomentAs(startDate);
        }
        return false;
      }).toList();

      // Sort filtered receipts
      _sortReceiptsByTimestamp(_searchedReceipts);
    });
  }

  // Build date filter buttons
  Widget _buildDateFilterButtons() {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ['Day', 'Week', 'Month', 'Year'].map((filter) {
          final isSelected = _activeFilter == filter;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  _applyDateFilter(filter);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? purple80 : Colors.white,
                  foregroundColor: isSelected ? Colors.white : purple80,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: purple80),
                  ),
                  elevation: isSelected ? 2 : 0,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Simple search bar without filters
  Widget _buildSearchBarWithChips(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: purple80,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                hintText: 'Search transactions...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Color(0xFF2C2646), fontSize: 14),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(color: Color(0xFF2C2646), fontSize: 14),
              onChanged: (query) {
                _performSearch(query);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Add new method to calculate spending by date
  List<FlSpot> _calculateSpendingByDate(List<Map<String, dynamic>> receipts) {
    // Create a map to store total spending for each date
    Map<DateTime, double> spendingByDate = {};

    // Process each receipt
    for (var receipt in receipts) {
      if (receipt['date'] is Timestamp) {
        DateTime date = (receipt['date'] as Timestamp).toDate();

        // If Day filter is active, keep exact hour and minute
        if (_activeFilter == 'Day') {
          // Keep exact hour and minute for day view
          date =
              DateTime(date.year, date.month, date.day, date.hour, date.minute);
        } else {
          // For other filters, normalize to start of day
          date = DateTime(date.year, date.month, date.day);
        }

        double amount = (receipt['amountToDisplay'] as num).toDouble();
        spendingByDate[date] = (spendingByDate[date] ?? 0) + amount;
      }
    }

    // Convert to list of FlSpot points
    List<FlSpot> spots = [];

    // Sort dates in ascending order (earliest first)
    var sortedDates = spendingByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    // For Day filter, ensure we show all transactions of the current day
    if (_activeFilter == 'Day') {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Filter to only include transactions from current day
      sortedDates = sortedDates
          .where((date) =>
              date.isAfter(startOfDay.subtract(const Duration(minutes: 1))) &&
              date.isBefore(endOfDay.add(const Duration(minutes: 1))))
          .toList();
    }

    // For Month filter, ensure we're only showing current month's transactions
    if (_activeFilter == 'Month') {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      sortedDates = sortedDates
          .where((date) =>
              date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
              date.isBefore(lastDayOfMonth.add(const Duration(days: 1))))
          .toList();
    }

    // Add spots in chronological order
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), spendingByDate[sortedDates[i]]!));
    }

    return spots;
  }

  // Add new method to build line chart
  Widget _buildLineChart(List<Map<String, dynamic>> receipts) {
    if (receipts.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = _calculateSpendingByDate(receipts);
    if (spots.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find max amount for scaling
    final maxAmount =
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    // Create a sorted list of receipts by date for proper tooltip mapping
    final sortedReceipts = List<Map<String, dynamic>>.from(receipts)
      ..sort((a, b) {
        final dateA = (a['date'] as Timestamp).toDate();
        final dateB = (b['date'] as Timestamp).toDate();
        return dateA.compareTo(dateB);
      });

    return Container(
      height: 300,
      padding: const EdgeInsets.only(left: 4, right: 16, top: 16, bottom: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxAmount / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval:
                    spots.length > 5 ? (spots.length / 5).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < sortedReceipts.length) {
                    final date =
                        (sortedReceipts[value.toInt()]['date'] as Timestamp)
                            .toDate();
                    String label;
                    if (_activeFilter == 'Day') {
                      // Show hour and minute for Day filter
                      label =
                          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                    } else if (_activeFilter == 'Month') {
                      // Show day number for Month filter
                      label = '${date.day}';
                    } else {
                      // Show date for other filters
                      label = DateFormat('MM/dd').format(date);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${_currencySymbolToDisplay}${value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: maxAmount * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final date =
                      (sortedReceipts[barSpot.x.toInt()]['date'] as Timestamp)
                          .toDate();
                  String dateStr;
                  if (_activeFilter == 'Day') {
                    // Show hour and minute for Day filter
                    dateStr =
                        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                  } else if (_activeFilter == 'Month') {
                    dateStr = 'Day ${date.day}';
                  } else {
                    dateStr = DateFormat('MM/dd/yyyy').format(date);
                  }
                  return LineTooltipItem(
                    '$dateStr\n${_currencySymbolToDisplay}${barSpot.y.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: light90,
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: TextStyle(
            color: Color(0xFF2C2646),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: light90,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh the data
          final receiptProvider =
              Provider.of<ReceiptProvider>(context, listen: false);
          await receiptProvider.fetchAllReceipts();
          if (mounted) {
            setState(() {
              _searchedReceipts =
                  List<Map<String, dynamic>>.from(receiptProvider.allReceipts);
              // Sort by timestamp (newest first)
              _sortReceiptsByTimestamp(_searchedReceipts);

              // Apply search filtering if there's a search query
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }

              // Apply date filter
              _applyDateFilter(_activeFilter);
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBarWithChips(context),
              const SizedBox(height: 16),
              _buildDateFilterButtons(),
              const SizedBox(height: 16),
              if (_searchedReceipts.isNotEmpty)
                _buildLineChart(_searchedReceipts),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<ReceiptProvider>(
                  builder: (context, receiptProvider, _) {
                    if (_searchedReceipts.isEmpty) {
                      return buildNoResultsFound();
                    }
                    return ListView(
                      children: [
                        _buildReceiptSection(
                          context,
                          sectionTitle: 'Transaction History',
                          receipts: _searchedReceipts,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
