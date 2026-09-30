import 'package:flutter/material.dart';
import 'package:plansync/data/expense_repository.dart';
import 'package:plansync/models/expense.dart';
import 'package:plansync/models/user.dart';

class CreateEditExpenseViewModel extends ChangeNotifier {
  CreateEditExpenseViewModel(
    this._planId,
    this.participants,
    String payerId, [
    this._editingExpense,
  ]) : paidById = participants.any((p) => p.id == payerId)
           ? payerId
           : participants.first.id {
    if (_editingExpense case final expense?) {
      nameController.text = expense.name;
      valueController.text = expense.value % 1 == 0
          ? expense.value.toStringAsFixed(0)
          : expense.value.toString();
    }
  }

  final String _planId;
  final List<User> participants;
  final _repository = ExpenseRepository();
  final Expense? _editingExpense;

  bool get isEditing => _editingExpense != null;

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
        id: _editingExpense?.id ?? '',
        name: nameController.text.trim(),
        value: value,
        paidById: paidById,
        createdAt: _editingExpense?.createdAt ?? DateTime.now(),
      );
      if (_editingExpense == null) {
        await _repository.create(_planId, expense);
      } else {
        await _repository.update(_planId, expense);
      }
      return true;
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> delete() async {
    final expense = _editingExpense;
    if (expense == null) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.delete(_planId, expense.id);
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
