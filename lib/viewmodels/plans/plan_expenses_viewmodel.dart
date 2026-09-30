import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/data/expense_repository.dart';
import 'package:plansync/models/expense.dart';
import 'package:plansync/models/user.dart';

class PlanExpensesViewModel extends ChangeNotifier {
  PlanExpensesViewModel(this.planId, this.participants) {
    _sub = _expenseRepository.expensesForPlan(planId).listen(_onExpenses);
  }

  final String planId;
  final List<User> participants;
  final _expenseRepository = ExpenseRepository();
  late final StreamSubscription<List<Expense>> _sub;

  List<Expense> expenses = [];
  bool isLoading = true;

  void _onExpenses(List<Expense> updated) {
    expenses = updated;
    isLoading = false;
    notifyListeners();
  }

  String payerName(Expense expense) {
    for (final p in participants) {
      if (p.id == expense.paidById) return '${p.name} ${p.lastName}';
    }
    return 'Unknown';
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
