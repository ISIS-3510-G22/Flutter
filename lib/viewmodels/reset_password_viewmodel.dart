import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plansync/services/auth_service.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;
  bool emailSent = false;

  Future<void> resetPassword() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      emailSent = true;
    } on FirebaseAuthException catch (e) {
      errorMessage = switch (e.code) {
        'user-not-found' => 'No account found with that email.',
        'invalid-email' => 'Enter a valid email address.',
        'network-request-failed' => 'No internet connection.',
        _ => 'Something went wrong. Try again.',
      };
    }

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
