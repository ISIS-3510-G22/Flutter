import 'package:flutter/material.dart';
import 'package:plansync/model/data/auth_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/auth_failure.dart';
import 'package:plansync/model/models/user.dart';

class SignUpViewModel extends ChangeNotifier {
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();
  bool isLoading = false;
  String? errorMessage;

  Future<bool> createProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userId = await _authRepository.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      await _userRepository.createUser(
        User(
          id: userId,
          name: nameController.text.trim(),
          lastName: lastNameController.text.trim(),
          username: usernameController.text.trim(),
          phone: phoneController.text.trim(),
          email: emailController.text.trim(),
        ),
      );
      return true;
    } on AuthFailure catch (e) {
      errorMessage = switch (e.error) {
        AuthError.emailAlreadyInUse =>
          'An account already uses this email address.',
        AuthError.invalidEmail => 'Enter a valid email address.',
        AuthError.weakPassword => 'Use a password with at least 8 characters.',
        AuthError.network => 'No internet connection.',
        _ => 'Could not create your profile. Try again.',
      };
      return false;
    } catch (_) {
      errorMessage = 'Could not save your profile. Try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
