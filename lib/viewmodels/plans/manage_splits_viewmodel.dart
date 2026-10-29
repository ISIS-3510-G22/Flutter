import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/expense_repository.dart';
import 'package:plansync/model/data/overdue_debt_repository.dart';
import 'package:plansync/model/data/plan_payment_repository.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/data/settlement_repository.dart';
import 'package:plansync/model/data/split_outbox_repository.dart';
import 'package:plansync/model/logic/debt_simplifier.dart';
import 'package:plansync/model/logic/overdue.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/overdue_debt.dart';
import 'package:plansync/model/models/reimbursement_method.dart';
import 'package:plansync/model/models/settlement.dart';
import 'package:plansync/model/models/user.dart';

class SplitRow {
  final String userId;
  final String name;
  final double amount;
  final String? settlementId;

  final int? overdueDays;

  const SplitRow({
    required this.userId,
    required this.name,
    required this.amount,
    this.settlementId,
    this.overdueDays,
  });
}

class ManageSplitsViewModel extends ChangeNotifier {
  ManageSplitsViewModel(
    this._planId,
    this._currentUserId, {
    List<User>? participants,
    List<String> participantIds = const [],
  }) {
    if (participants != null) {
      _participants = participants;
      _participantsLoaded = true;
    } else {
      _loadParticipants(participantIds);
    }
    _hadPending = _queue.hasPendingFor(_planId);
    _queueSub = _queue.changes.listen((_) => _onQueueChanged());
    _listenToServer();
    _loadPlanDate();
  }

  void _listenToServer() {
    _expensesSub?.cancel();
    _settlementsSub?.cancel();
    _choicesSub?.cancel();
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
    _choicesSub = _paymentRepository.choicesForPlan(_planId).listen((c) {
      _methodChoices = c;
      notifyListeners();
    });
  }

  /// Every queue change re-reads the local copy (labels, offline saves). Only
  /// when this plan's last queued write is gone does it listen to the server
  /// again: that full snapshot brings others' changes and drops dropped ones.
  Future<void> _onQueueChanged() async {
    final pending = _queue.hasPendingFor(_planId);
    final caughtUp = _hadPending && !pending;
    _hadPending = pending;
    if (caughtUp) {
      _listenToServer();
      return;
    }
    await _reloadLocal();
  }

  Future<void> _reloadLocal() async {
    final expenses = await _expenseRepository.savedExpenses(_planId);
    final settlements = await _settlementRepository.savedSettlements(_planId);
    if (expenses != null) _expenses = expenses;
    if (settlements != null) _settlements = settlements;
    _methodChoices = await _paymentRepository.savedChoices(_planId);
    _recalculate();
  }

  final String _planId;
  final String _currentUserId;
  List<User> _participants = [];
  bool _participantsLoaded = false;
  final _expenseRepository = ExpenseRepository();
  final _settlementRepository = SettlementRepository();
  final _paymentRepository = PlanPaymentRepository();
  final _planRepository = PlanRepository();
  final _overdueRepository = OverdueDebtRepository();
  DateTime? _planDate;
  var _syncedOverdue = '';
  StreamSubscription<List<Expense>?>? _expensesSub;
  StreamSubscription<List<Settlement>?>? _settlementsSub;
  StreamSubscription<Map<String, String>>? _choicesSub;
  late final StreamSubscription<void> _queueSub;
  late bool _hadPending;

  SplitOutboxRepository get _queue => SplitOutboxRepository.instance;

  /// Payments of this plan still waiting to sync.
  Set<String> get pendingIds => _queue.pendingIdsFor(_planId);
  Map<String, String> _methodChoices = {};

  // `null` = never saved on this phone and no server answer yet.
  List<Expense>? _expenses;
  List<Settlement>? _settlements;
  bool _expensesLoaded = false;
  bool _settlementsLoaded = false;

  List<SplitRow> youOwe = [];
  List<SplitRow> owedToYou = [];
  List<SplitRow> paidByYou = [];
  List<SplitRow> paidToYou = [];
  bool isLoading = true;

  /// Balances need both lists: with either one never saved they'd be wrong,
  /// so the view shows "Connect to load this plan's expenses." instead.
  bool notSaved = false;

  bool get hasExpenses => _expenses?.isNotEmpty ?? false;

  /// Tomas's saved copy of the plan first, then the server (8 s).
  Future<void> _loadPlanDate() async {
    try {
      final saved = await _planRepository.savedPlan(_currentUserId, _planId);
      final plan =
          saved ??
          await _planRepository
              .planById(_planId)
              .first
              .timeout(const Duration(seconds: 8));
      _planDate = plan.date;
      _recalculate();
    } catch (_) {
      // Without the date there is just no overdue label.
    }
  }

