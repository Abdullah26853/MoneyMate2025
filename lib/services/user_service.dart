import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

import '../logger.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user profile data for a specified user by email
  Stream<DocumentSnapshot<Map<String, dynamic>>> fetchUserProfile(
      String email) {
    // Retrieve the user profile data from Firestore
    return _firestore
        .collection('users')
        .doc(email) // Use provided email as document ID
        .snapshots();
  }

  // Add new user profile with only userName, profileImagePath, and currencyCode
  Future<void> addUserProfile({
    required String email,
    required String userName,
    String profileImagePath = '',
    String currencyCode = '',
  }) async {
    // Reference to the user's document in Firestore using their email as document ID
    DocumentReference userDocRef = _firestore.collection('users').doc(email);

    // Create a new user profile document with the specified fields
    await userDocRef.set({
      'userName': userName,
      'profileImagePath': profileImagePath, // Default empty if not provided
      'currencyCode': currencyCode, // Default empty if not provided
    }, SetOptions(merge: true));
  }

  // Update user profile data with userName, profileImagePath, and currencyCode
  Future<void> updateUserProfile({
    required String email,
    required String userName,
    String? profileImagePath,
    String? currencyCode,
  }) async {
    // Reference to the user's document in Firestore
    final userDocRef = _firestore.collection('users').doc(email);

    // Prepare update data
    final Map<String, dynamic> updateData = {
      'userName': userName,
      if (profileImagePath != null && profileImagePath.isNotEmpty)
        'profileImagePath': profileImagePath,
      if (currencyCode != null && currencyCode.isNotEmpty)
        'currencyCode': currencyCode,
    };

    // Update Firestore document with merge option
    await userDocRef.set(updateData, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchUserProfileOnce(
      String email) async {
    // Reference to the user's document in Firestore
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(email);

    // Fetch the document once
    return await userDocRef.get();
  }

  // Update profile image only - now stores as Base64
  Future<void> updateProfileImage(String email, String localImagePath) async {
    try {
      // Read the image file
      final imageFile = File(localImagePath);
      final imageBytes = await imageFile.readAsBytes();

      // Decode and resize the image
      img.Image? image = img.decodeImage(imageBytes);
      if (image != null) {
        // Resize to a reasonable size (e.g., 200x200)
        image = img.copyResize(image, width: 200, height: 200);

        // Convert to JPEG and then to Base64
        final resizedBytes = img.encodeJpg(image, quality: 85);
        final base64Image = base64Encode(resizedBytes);

        // Update Firestore with the Base64 string
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(email);
        await userDocRef.update({
          'profileImagePath': 'data:image/jpeg;base64,$base64Image',
        });
      }
    } catch (e) {
      logger.e('Error updating profile image: $e');
      throw Exception('Failed to update profile image: $e');
    }
  }

  // Delete the user profile data
  Future<void> deleteUserProfile(String email) async {
    DocumentReference userDocRef = _firestore.collection('users').doc(email);

    await userDocRef.delete();
  }

  // Clear all history: Receipts and Categories associated with the user
  Future<void> clearAllHistory(String email) async {
    // Clear receipts
    await _firestore.collection('receipts').doc(email).update({
      'receiptlist': [], // Clear the array
    });

    // Clear categories
    await _firestore.collection('categories').doc(email).update({
      'categorylist': [], // Clear the array
    });
  }

  // Delete the Firebase Firestore profile, receipts, and categories for a specified email
  Future<void> deleteUser(String email) async {
    try {
      // Delete user profile in Firestore
      await _firestore.collection('users').doc(email).delete();

      // Delete receipts
      await _firestore.collection('receipts').doc(email).delete();

      // Delete categories
      await _firestore.collection('categories').doc(email).delete();

      logger.i('User profile and associated data deleted successfully');
    } catch (e) {
      logger.e("Error deleting user: $e");
    }
  }
}
