import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/auth_repository.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
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
  final _connectivity = ConnectivityRepository.instance;
  late final StreamSubscription<bool> _connectivitySubscription;
  bool isLoading = false;
  late bool isOnline;
  String? _errorMessage;
  String? _createdUserId;

  String? get errorMessage =>
      isOnline ? _errorMessage : 'Creating an account needs a connection.';

  SignUpViewModel() {
    isOnline = _connectivity.isOnline;
    _connectivitySubscription = _connectivity.changes.listen((online) {
      isOnline = online;
      if (online &&
          _errorMessage == 'Creating an account needs a connection.') {
        _errorMessage = null;
      }
      notifyListeners();
    });
  }

  Future<bool> createProfile() async {
    if (!_connectivity.isOnline) {
      isOnline = false;
      _errorMessage = 'Creating an account needs a connection.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _createdUserId ??= await _authRepository.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      await _userRepository
          .createUser(
            User(
              id: userId,
              name: nameController.text.trim(),
              lastName: lastNameController.text.trim(),
              username: usernameController.text.trim(),
              phone: phoneController.text.trim(),
              email: emailController.text.trim(),
            ),
          )
          .timeout(const Duration(seconds: 8));
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = switch (e.error) {
        AuthError.emailAlreadyInUse =>
          'An account already uses this email address.',
        AuthError.invalidEmail => 'Enter a valid email address.',
        AuthError.weakPassword => 'Use a password with at least 8 characters.',
        AuthError.network => 'No internet connection.',
        _ => 'Could not create your profile. Try again.',
      };
      return false;
    } catch (_) {
      _errorMessage = _connectivity.isOnline
          ? 'Could not save your profile. Try again.'
          : 'Creating an account needs a connection.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    nameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
