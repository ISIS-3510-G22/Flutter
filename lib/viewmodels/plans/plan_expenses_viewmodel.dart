import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/model/data/expense_repository.dart';
import 'package:plansync/model/data/plan_payment_repository.dart';
import 'package:plansync/model/data/split_outbox_repository.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/reimbursement_method.dart';
import 'package:plansync/model/models/user.dart';

class PlanExpensesViewModel extends ChangeNotifier {
  PlanExpensesViewModel(this.planId, this.participants, this._currentUserId) {
    _hadPending = _queue.hasPendingFor(planId);
    _queueSub = _queue.changes.listen((_) => _onQueueChanged());
    _listenToServer();
    _loadMyMethods();
  }

  final String planId;

  /// Starts as the list plan detail passes in (offline it has no payment
  /// methods) and is replaced by the people from `plan_people` or the server.
  List<User> participants;
  final String _currentUserId;
  final _expenseRepository = ExpenseRepository();
  final _paymentRepository = PlanPaymentRepository();
  StreamSubscription<List<Expense>?>? _sub;
  StreamSubscription<Map<String, String>>? _choicesSub;
  late final StreamSubscription<void> _queueSub;
  late bool _hadPending;

  SplitOutboxRepository get _queue => SplitOutboxRepository.instance;

  /// Expenses and payments of this plan still waiting to sync.
  Set<String> get pendingIds => _queue.pendingIdsFor(planId);

  List<Expense> expenses = [];
  bool isLoading = true;

  /// True while nothing is saved for this plan and the server hasn't
  /// answered: offline that means "Connect to load this plan's expenses."
  bool notSaved = false;

  List<ReimbursementMethod> myMethods = [];
  String? myMethodId;

  void _listenToServer() {
    _sub?.cancel();
    _choicesSub?.cancel();
    _sub = _expenseRepository.expensesForPlan(planId).listen(_onExpenses);
    _choicesSub = _paymentRepository.choicesForPlan(planId).listen(_onChoices);
  }

  /// Every queue change re-reads the local copy (labels, offline saves). Only
  /// when this plan's last queued write is gone does it listen to the server
  /// again: that full snapshot brings others' changes and drops dropped edits.
  Future<void> _onQueueChanged() async {
    final pending = _queue.hasPendingFor(planId);
    final caughtUp = _hadPending && !pending;
    _hadPending = pending;
    if (caughtUp) {
      _listenToServer();
      return;
    }
    final saved = await _expenseRepository.savedExpenses(planId);
    if (saved != null) expenses = saved;
    myMethodId = (await _paymentRepository.savedChoices(
      planId,
    ))[_currentUserId];
    notifyListeners();
  }

  void _onExpenses(List<Expense>? updated) {
    notSaved = updated == null;
    if (updated != null) expenses = updated;
    isLoading = false;
    notifyListeners();
  }

  void _onChoices(Map<String, String> choices) {
    myMethodId = choices[_currentUserId];
    notifyListeners();
  }

  /// Also loads the signed-in user, who may not be among the people going.
  Future<void> _loadMyMethods() async {
    final ids = {...participants.map((p) => p.id), _currentUserId}.toList();
    final people = await _paymentRepository.participants(planId, ids);
    final going = [
      for (final p in people)
        if (participants.any((q) => q.id == p.id)) p,
    ];
    if (going.isNotEmpty) participants = going;
    for (final p in people) {
      if (p.id == _currentUserId) myMethods = p.reimbursementMethods;
    }
    notifyListeners();
  }

  String? get selectedMethodId {
    for (final m in myMethods) {
      if (m.id == myMethodId) return m.id;
    }
    return null;
  }

  /// The screen doesn't wait: `.then` picks the message from whether it was
  /// sent or kept on the phone, `.catchError` covers a local save failure.
  Future<String?> chooseMethod(String? methodId) {
    if (methodId == null) return Future.value(null);
    final before = myMethodId;
    myMethodId = methodId;
    notifyListeners();
    return _paymentRepository
        .chooseMethod(planId, _currentUserId, methodId)
        .then(
          (sent) => sent
              ? 'Payment method saved'
              : 'Payment method saved on your phone. Others see it when '
                    "you're back online.",
        )
        .catchError((_) {
          myMethodId = before;
          notifyListeners();
          return "Couldn't save your payment method on this phone.";
        });
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
    _sub?.cancel();
    _choicesSub?.cancel();
    _queueSub.cancel();
    super.dispose();
  }
}