  int? _overdueDays() {
    final date = _planDate;
    if (date == null) return null;
    return overdueDays(date, DateTime.now());
  }

  /// Derived data: skipped offline, rerun on the next recalculation online.
  Future<void> _syncOverdue(List<Transfer> transfers) async {
    if (!ConnectivityRepository.instance.isOnline) return;
    final days = _overdueDays();
    if (_planDate == null) return;
    final overdue = [
      if (days != null)
        for (final t in transfers)
          OverdueDebt(
            fromId: t.fromId,
            toId: t.toId,
            amount: t.amount,
            daysOverdue: days,
          ),
    ];
    final signature = [
      for (final d in overdue) '${d.id}:${d.amount}:${d.daysOverdue}',
    ].join('|');
    if (signature == _syncedOverdue) return;
    _syncedOverdue = signature;
    try {
      await _overdueRepository.sync(_planId, overdue);
    } catch (_) {
      _syncedOverdue = '';
    }
  }

  Future<void> _loadParticipants(List<String> ids) async {
    _participants = await _paymentRepository.participants(_planId, ids);
    _participantsLoaded = true;
    _recalculate();
  }

  bool get isEmpty =>
      youOwe.isEmpty &&
      owedToYou.isEmpty &&
      paidByYou.isEmpty &&
      paidToYou.isEmpty;

  List<ReimbursementMethod> allMethodsOf(String userId) {
    for (final p in _participants) {
      if (p.id == userId) return p.reimbursementMethods;
    }
    return const [];
  }

  ReimbursementMethod? preferredMethodOf(String userId) {
    final methods = allMethodsOf(userId);
    if (methods.isEmpty) return null;
    final chosen = _methodChoices[userId];
    for (final m in methods) {
      if (m.id == chosen) return m;
    }
    return methods.first;
  }

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

    for (final expense in _expenses!) {
      final splitIds = _splitIds(expense);
      if (splitIds.isEmpty) continue;
      final totalCents = (expense.value * 100).round();
      final shares = splitCents(totalCents, splitIds.length);
      add(expense.paidById, totalCents);
      for (var i = 0; i < splitIds.length; i++) {
        add(splitIds[i], -shares[i]);
      }
    }
    for (final s in _settlements!) {
      final cents = (s.amount * 100).round();
      add(s.fromId, cents);
      add(s.toId, -cents);
    }
    return balances;
  }

  void _recalculate() {
    if (!_expensesLoaded || !_settlementsLoaded || !_participantsLoaded) {
      return;
    }
    final settlements = _settlements;
    notSaved = _expenses == null || settlements == null;
    if (notSaved) {
      isLoading = false;
      notifyListeners();
      return;
    }

    youOwe = [];
    owedToYou = [];
    final transfers = simplifyDebts(_balancesCents());
    final days = _overdueDays();
    for (final t in transfers) {
      if (t.fromId == _currentUserId) {
        youOwe.add(
          SplitRow(userId: t.toId, name: _nameOf(t.toId), amount: t.amount),
        );
      } else if (t.toId == _currentUserId) {
        owedToYou.add(
          SplitRow(
            userId: t.fromId,
            name: _nameOf(t.fromId),
            amount: t.amount,
            overdueDays: days,
          ),
        );
      }
    }

    _syncOverdue(transfers);

    paidByYou = [];
    paidToYou = [];
    for (final s in settlements!) {
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

  static const _queuedPayment =
      "Payment saved on your phone. Balances update for everyone when you're "
      'back online.';

  /// The screen doesn't wait: `.then` picks the message (none when sent,
  /// "saved on your phone" when queued), `.catchError` the local failure.
  /// The settlement ID is made here, so undo works while it's still queued.
  Future<String?> markPaid(SplitRow row) {
    final settlement = Settlement(
      id: _settlementRepository.newId(_planId),
      fromId: _currentUserId,
      toId: row.userId,
      amount: row.amount,
    );
    return _settlementRepository
        .markPaid(_planId, settlement)
        .then((sent) async {
          await _reloadLocal();
          return sent ? null : _queuedPayment;
        })
        .catchError((_) => "Couldn't save this payment on your phone.");
  }

  Future<String?> undoPaid(SplitRow row) {
    final settlementId = row.settlementId;
    if (settlementId == null) return Future.value(null);
    return _settlementRepository
        .undoPaid(_planId, settlementId)
        .then((sent) async {
          await _reloadLocal();
          return sent ? null : _queuedPayment;
        })
        .catchError((_) => "Couldn't undo this payment on your phone.");
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
    _expensesSub?.cancel();
    _settlementsSub?.cancel();
    _choicesSub?.cancel();
    _queueSub.cancel();
    super.dispose();
  }
}
