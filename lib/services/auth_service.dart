import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception(
              'No user found for that email. Please check your credentials.');
        case 'wrong-password':
          throw Exception('Wrong password provided. Please try again.');
        case 'invalid-email':
          throw Exception(
              'The email address is invalid. Please check your email format.');
        case 'user-disabled':
          throw Exception(
              'This user has been disabled. Please contact support.');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later.');
        case 'network-request-failed':
          throw Exception(
              'Network request failed. Please check your internet connection.');
        default:
          throw Exception('Login failed: ${e.message} (${e.code})');
      }
    } catch (e) {
      throw Exception(
          'An unexpected error occurred during login: ${e.toString()}');
    }
  }

  static Future<void> register(
      String email, String password, String firstName, String lastName) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName('$firstName $lastName');

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
              'This email is already in use. Please use a different email.');
        case 'weak-password':
          throw Exception(
              'The password provided is too weak. Please choose a stronger password.');
        case 'invalid-email':
          throw Exception(
              'The email address is invalid. Please use a valid email.');
        default:
          throw Exception('Registration failed: ${e.message} (${e.code})');
      }
    } catch (e) {
      throw Exception(
          'An unexpected error occurred during registration: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    try {
      await _auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    } catch (e) {
      throw Exception('Failed to log out: ${e.toString()}');
    }
  }

  static User? get currentUser {
    return _auth.currentUser;
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception(
              'The email address is invalid. Please check your email.');
        case 'user-not-found':
          throw Exception(
              'No user found for that email. Please check your email.');
        case 'too-many-requests':
          throw Exception('Too many requests. Please try again later.');
        default:
          throw Exception(
              'Failed to send password reset email: ${e.message} (${e.code})');
      }
    } catch (e) {
      throw Exception(
          'An unexpected error occurred while resetting the password: ${e.toString()}');
    }
  }

  static Future<void> reauthenticateUser(String email, String password) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No user logged in.');
      }

      final AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('The password is incorrect.');
      } else if (e.code == 'user-not-found') {
        throw Exception('No user found with this email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is invalid.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Too many requests. Please try again later.');
      } else {
        throw Exception('Failed to reauthenticate: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error occurred: ${e.toString()}');
    }
  }

  static Future<void> changePassword(String newPassword,
      GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
              content: Text('No user logged in. Please log in first.')),
        );
        throw Exception('No user logged in.');
      }
      if (!isValidPassword(newPassword)) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
              content: Text('The new password is not strong enough.')),
        );
        throw Exception('The new password is not strong enough.');
      }

      await user.updatePassword(newPassword);

      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to change password';
      if (e.code == 'weak-password') {
        errorMessage = 'The new password is too weak.';
      } else {
        errorMessage = 'Error: ${e.message}';
      }

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );

      throw Exception(errorMessage);
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Unexpected error occurred: ${e.toString()}')),
      );

      throw Exception(
          'Unexpected error occurred while changing the password: ${e.toString()}');
    }
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
