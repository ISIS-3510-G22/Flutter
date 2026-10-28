import 'package:flutter/material.dart';
import 'package:plansync/model/data/auth_repository.dart';
import 'package:plansync/model/models/auth_failure.dart';

class LoginViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _authRepository = AuthRepository();

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
      await _authRepository.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } on AuthFailure catch (e) {
      errorMessage = switch (e.error) {
        AuthError.userNotFound ||
        AuthError.invalidCredentials => 'Incorrect email or password.',
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
    passwordController.dispose();
    super.dispose();
  }
}
