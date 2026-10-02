import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/data/expense_repository.dart';
import 'package:plansync/data/plan_payment_repository.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/expense.dart';
import 'package:plansync/models/reimbursement_method.dart';
import 'package:plansync/models/user.dart';

class PlanExpensesViewModel extends ChangeNotifier {
  PlanExpensesViewModel(this.planId, this.participants, this._currentUserId) {
    _sub = _expenseRepository.expensesForPlan(planId).listen(_onExpenses);
    _choicesSub = _paymentRepository.choicesForPlan(planId).listen(_onChoices);
    _loadMyMethods();
  }

  final String planId;
  final List<User> participants;
  final String _currentUserId;
  final _expenseRepository = ExpenseRepository();
  final _paymentRepository = PlanPaymentRepository();
  final _userRepository = UserRepository();
  late final StreamSubscription<List<Expense>> _sub;
  late final StreamSubscription<Map<String, String>> _choicesSub;

  List<Expense> expenses = [];
  bool isLoading = true;

  /// The current user's profile methods, read fresh so recently added ones
  /// show up without signing in again.
  List<ReimbursementMethod> myMethods = [];
  String? myMethodId;

  void _onExpenses(List<Expense> updated) {
    expenses = updated;
    isLoading = false;
    notifyListeners();
  }

  void _onChoices(Map<String, String> choices) {
    myMethodId = choices[_currentUserId];
    notifyListeners();
  }

  Future<void> _loadMyMethods() async {
    final me = await _userRepository.getUser(_currentUserId);
    if (me == null) return;
    myMethods = me.reimbursementMethods;
    notifyListeners();
  }

  /// The chosen method, if it still exists in the profile.
  String? get selectedMethodId {
    for (final m in myMethods) {
      if (m.id == myMethodId) return m.id;
    }
    return null;
  }

  Future<bool> chooseMethod(String? methodId) async {
    if (methodId == null) return false;
    try {
      await _paymentRepository.choose(planId, _currentUserId, methodId);
      return true;
    } catch (_) {
      return false;
    }
  }

  String payerName(Expense expense) {
    for (final p in participants) {
      if (p.id == expense.paidById) return '${p.name} ${p.lastName}';
    }
    return 'Unknown';
  }

  String splitLabel(Expense expense) {
    final ids = expense.splitAmongIds;
    if (ids.isEmpty || participants.every((p) => ids.contains(p.id))) {
      return 'For everyone';
    }
    if (ids.length == 1) {
      for (final p in participants) {
        if (p.id == ids.first) return 'For ${p.name}';
      }
    }
    return 'For ${ids.length} people';
  }

  @override
  void dispose() {
    _sub.cancel();
    _choicesSub.cancel();
    super.dispose();
  }
}
