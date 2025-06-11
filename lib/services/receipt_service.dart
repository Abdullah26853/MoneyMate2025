import 'package:cloud_firestore/cloud_firestore.dart';

import '../logger.dart';

class ReceiptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> fetchReceipts(
      String email) async* {
    DocumentReference<Map<String, dynamic>> docRef =
        _firestore.collection('receipts').doc(email);

    DocumentSnapshot<Map<String, dynamic>> docSnapshot = await docRef.get();
    logger.i("Checking existence of document for email: $email");

    if (!docSnapshot.exists) {
      await docRef.set({
        'receiptlist': [],
        'receiptCount': 0,
      });
      logger.i(
          "Document created for email: $email with empty receiptlist and receiptCount initialized.");
    } else {
      logger.e("Document already exists for email: $email");
    }

    await for (var snapshot in docRef.snapshots()) {
      logger.i("Received snapshot for email: $email");
      logger.i("Snapshot data: ${snapshot.data()}");
      yield snapshot;
    }
  }

  Future<void> addReceipt(
      {required String email,
      required Map<String, dynamic> receiptData}) async {
    try {
      String receiptId = _firestore.collection('receipts').doc().id;
      receiptData['id'] = receiptId;

      DocumentReference userDocRef =
          _firestore.collection('receipts').doc(email);
      await userDocRef.set({
        'receiptlist': FieldValue.arrayUnion([receiptData]),
        'receiptCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Update total spent in budget document
      double amount = (receiptData['amount'] ?? 0.0).toDouble();
      DocumentReference budgetRef = _firestore.collection('budgets').doc(email);

      // Get current budget document
      DocumentSnapshot budgetDoc = await budgetRef.get();

      if (!budgetDoc.exists) {
        // Initialize budget document if it doesn't exist
        await budgetRef.set({
          'monthlyBudget': 0.0,
          'totalSpent': amount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Update total spent
        await budgetRef.update({
          'totalSpent': FieldValue.increment(amount),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      logger.i("Updated total spent for receipt amount: $amount");
    } catch (e) {
      logger.e("Error adding receipt: $e");
      rethrow;
    }
  }

  Future<void> updateReceipt({
    required String email,
    required String receiptId,
    required Map<String, dynamic> updatedData,
    String? paymentMethod,
  }) async {
    DocumentReference userDocRef = _firestore.collection('receipts').doc(email);
    DocumentSnapshot userDoc = await userDocRef.get();

    if (!userDoc.exists) throw Exception('User document not found');

    List<dynamic> receiptList = userDoc['receiptlist'] ?? [];
    int receiptIndex =
        receiptList.indexWhere((receipt) => receipt['id'] == receiptId);

    if (receiptIndex != -1) {
      updatedData['id'] = receiptId;
      if (paymentMethod != null) updatedData['paymentMethod'] = paymentMethod;

      receiptList[receiptIndex] = updatedData;
      await userDocRef.update({'receiptlist': receiptList});
    } else {
      throw Exception('Receipt not found');
    }
  }

  Future<void> deleteReceipt(String email, String receiptId) async {
    DocumentReference userDocRef = _firestore.collection('receipts').doc(email);
    DocumentSnapshot doc = await userDocRef.get();

    if (doc.exists) {
      List<dynamic> receiptList = doc['receiptlist'] ?? [];
      receiptList.removeWhere((receipt) => receipt['id'] == receiptId);
      await userDocRef.update({
        'receiptlist': receiptList,
        'receiptCount': FieldValue.increment(-1)
      });
    }
  }

  Future<void> setReceiptsCategoryToNull(
      String email, String categoryId) async {
    DocumentReference userDocRef = _firestore.collection('receipts').doc(email);
    DocumentSnapshot doc = await userDocRef.get();

    if (doc.exists) {
      List<dynamic> receiptList = doc['receiptlist'] ?? [];
      List<dynamic> updatedReceipts = [];

      for (var receipt in receiptList) {
        if (receipt['categoryId'] == categoryId) receipt['categoryId'] = null;
        updatedReceipts.add(receipt);
      }

      if (updatedReceipts.isNotEmpty) {
        await userDocRef.update({'receiptlist': updatedReceipts});
      }
    }
  }
}
