import 'package:firebase_auth/firebase_auth.dart';

import '../logger.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the currently logged-in user
  static Future<User?> getCurrentUser() async {
    try {
      return _auth.currentUser;
    } catch (e) {
      logger.e("Error fetching user: $e");
      return null;
    }
  }

  // Sign in with email and password
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      logger.e("Error signing in: ${e.message}");
      rethrow; // Rethrow to be caught by the calling function
    }
  }

  // Register with email and password
  static Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      logger.i("User registered: ${userCredential.user?.email}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      logger.e("FirebaseAuthException: ${e.message}");
      rethrow;
    } catch (e) {
      logger.e("Unknown error during registration: $e");
      return null;
    }
  }

  // Sign out the user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      logger.e("Error signing out: $e");
    }
  }

  // Re-authenticate user
  static Future<void> reAuthenticate(String email, String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        logger.w("No user is currently signed in.");
      }
    } catch (e) {
      logger.e("Error re-authenticating user: $e");
    }
  }

  // Delete the user account
  static Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      } else {
        logger.w("No user is currently signed in.");
      }
    } catch (e) {
      logger.e("Error deleting account: $e");
    }
  }

  // Reset password by sending password reset email
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      logger.i("Password reset email sent to $email");
    } catch (e) {
      logger.e("Error sending password reset email: $e");
    }
  }
}
