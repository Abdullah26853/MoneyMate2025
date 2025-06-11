import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:receipt_manager/providers/category_provider.dart';
import 'package:receipt_manager/providers/receipt_provider.dart';
import 'package:receipt_manager/services/scan_receipts.dart';

import '../components/category_select_popup.dart';
import '../components/currency_roller_picker_popup.dart';
import '../components/custom_button.dart';
import '../components/custom_divider.dart';
import '../components/date_picker_popup.dart';
import '../constants/app_colors.dart';
import '../providers/user_provider.dart';
import '../../logger.dart';
import 'base_page.dart';

class AddOrUpdateReceiptPage extends StatefulWidget {
  static const String id = 'add_update_receipt_page';
  final Map<String, dynamic>? existingReceipt;
  final String? receiptId;
  final Map<String, dynamic>? extract;

  const AddOrUpdateReceiptPage({
    super.key,
    this.existingReceipt,
    this.receiptId,
    this.extract,
  });

  @override
  AddOrUpdateReceiptPageState createState() => AddOrUpdateReceiptPageState();
}

class AddOrUpdateReceiptPageState extends State<AddOrUpdateReceiptPage> {
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();

  List<Map<String, dynamic>> _userCategories = [];
  String? _selectedCategoryId;
  String? _selectedCategoryIcon;
  String? _selectedCategoryName;
  String? _selectedPaymentMethod;
  String? _selectedCurrencyCode;

  String? _uploadedImageUrl;
  XFile? _imageFile;

  // Extraction related fields
  bool _isProcessingImage = false;
  bool _isExtractionDone = false;
  String _extractedText = '';
  String _language = '';
  String _merchantName = '';
  String _receiptDate = '';
  String _currency = '';
  String _totalPrice = '';

  bool _isSaving = false;

  final List<String> _currencyOptions = ['EGP', 'USD', 'EUR'];
  final List<String> _paymentMethods = [
    'Credit Card',
    'Debit Card',
    'Cash',
    'Others',
  ];

  final ScanReceipts _scanReceipts = ScanReceipts();

  @override
  void initState() {
    super.initState();
    _loadUserCategories();
    _initializeFormFields();
    if (_selectedPaymentMethod == null) {
      _selectedPaymentMethod = 'Cash';
    }
  }

  Future<void> _loadUserCategories() async {
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.loadUserCategories();
    setState(() {
      _userCategories = categoryProvider.categories;
    });
  }

  void _initializeFormFields() {
    if (widget.existingReceipt != null) {
      _merchantController.text = widget.existingReceipt!['merchant'] ?? '';
      _selectedPaymentMethod = widget.existingReceipt!['paymentMethod'] ?? '';
      _dateController.text = widget.existingReceipt!['date']
              ?.toDate()
              .toLocal()
              .toString()
              .split(' ')[0] ??
          '';
      _selectedCurrencyCode = widget.existingReceipt!['currencyCode'];
      _totalController.text =
          widget.existingReceipt!['amount']?.toString() ?? '';
      _selectedCategoryId = widget.existingReceipt!['categoryId'];
      _selectedCategoryName = widget.existingReceipt!['categoryName'];
      _selectedCategoryIcon = widget.existingReceipt!['categoryIcon'];
      _itemNameController.text = widget.existingReceipt!['itemName'] ?? '';
      _descriptionController.text =
          widget.existingReceipt!['description'] ?? '';
      if (widget.existingReceipt!['imageUrl'] != null) {
        _uploadedImageUrl = widget.existingReceipt!['imageUrl'];
      }
    } else if (widget.extract != null) {
      // Pre-fill Item Name for both direct scan and extracted data
      _itemNameController.text = "Scanned Receipt";

      if (widget.extract!['isDirectScan'] == true &&
          widget.extract!['imagePath'] != null) {
        _imageFile = XFile(widget.extract!['imagePath']);
        _processImageAndExtractText(File(_imageFile!.path));
      } else {
        _merchantController.text = widget.extract!['merchant'] ?? '';
        _dateController.text = widget.extract!['date'] ??
            DateTime.now().toLocal().toString().split(' ')[0];
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        _selectedCurrencyCode =
            widget.extract!['currency'] ?? userProvider.currencyCode;
        final extractAmount = widget.extract!['amount'] ?? '';
        _totalController.text = extractAmount.toString();
        _imageFile = widget.extract!['imagePath'] != null
            ? XFile(widget.extract!['imagePath'])
            : null;
        _isExtractionDone = true;
      }
    } else {
      _dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _selectedCurrencyCode = userProvider.currencyCode;
    }

    Provider.of<CategoryProvider>(context, listen: false).loadUserCategories();
  }

