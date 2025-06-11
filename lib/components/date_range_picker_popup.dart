import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/receipt_provider.dart';
import 'custom_button.dart';
import 'custom_divider.dart';
import 'custom_option_widget.dart';

class CalendarFilterWidget extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime, DateTime) onApply;

  const CalendarFilterWidget({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onApply,
  });

  @override
  CalendarFilterWidgetState createState() => CalendarFilterWidgetState();
}

class CalendarFilterWidgetState extends State<CalendarFilterWidget> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedDays = 90;

  late VoidCallback _receiptProviderListener;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;

    // Initialize ReceiptProvider and listen for updates
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);
    receiptProvider
        .loadOldestAndNewestDates(); // Ensure oldest and newest dates are loaded

    // Add listener to update dates dynamically when provider changes
    _receiptProviderListener = () {
      if (_selectedDays == -1) {
        // Update only if "All History" is selected
        if (mounted) {
          setState(() {
            _startDate = receiptProvider.oldestDate;
            _endDate = receiptProvider.newestDate;
          });
        }
      }
    };
    receiptProvider.addListener(_receiptProviderListener);

    _initializeDates(receiptProvider);
  }

  @override
  void dispose() {
    // Remove the listener
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);
    receiptProvider.removeListener(_receiptProviderListener);

    super.dispose();
  }

  void _initializeDates(ReceiptProvider receiptProvider) {
    final oldestDate = receiptProvider.oldestDate;
    final newestDate = receiptProvider.newestDate;

    setState(() {
      _startDate ??= oldestDate;
      _endDate ??= newestDate;

      // Dynamically set _selectedDays based on the initial dates
      if (_startDate == oldestDate && _endDate == newestDate) {
        _selectedDays = -1; // All History
      } else if (_isCurrentYear()) {
        _selectedDays = -2; // Current Year
      } else if (_isCurrentMonth()) {
        _selectedDays = -3; // Current Month
      } else if (_startDate != null && _endDate != null) {
        _selectedDays = _endDate!.difference(_startDate!).inDays;
      }
    });
  }

  bool _isCurrentYear() {
    final now = DateTime.now();
    return _startDate?.year == now.year &&
        _startDate?.month == 1 &&
        _startDate?.day == 1 &&
        _endDate?.year == now.year;
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _startDate?.year == now.year &&
        _startDate?.month == now.month &&
        _startDate?.day == 1 &&
        _endDate?.year == now.year &&
        _endDate?.month == now.month;
  }

  void _updateRange(int days) {
    setState(() {
      _selectedDays = days;
      if (_endDate != null) {
        _startDate = _endDate!.subtract(Duration(days: days));
      } else if (_startDate != null) {
        _endDate = _startDate!.add(Duration(days: days));
      }
    });
  }

  Future<void> _updateSpecialRange(String option) async {
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);
    final oldestDate = receiptProvider.oldestDate;
    final newestDate = receiptProvider.newestDate;

    setState(() {
      final now = DateTime.now();
      switch (option) {
        case 'Current Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, now.month, now.day);
          _selectedDays = -2; // Distinct value for Current Year
          break;
        case 'Current Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month, now.day);
          _selectedDays = -3; // Distinct value for Current Month
          break;
        case 'All History':
          _startDate = oldestDate;
          _endDate = newestDate;
          _selectedDays = -1; // Distinct value for All History
          break;
      }
    });
  }

  Future<void> _showRollingDatePicker(
      BuildContext context, bool isStartDate) async {
    DateTime initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());
    DateTime maximumDate = DateTime.now();

    if (initialDate.isAfter(maximumDate)) {
      initialDate = maximumDate;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: isStartDate
                      ? DateTime(2000)
                      : (_startDate ?? DateTime(2000)),
                  maximumDate:
                      isStartDate ? _endDate ?? maximumDate : maximumDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      if (isStartDate) {
                        _startDate = newDate;
                      } else {
                        _endDate = newDate;
                      }
                    });
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('DONE', style: TextStyle(color: purple100)),
              ),
            ],
          ),
        );
      },
    );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomDivider(),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              {'label': 'Wk', 'days': 7},
              {'label': '30D', 'days': 30},
              {'label': '90D', 'days': 90},
              {'label': 'Year', 'days': 365}
            ]
                .map((item) => CustomOptionWidget(
                      label: item['label'] as String,
                      isSelected: _selectedDays == item['days'],
                      onSelected: (_) => _updateRange(item['days'] as int),
                    ))
                .toList(),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Current Year', 'Current Month', 'All History']
                .map(
                  (option) => CustomOptionWidget(
                    label: option,
                    isSelected: () {
                      final receiptProvider =
                          Provider.of<ReceiptProvider>(context, listen: false);
                      final oldestDate = receiptProvider.oldestDate;
                      final newestDate = receiptProvider.newestDate;

                      if (option == 'All History') {
                        return _selectedDays == -1 &&
                            _startDate == oldestDate &&
                            _endDate == newestDate;
                      }
                      if (option == 'Current Year') {
                        return _selectedDays == -2 &&
                            _startDate?.month == 1 &&
                            _startDate?.year == DateTime.now().year &&
                            _endDate?.year == DateTime.now().year;
                      }
                      if (option == 'Current Month') {
                        return _selectedDays == -3 &&
                            _startDate?.month == DateTime.now().month &&
                            _startDate?.year == DateTime.now().year &&
                            _endDate?.year == DateTime.now().year;
                      }
                      return false;
                    }(),
                    onSelected: (_) => _updateSpecialRange(option),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDatePickerButton('From', _startDate, true),
              _buildDatePickerButton('To', _endDate, false),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomButton(
                  text: "Cancel",
                  backgroundColor: purple20,
                  textColor: purple100,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: "Apply",
                  backgroundColor: purple100,
                  textColor: light80,
                  onPressed: () {
                    if (_startDate != null && _endDate != null) {
                      widget.onApply(_startDate!, _endDate!);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton(
      String label, DateTime? date, bool isStartDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: dark50)),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showRollingDatePicker(context, isStartDate),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              date != null ? DateFormat.yMMMd().format(date) : 'Select',
              style: TextStyle(fontSize: 16, color: dark50),
            ),
          ),
        ),
      ],
    );
  }
}
