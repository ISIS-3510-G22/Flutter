import 'package:flutter/material.dart';
import 'package:plansync/model/data/auth_repository.dart';
import 'package:plansync/model/models/auth_failure.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final _authRepository = AuthRepository();

  bool isLoading = false;
  String? errorMessage;
  bool emailSent = false;

  Future<void> resetPassword() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      emailSent = true;
    } on AuthFailure catch (e) {
      errorMessage = switch (e.error) {
        AuthError.userNotFound => 'No account found with that email.',
        AuthError.invalidEmail => 'Enter a valid email address.',
        AuthError.network => 'No internet connection.',
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
