import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/auth_repository.dart';
import 'package:plansync/model/models/auth_failure.dart';
import 'package:plansync/model/models/offline_exception.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final _authRepository = AuthRepository();

  bool isLoading = false;
  String? errorMessage;
  bool emailSent = false;

  static const _notSent =
      "We couldn't send the reset email. Try again in a few minutes.";

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      errorMessage = 'Enter your email address.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.sendPasswordResetEmail(email: email);
      emailSent = true;
    } on OfflineException {
      errorMessage = "You're offline. Connect to send the reset email.";
    } on TimeoutException {
      errorMessage = 'The connection is too slow to send the email. Try again.';
    } on AuthFailure catch (e) {
      errorMessage = switch (e.error) {
        AuthError.userNotFound => 'No account found with that email.',
        AuthError.invalidEmail => 'Enter a valid email address.',
        AuthError.network =>
          "We couldn't reach the server. Check your connection and try again.",
        _ => _notSent,
      };
    } catch (_) {
      errorMessage = _notSent;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
