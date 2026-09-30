import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/data/expense_repository.dart';
import 'package:plansync/data/settlement_repository.dart';
import 'package:plansync/models/expense.dart';
import 'package:plansync/models/settlement.dart';
import 'package:plansync/models/user.dart';

class SplitBalance {
  final User user;
  final double total;
  final double paid;

  const SplitBalance({
    required this.user,
    required this.total,
    required this.paid,
  });

  double get remaining => total - paid > 0.005 ? total - paid : 0;
  bool get isSettled => remaining == 0;
}

class ManageSplitsViewModel extends ChangeNotifier {
  ManageSplitsViewModel(this._planId, this._participants, this._currentUserId) {
    _expensesSub = _expenseRepository.expensesForPlan(_planId).listen((e) {
      _expenses = e;
      _expensesLoaded = true;
      _recalculate();
    });
    _settlementsSub = _settlementRepository.settlementsForPlan(_planId).listen((
      s,
    ) {
      _settlements = s;
      _settlementsLoaded = true;
      _recalculate();
    });
  }

  final String _planId;
  final List<User> _participants;
  final String _currentUserId;
  final _expenseRepository = ExpenseRepository();
  final _settlementRepository = SettlementRepository();
  late final StreamSubscription<List<Expense>> _expensesSub;
  late final StreamSubscription<List<Settlement>> _settlementsSub;

  List<Expense> _expenses = [];
  List<Settlement> _settlements = [];
  bool _expensesLoaded = false;
  bool _settlementsLoaded = false;

  List<SplitBalance> youOwe = [];
  List<SplitBalance> owedToYou = [];
  bool isLoading = true;
  String? errorMessage;

  Map<String, Map<String, double>> _owes() {
    final owes = <String, Map<String, double>>{};
    if (_participants.isEmpty) return owes;
    for (final expense in _expenses) {
      final share = expense.value / _participants.length;
      for (final p in _participants) {
        if (p.id == expense.paidById) continue;
        final row = owes.putIfAbsent(p.id, () => {});
        final current = row[expense.paidById];
        if (current == null) {
          row[expense.paidById] = share;
        } else {
          row[expense.paidById] = current + share;
        }
      }
    }
    return owes;
  }

  double _owedBetween(
    Map<String, Map<String, double>> owes,
    String fromId,
    String toId,
  ) {
    final row = owes[fromId];
    if (row == null) return 0;
    final amount = row[toId];
    if (amount == null) return 0;
    return amount;
  }

  double _paid(String fromId, String toId) {
    for (final s in _settlements) {
      if (s.fromId == fromId && s.toId == toId) return s.amount;
    }
    return 0;
  }

  void _recalculate() {
    if (!_expensesLoaded || !_settlementsLoaded) return;
    final owes = _owes();
    youOwe = [];
    owedToYou = [];
    for (final other in _participants) {
      if (other.id == _currentUserId) continue;
      final net =
          _owedBetween(owes, _currentUserId, other.id) -
          _owedBetween(owes, other.id, _currentUserId);
      if (net > 0.005) {
        youOwe.add(
          SplitBalance(
            user: other,
            total: net,
            paid: _paid(_currentUserId, other.id),
          ),
        );
      } else if (net < -0.005) {
        owedToYou.add(
          SplitBalance(
            user: other,
            total: -net,
            paid: _paid(other.id, _currentUserId),
          ),
        );
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> togglePaid(SplitBalance balance, bool paid) async {
    errorMessage = null;
    try {
      if (paid) {
        await _settlementRepository.settle(
          _planId,
          Settlement(
            fromId: _currentUserId,
            toId: balance.user.id,
            amount: balance.total,
          ),
        );
      } else {
        await _settlementRepository.unsettle(
          _planId,
          _currentUserId,
          balance.user.id,
        );
      }
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _expensesSub.cancel();
    _settlementsSub.cancel();
    super.dispose();
  }
}