  Future<void> _processImageAndExtractText(File imageFile) async {
    setState(() {
      _isProcessingImage = true;
    });

    try {
      final result = await _scanReceipts.processReceiptImage(imageFile);

      setState(() {
        _extractedText = result['text'] ?? '';
        _merchantName = result['merchant'] ?? '';
        _receiptDate = result['date'] ?? '';
        _currency = result['currency'] ?? '';
        _totalPrice = result['amount'] ?? '';

        // Populate the form fields with extracted data
        _merchantController.text =
            _merchantName != 'Not Found' ? _merchantName : '';
        _dateController.text = _receiptDate != 'Not Found'
            ? _receiptDate
            : DateTime.now().toLocal().toString().split(' ')[0];
        _totalController.text = _totalPrice != 'Not Found' ? _totalPrice : '';

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        _selectedCurrencyCode =
            _currency != 'Not Found' ? _currency : userProvider.currencyCode;
      });
    } catch (e) {
      logger.e('Error processing image: $e');
    } finally {
      setState(() {
        _isProcessingImage = false;
        _isExtractionDone = true;
      });
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = image;
        _isExtractionDone = false;
      });

      _processImageAndExtractText(File(image.path));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DatePickerPopup(
          initialDate: DateTime.now(),
          onConfirm: (DateTime selectedDate) {
            setState(() {
              _dateController.text = "${selectedDate.toLocal()}".split(' ')[0];
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _saveReceipt() async {
    if (_isSaving) return; // Prevent multiple submissions

    setState(() {
      _isSaving = true; // Disable the save button
    });

    final messenger = ScaffoldMessenger.of(context);
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);

    double? amount =
        double.tryParse(_totalController.text.replaceAll(',', '.'));

    // Check if this is from a scan
    bool isFromScan =
        widget.extract != null && widget.extract!['isDirectScan'] == true;

    // Validate required fields based on whether it's from scan or not
    if (_dateController.text.isEmpty ||
        amount == null ||
        _itemNameController.text.isEmpty ||
        (!isFromScan && _selectedPaymentMethod == null)) {
      messenger.showSnackBar(
        SnackBar(
            content: Text('Please fill in all required fields with * mark')),
      );
      setState(() {
        _isSaving = false; // Re-enable the save button
      });
      return;
    }

    // Parse the date and preserve the current time if today
    Timestamp timestamp;
    if (widget.receiptId != null && widget.existingReceipt != null) {
      // If updating, preserve the original date unless the user changed it
      final originalTimestamp = widget.existingReceipt!['date'] as Timestamp?;
      final originalDate = originalTimestamp?.toDate();
      final pickedDate = DateTime.parse(_dateController.text);
      // If the picked date is different from the original date (ignoring time), update it
      if (originalDate != null &&
          pickedDate.year == originalDate.year &&
          pickedDate.month == originalDate.month &&
          pickedDate.day == originalDate.day) {
        // Date not changed, preserve original timestamp
        timestamp = originalTimestamp!;
      } else {
        // Date changed, use new logic
        final now = DateTime.now();
        DateTime finalDateTime;
        if (pickedDate.year == now.year &&
            pickedDate.month == now.month &&
            pickedDate.day == now.day) {
          finalDateTime = now;
        } else {
          finalDateTime = pickedDate;
        }
        timestamp = Timestamp.fromDate(finalDateTime);
      }
    } else {
      // New receipt logic
      final pickedDate = DateTime.parse(_dateController.text);
      final now = DateTime.now();
      DateTime finalDateTime;
      if (pickedDate.year == now.year &&
          pickedDate.month == now.month &&
          pickedDate.day == now.day) {
        finalDateTime = now;
      } else {
        finalDateTime = pickedDate;
      }
      timestamp = Timestamp.fromDate(finalDateTime);
    }

    Map<String, dynamic> receiptData = {
      'merchant': _merchantController.text,
      'date': timestamp,
      'currencyCode': _selectedCurrencyCode,
      'amount': amount,
      'categoryId': _selectedCategoryId,
      'paymentMethod': _selectedPaymentMethod ?? 'Other',
      'itemName': _itemNameController.text,
      'description': _descriptionController.text,
    };

    try {
      if (widget.receiptId != null) {
        await receiptProvider.updateReceipt(
          receiptId: widget.receiptId!,
          updatedData: receiptData,
        );
        await receiptProvider.fetchAllReceipts(); // Refresh the list
        messenger.showSnackBar(
          SnackBar(content: Text('Receipt updated successfully')),
        );
      } else {
        await receiptProvider.addReceipt(receiptData: receiptData);
        await receiptProvider.fetchAllReceipts(); // Refresh the list
        messenger.showSnackBar(
          SnackBar(content: Text('Receipt saved successfully')),
        );
        _clearForm();
      }

      // Navigate back and refresh the UI
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save receipt. Try again.')),
      );
    }

    setState(() {
      _isSaving = false; // Re-enable the save button
    });
  }

  void _clearForm() {
    setState(() {
      _merchantController.clear();
      _dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
      _totalController.clear();
      _descriptionController.clear();
      _itemNameController.clear();
      _selectedCategoryId = null;
      _selectedPaymentMethod = null;
    });
  }

  Future<void> _confirmDelete() async {
    bool? confirm = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
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
              SizedBox(height: 8),
              Text(
                'Delete Receipt?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Are you sure you want to delete this receipt?',
                style: TextStyle(
                  fontSize: 16,
                  color: purple200,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CustomButton(
                        text: "Cancel",
                        backgroundColor: purple20,
                        textColor: purple100,
                        onPressed: () {
                          Navigator.of(context).pop(false); // Return false
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CustomButton(
                        text: "Delete",
                        backgroundColor: Colors.redAccent,
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.of(context).pop(true); // Return true
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      // Perform delete operation
      await _deleteReceipt();
    }
  }

  Future<void> _deleteReceipt() async {
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);
    if (widget.receiptId != null) {
      await receiptProvider.deleteReceipt(widget.receiptId!);
      Navigator.pushReplacementNamed(context, BasePage.id);
    }
  }

  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: Provider.of<CategoryProvider>(context, listen: false),
          child: CategorySelectPopup(),
        );
      },
    ).then((selectedCategoryId) {
      if (selectedCategoryId != null) {
        final selectedCategory = _userCategories.firstWhere(
          (category) => category['id'] == selectedCategoryId,
          orElse: () => {},
        );

        if (selectedCategory.isNotEmpty) {
          setState(() {
            _selectedCategoryId = selectedCategoryId;
            _selectedCategoryName = selectedCategory['name'];
            _selectedCategoryIcon = selectedCategory['icon'];
          });
        }
      }
    });
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CurrencyPicker(
          selectedCurrencyCode: 'EUR', // Provide a default,
          onCurrencyCodeSelected: (String newCurrencyCode) async {
            // Update the state to reflect the new currency immediately
            setState(() {
              _selectedCurrencyCode = newCurrencyCode;
            });
          },
        );
      },
    );
  }

  InputDecoration buildRequiredFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
      suffixText: '*',
      suffixStyle: TextStyle(color: Colors.red, fontSize: 14),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: purple100, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  InputDecoration buildDynamicLabelDecoration({
    required String label,
    required bool isSelected,
    String? selectedValue,
    bool isRequired = true,
  }) {
    return InputDecoration(
      labelText: isSelected && selectedValue != null ? selectedValue : label,
      labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
      suffixText: isRequired && !isSelected ? '*' : null,
      suffixStyle: TextStyle(color: Colors.red, fontSize: 14),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: purple100, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
    );
  }

  void _showPaymentMethodPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomDivider(),
              SizedBox(height: 16),
              Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              ..._paymentMethods.map((method) {
                final selected = _selectedPaymentMethod == method;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomButton(
                    text: method,
                    backgroundColor: selected ? purple100 : Colors.grey[200]!,
                    textColor: selected ? light80 : Colors.black87,
                    onPressed: () {
                      setState(() {
                        _selectedPaymentMethod = method;
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFromScan =
        widget.extract != null && widget.extract!['isDirectScan'] == true;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.receiptId != null ? 'Update Receipt' : 'Add Receipt',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isExtractionDone &&
                          _imageFile != null &&
                          widget.extract?['isDirectScan'] == true) ...[
                        Container(
                          margin: EdgeInsets.only(bottom: 24),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.08),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Extracted Info',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blue[800])),
                                  Spacer(),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      child: Image.file(File(_imageFile!.path),
                                          fit: BoxFit.cover),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              _buildExtractionInfoRow('Amount:', _totalPrice),
                              _buildExtractionInfoRow('Date:', _receiptDate),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 12),
                      if (isFromScan) ...[
                        Text('Item Name',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _itemNameController,
                          decoration: _modernInputDecoration(''),
                        ),
                        SizedBox(height: 18),
                        Text('Category',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          items: _userCategories
                              .map((cat) => DropdownMenuItem<String>(
                                    value: cat['id']?.toString() ?? '',
                                    child: Row(
                                      children: [
                                        Text(cat['icon'] ?? ''),
                                        SizedBox(width: 8),
                                        Text(cat['name'] ?? ''),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            final selected = _userCategories.firstWhere(
                                (cat) => cat['id'] == val,
                                orElse: () => {});
                            setState(() {
                              _selectedCategoryId = val;
                              _selectedCategoryName = selected['name'];
                              _selectedCategoryIcon = selected['icon'];
                            });
                          },
                          decoration: _modernInputDecoration('Select Category'),
                        ),
                        SizedBox(height: 18),
                        Text('Amount',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _totalController,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: _modernInputDecoration('').copyWith(
                                  suffixIcon: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCurrencyCode ??
                                          _currencyOptions[0],
                                      items: _currencyOptions
                                          .map((currency) => DropdownMenuItem(
                                                value: currency,
                                                child: Text(currency),
                                              ))
                                          .toList(),
                                      onChanged: (val) => setState(
                                          () => _selectedCurrencyCode = val),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18),
                        Text('Date',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          decoration: _modernInputDecoration('').copyWith(
                            suffixIcon: Icon(Icons.calendar_today,
                                color: Colors.grey[500]),
                          ),
                        ),
                        SizedBox(height: 18),
                        Text('Payment Method',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _paymentMethods.take(3).map((method) {
                            final selected = _selectedPaymentMethod == method;
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text(method,
                                      style: TextStyle(fontSize: 13)),
                                  selected: selected,
                                  onSelected: (_) => setState(
                                      () => _selectedPaymentMethod = method),
                                  selectedColor: purple100,
                                  backgroundColor: Colors.grey[100],
                                  labelStyle: TextStyle(
                                    color:
                                        selected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  shape: StadiumBorder(),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        // Original form fields for manual entry
                        SizedBox(height: 12),
                        Text('Item Name',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _itemNameController,
                          decoration: _modernInputDecoration('Item Name'),
                        ),
                        SizedBox(height: 18),
                        Text('Amount',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _totalController,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: _modernInputDecoration('').copyWith(
                                  suffixIcon: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCurrencyCode ??
                                          _currencyOptions[0],
                                      items: _currencyOptions
                                          .map((currency) => DropdownMenuItem(
                                                value: currency,
                                                child: Text(currency),
                                              ))
                                          .toList(),
                                      onChanged: (val) => setState(
                                          () => _selectedCurrencyCode = val),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18),
                        Text('Category',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          items: _userCategories
                              .map((cat) => DropdownMenuItem<String>(
                                    value: cat['id']?.toString() ?? '',
                                    child: Row(
                                      children: [
                                        Text(cat['icon'] ?? ''),
                                        SizedBox(width: 8),
                                        Text(cat['name'] ?? ''),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            final selected = _userCategories.firstWhere(
                                (cat) => cat['id'] == val,
                                orElse: () => {});
                            setState(() {
                              _selectedCategoryId = val;
                              _selectedCategoryName = selected['name'];
                              _selectedCategoryIcon = selected['icon'];
                            });
                          },
                          decoration: _modernInputDecoration('Select Category'),
                        ),
                        SizedBox(height: 18),
                        Text('Merchant',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _merchantController,
                          decoration: _modernInputDecoration('Merchant'),
                        ),
                        SizedBox(height: 18),
                        Text('Date',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          decoration: _modernInputDecoration('').copyWith(
                            suffixIcon: Icon(Icons.calendar_today,
                                color: Colors.grey[500]),
                          ),
                        ),
                        SizedBox(height: 18),
                        Text('Payment Method',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _paymentMethods.take(3).map((method) {
                            final selected = _selectedPaymentMethod == method;
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text(method,
                                      style: TextStyle(fontSize: 13)),
                                  selected: selected,
                                  onSelected: (_) => setState(
                                      () => _selectedPaymentMethod = method),
                                  selectedColor: purple100,
                                  backgroundColor: Colors.grey[100],
                                  labelStyle: TextStyle(
                                    color:
                                        selected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  shape: StadiumBorder(),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 18),
                        Text('Description',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration:
                              _modernInputDecoration('Add a note (optional)'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              if (widget.receiptId != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveReceipt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple100,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Update',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmDelete,
                        icon: Icon(Icons.delete_outline, color: Colors.white),
                        label: Text('Delete',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.receiptId == null) ...[
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveReceipt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple100,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Save',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildExtractionInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value == 'Not Found' ? 'Not detected' : value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
