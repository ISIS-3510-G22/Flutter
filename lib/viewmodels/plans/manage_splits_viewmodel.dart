import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/data/expense_repository.dart';
import 'package:plansync/data/payment_info_repository.dart';
import 'package:plansync/data/settlement_repository.dart';
import 'package:plansync/models/expense.dart';
import 'package:plansync/models/payment_info.dart';
import 'package:plansync/models/settlement.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/utils/debt_simplifier.dart';

class SplitRow {
  final String userId;
  final String name;
  final double amount;
  final String? settlementId;

  const SplitRow({
    required this.userId,
    required this.name,
    required this.amount,
    this.settlementId,
  });
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
    _paymentInfoSub = _paymentInfoRepository
        .paymentInfoForPlan(_planId)
        .listen(_onPaymentInfo);
  }

  final String _planId;
  final List<User> _participants;
  final String _currentUserId;
  final _expenseRepository = ExpenseRepository();
  final _settlementRepository = SettlementRepository();
  final _paymentInfoRepository = PaymentInfoRepository();
  late final StreamSubscription<List<Expense>> _expensesSub;
  late final StreamSubscription<List<Settlement>> _settlementsSub;
  late final StreamSubscription<List<PaymentInfo>> _paymentInfoSub;

  List<Expense> _expenses = [];
  List<Settlement> _settlements = [];
  bool _expensesLoaded = false;
  bool _settlementsLoaded = false;
  Map<String, String> _paymentDetails = {};

  List<SplitRow> youOwe = [];
  List<SplitRow> owedToYou = [];
  List<SplitRow> paidByYou = [];
  List<SplitRow> paidToYou = [];
  bool isLoading = true;
  String? errorMessage;

  bool get isEmpty =>
      youOwe.isEmpty &&
      owedToYou.isEmpty &&
      paidByYou.isEmpty &&
      paidToYou.isEmpty;

  void _onPaymentInfo(List<PaymentInfo> infos) {
    _paymentDetails = {for (final i in infos) i.userId: i.details};
    notifyListeners();
  }

  String? paymentDetailsOf(String userId) => _paymentDetails[userId];

  List<String> _splitIds(Expense expense) {
    if (expense.splitAmongIds.isEmpty) {
      return _participants.map((p) => p.id).toList();
    }
    return expense.splitAmongIds;
  }

  String _nameOf(String userId) {
    for (final p in _participants) {
      if (p.id == userId) return '${p.name} ${p.lastName}';
    }
    return 'Unknown';
  }

  // Positive = must receive money, negative = must pay.
  Map<String, int> _balancesCents() {
    final balances = <String, int>{};
    void add(String id, int cents) {
      final current = balances[id];
      if (current == null) {
        balances[id] = cents;
      } else {
        balances[id] = current + cents;
      }
    }

    for (final expense in _expenses) {
      final splitIds = _splitIds(expense);
      if (splitIds.isEmpty) continue;
      final totalCents = (expense.value * 100).round();
      final shares = splitCents(totalCents, splitIds.length);
      add(expense.paidById, totalCents);
      for (var i = 0; i < splitIds.length; i++) {
        add(splitIds[i], -shares[i]);
      }
    }
    for (final s in _settlements) {
      final cents = (s.amount * 100).round();
      add(s.fromId, cents);
      add(s.toId, -cents);
    }
    return balances;
  }

  void _recalculate() {
    if (!_expensesLoaded || !_settlementsLoaded) return;

    youOwe = [];
    owedToYou = [];
    for (final t in simplifyDebts(_balancesCents())) {
      if (t.fromId == _currentUserId) {
        youOwe.add(
          SplitRow(userId: t.toId, name: _nameOf(t.toId), amount: t.amount),
        );
      } else if (t.toId == _currentUserId) {
        owedToYou.add(
          SplitRow(userId: t.fromId, name: _nameOf(t.fromId), amount: t.amount),
        );
      }
    }

    paidByYou = [];
    paidToYou = [];
    for (final s in _settlements) {
      if (s.fromId == _currentUserId) {
        paidByYou.add(
          SplitRow(
            userId: s.toId,
            name: _nameOf(s.toId),
            amount: s.amount,
            settlementId: s.id,
          ),
        );
      } else if (s.toId == _currentUserId) {
        paidToYou.add(
          SplitRow(
            userId: s.fromId,
            name: _nameOf(s.fromId),
            amount: s.amount,
            settlementId: s.id,
          ),
        );
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> markPaid(SplitRow row) async {
    errorMessage = null;
    try {
      await _settlementRepository.settle(
        _planId,
        Settlement(
          id: '',
          fromId: _currentUserId,
          toId: row.userId,
          amount: row.amount,
        ),
      );
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      notifyListeners();
    }
  }

  Future<void> undoPaid(SplitRow row) async {
    final settlementId = row.settlementId;
    if (settlementId == null) return;
    errorMessage = null;
    try {
      await _settlementRepository.unsettle(_planId, settlementId);
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _expensesSub.cancel();
    _settlementsSub.cancel();
    _paymentInfoSub.cancel();
    super.dispose();
  }
}
