import 'package:flutter/material.dart';
import 'package:plansync/data/expense_repository.dart';
import 'package:plansync/models/expense.dart';
import 'package:plansync/models/user.dart';

class CreateEditExpenseViewModel extends ChangeNotifier {
  CreateEditExpenseViewModel(this._planId, this.participants, String payerId)
    : paidById = participants.any((p) => p.id == payerId)
          ? payerId
          : participants.first.id;

  final String _planId;
  final List<User> participants;
  final _repository = ExpenseRepository();

  final nameController = TextEditingController();
  final valueController = TextEditingController();

  String paidById;

  bool isLoading = false;
  String? errorMessage;

  void selectPayer(String? userId) {
    if (userId == null) return;
    paidById = userId;
    notifyListeners();
  }

  Future<bool> save() async {
    final value = double.tryParse(valueController.text.trim());
    if (nameController.text.trim().isEmpty) {
      errorMessage = 'Name is required.';
      notifyListeners();
      return false;
    }
    if (value == null || value <= 0) {
      errorMessage = 'Enter a valid value.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final expense = Expense(
        id: '',
        name: nameController.text.trim(),
        value: value,
        paidById: paidById,
        createdAt: DateTime.now(),
      );
      await _repository.create(_planId, expense);
      return true;
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    valueController.dispose();
    super.dispose();
  }
}
