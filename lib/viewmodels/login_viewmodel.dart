import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plansync/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _authService = AuthService();

  bool obscurePassword = true;
  bool isLoading = false;
  String? errorMessage;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<void> login() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      errorMessage = switch (e.code) {
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
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
    passwordController.dispose();
    super.dispose();
  }
}