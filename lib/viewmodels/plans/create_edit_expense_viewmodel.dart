import 'package:flutter/material.dart';
import 'package:plansync/model/data/expense_repository.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/user.dart';

class CreateEditExpenseViewModel extends ChangeNotifier {
  CreateEditExpenseViewModel(
    this._planId,
    this.participants,
    String payerId, [
    this._editingExpense,
  ]) : paidById = participants.any((p) => p.id == payerId)
           ? payerId
           : participants.first.id {
    splitAmongIds = participants.map((p) => p.id).toSet();
    if (_editingExpense case final expense?) {
      nameController.text = expense.name;
      valueController.text = expense.value % 1 == 0
          ? expense.value.toStringAsFixed(0)
          : expense.value.toString();
      if (expense.splitAmongIds.isNotEmpty) {
        splitAmongIds = expense.splitAmongIds.toSet();
      }
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
  Set<String> splitAmongIds = {};

  bool isLoading = false;
  String? errorMessage;

  /// Set when the last save or delete was kept on the phone (queued), for
  /// the snackbar the form shows as it closes. `null` when it was sent.
  String? queuedMessage;

  bool get isForEveryone =>
      participants.every((p) => splitAmongIds.contains(p.id));

  void selectPayer(String? userId) {
    if (userId == null) return;
    paidById = userId;
    notifyListeners();
  }

  void toggleEveryone(bool everyone) {
    if (everyone) {
      splitAmongIds = participants.map((p) => p.id).toSet();
    } else {
      splitAmongIds = {};
    }
    notifyListeners();
  }

  void toggleParticipant(String userId) {
    if (splitAmongIds.contains(userId)) {
      splitAmongIds.remove(userId);
    } else {
      splitAmongIds.add(userId);
    }
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
    if (splitAmongIds.isEmpty) {
      errorMessage = 'Select at least one person.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      var id = _repository.newId(_planId);
      var createdAt = DateTime.now();
      if (_editingExpense case final editing?) {
        id = editing.id;
        createdAt = editing.createdAt;
      }
      final expense = Expense(
        id: id,
        name: nameController.text.trim(),
        value: value,
        paidById: paidById,
        createdAt: createdAt,
        splitAmongIds: splitAmongIds.toList(),
      );
      // The form waits (it closes afterwards), so `await`: at most the 8 s
      // send timeout online, instantly offline.
      final sent = await _repository.save(
        _planId,
        expense,
        isNew: _editingExpense == null,
      );
      queuedMessage = sent
          ? null
          : "Expense saved on your phone. Everyone sees it when you're back "
                'online.';
      return true;
    } catch (_) {
      errorMessage = "Couldn't save this expense on your phone.";
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
      final sent = await _repository.remove(_planId, expense);
      queuedMessage = sent
          ? null
          : "Expense deleted on your phone. It's removed for everyone when "
                "you're back online.";
      return true;
    } catch (_) {
      errorMessage = "Couldn't delete this expense on your phone.";
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
