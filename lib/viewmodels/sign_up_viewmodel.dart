import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/auth_service.dart';

class SignUpViewModel extends ChangeNotifier {
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _authService = AuthService();
  final _userRepository = UserRepository();
  bool isLoading = false;
  String? errorMessage;

  Future<bool> createProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userId = await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      await _userRepository.createUser(User(
        id: userId,
        name: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        username: usernameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
      ));
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = switch (e.code) {
        'email-already-in-use' => 'An account already uses this email address.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' => 'Use a password with at least 6 characters.',
        'network-request-failed' => 'No internet connection.',
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
