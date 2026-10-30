import 'package:flutter/material.dart';
import 'package:plansync/model/data/expense_repository.dart';
import 'package:plansync/model/logic/custom_split.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/split_method.dart';
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
    amountControllers = {
      for (final p in participants) p.id: TextEditingController(),
    };
    if (_editingExpense case final expense?) {
      nameController.text = expense.name;
      valueController.text = _amountText(expense.value);
      if (expense.splitAmongIds.isNotEmpty) {
        splitAmongIds = expense.splitAmongIds.toSet();
      }
      splitMethod = expense.splitMethod;
      expense.customAmounts.forEach((id, amount) {
        amountControllers[id]?.text = _amountText(amount);
      });
    }
  }

  static String _amountText(double amount) =>
      amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toString();

  final String _planId;
  final List<User> participants;
  final _repository = ExpenseRepository();
  final Expense? _editingExpense;

  bool get isEditing => _editingExpense != null;

  final nameController = TextEditingController();
  final valueController = TextEditingController();

  String paidById;
  Set<String> splitAmongIds = {};

  SplitMethod splitMethod = SplitMethod.equal;

  /// One per participant; only the selected ones count.
  late final Map<String, TextEditingController> amountControllers;

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

  void selectMethod(SplitMethod method) {
    splitMethod = method;
    errorMessage = null;
    notifyListeners();
  }

  /// Called as the value or any custom amount is typed, so the remaining
  /// line and the Save button update.
  void onAmountChanged() => notifyListeners();

  Map<String, double> get _customAmounts => {
    for (final id in splitAmongIds)
      id: double.tryParse(amountControllers[id]?.text.trim() ?? '') ?? 0,
  };

  /// Positive: still to assign. Negative: over the total.
  int get remaining => remainingCents(
    double.tryParse(valueController.text.trim()) ?? 0,
    _customAmounts,
  );

  bool get amountsAddUp => splitMethod == SplitMethod.equal || remaining == 0;

  String? get _customError {
    if (_customAmounts.values.any((amount) => amount < 0)) {
      return "Amounts can't be negative.";
    }
    final money = '\$${(remaining.abs() / 100).toStringAsFixed(2)}';
    if (remaining > 0) return 'Assign the remaining $money before saving.';
    if (remaining < 0) return 'The amounts are over the total by $money.';
    return null;
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
    final custom = splitMethod == SplitMethod.custom;
    if (custom && _customError != null) {
      errorMessage = _customError;
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
        splitMethod: splitMethod,
        customAmounts: custom ? _customAmounts : const {},
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

  // Set in dispose: async work (queue reloads, `.then` / `.catchError`,
  // awaited saves) can finish after the view closed, so stop notifying then.
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    nameController.dispose();
    valueController.dispose();
    for (final controller in amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
