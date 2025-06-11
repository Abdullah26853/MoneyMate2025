import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import 'authentication_provider.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  AuthenticationProvider? _authProvider; // Reference to AuthenticationProvider

  DocumentSnapshot<Map<String, dynamic>>? _userProfile;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;

  DocumentSnapshot<Map<String, dynamic>>? get userProfile => _userProfile;

  // Inject AuthenticationProvider through a setter
  set authProvider(AuthenticationProvider authProvider) {
    _authProvider = authProvider;
    notifyListeners(); // Notify listeners in case of authentication changes
  }

  // Helper to get user email from AuthenticationProvider
  String? get _userEmail => _authProvider?.user?.email;

  // Getter for userName
  String? get userName => _userProfile?.data()?['userName'];
  // Getter for profileImagePath
  String? get profileImagePath => _userProfile?.data()?['profileImagePath'];
  // Getter for currencyCode
  String? get currencyCode => _userProfile?.data()?['currencyCode'];

  // Fetch user profile data and listen for updates
  void fetchUserProfile() {
    if (_userEmail != null) {
      _profileStream?.cancel(); // Cancel any existing stream
      _profileStream =
          _userService.fetchUserProfile(_userEmail!).listen((snapshot) {
        if (_authProvider?.isAuthenticated ?? false) {
          // Ensure user is logged in
          _userProfile = snapshot;
          notifyListeners();
        }
      });
    }
  }

  // Clear user profile data and cancel the stream
  void clearUserProfile() {
    _profileStream?.cancel();
    _profileStream = null;
    _userProfile = null;
    notifyListeners();
  }

  // Add a new user profile
  Future<void> addUserProfile({
    required String userName,
    String profileImagePath = '',
    String currencyCode = '',
  }) async {
    if (_userEmail != null) {
      await _userService.addUserProfile(
        email: _userEmail!,
        userName: userName,
        profileImagePath: profileImagePath,
        currencyCode: currencyCode,
      );
      notifyListeners();
    }
  }

  // Update user profile with all fields
  Future<void> updateUserProfile({
    String? userName,
    String? profileImagePath,
    String? currencyCode,
  }) async {
    if (_userEmail != null) {
      await _userService.updateUserProfile(
        email: _userEmail!,
        userName: userName ?? this.userName ?? '',
        profileImagePath: profileImagePath ?? this.profileImagePath ?? '',
        currencyCode: currencyCode ?? this.currencyCode ?? '',
      );

      // Refresh local data
      _userProfile = await _userService.fetchUserProfileOnce(_userEmail!);

      notifyListeners();
    }
  }

  // Update profile image only
  Future<void> updateProfileImage(String localImagePath) async {
    if (_userEmail != null) {
      try {
        // Update the profile image in the backend
        await _userService.updateProfileImage(_userEmail!, localImagePath);

        // Fetch the updated profile to refresh local data
        _userProfile = await _userService.fetchUserProfileOnce(_userEmail!);

        notifyListeners();
      } catch (e) {
        throw Exception('Failed to update profile image: $e');
      }
    }
  }

  // Clear all user history
  Future<void> clearAllHistory() async {
    if (_userEmail != null) {
      await _userService.clearAllHistory(_userEmail!);
      notifyListeners();
    }
  }

  // Delete user profile and associated data
  Future<void> deleteUser() async {
    if (_userEmail != null) {
      await _userService.deleteUser(_userEmail!);
      _userProfile = null;
      notifyListeners();
    }
  }
}
