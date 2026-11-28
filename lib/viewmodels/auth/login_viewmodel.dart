import 'package:flutter/material.dart';
import 'package:plansync/model/data/auth_repository.dart';
import 'package:plansync/model/logic/validators.dart';
import 'package:plansync/model/models/auth_failure.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel() {
    emailController.addListener(notifyListeners);
    passwordController.addListener(notifyListeners);
  }

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

  String? get loginHint =>
      validateEmail(emailController.text) ??
      (passwordController.text.isEmpty ? 'Password is required.' : null);

  bool get canLogin => loginHint == null;

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
