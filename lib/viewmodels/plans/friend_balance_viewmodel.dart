import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/model/data/balance_repository.dart';
import 'package:plansync/model/data/settlement_repository.dart';
import 'package:plansync/model/data/split_outbox_repository.dart';
import 'package:plansync/model/logic/balances.dart';
import 'package:plansync/model/models/friend_balance.dart';

class FriendBalanceViewModel extends ChangeNotifier {
  FriendBalanceViewModel(this._uid, FriendBalance friend)
    : _friendId = friend.userId,
      plans = friend.plans {
    _hadPending = _hasPending;
    _queueSub = _queue.changes.listen((_) => _onQueueChanged());
  }

  final String _uid;
  final String _friendId;
  final _balanceRepository = BalanceRepository();
  final _settlementRepository = SettlementRepository();
  late final StreamSubscription<void> _queueSub;
  late bool _hadPending;

  List<PlanBalance> plans;
  bool isSaving = false;

  SplitOutboxRepository get _queue => SplitOutboxRepository.instance;

  bool isPending(String planId) => _queue.hasPendingFor(planId);

  bool get _hasPending => plans.any((p) => isPending(p.planId));

  Future<({String message, String? settlementId})> recordPayment(
    PlanBalance plan,
    int cents,
  ) async {
    final settlement = paymentBetween(
      _settlementRepository.newId(plan.planId),
      _uid,
      _friendId,
      cents * plan.cents.sign,
    );
    isSaving = true;
    notifyListeners();
    try {
      final sent = await _settlementRepository.markPaid(
        plan.planId,
        settlement,
      );
      await reload();
      return (message: _savedMessage(sent), settlementId: settlement.id);
    } catch (_) {
      return (
        message: "Couldn't save this payment on your phone.",
        settlementId: null,
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String> undoPayment(String planId, String settlementId) async {
    isSaving = true;
    notifyListeners();
    try {
      final sent = await _settlementRepository.undoPaid(planId, settlementId);
      await reload();
      return sent ? 'Payment undone' : _savedMessage(sent);
    } catch (_) {
      return "Couldn't undo this payment on your phone.";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  String _savedMessage(bool sent) => sent
      ? 'Payment recorded'
      : "Saved on your phone. It will sync when you're back online.";

  Future<void> _onQueueChanged() async {
    final pending = _hasPending;
    final caughtUp = _hadPending && !pending;
    _hadPending = pending;
    notifyListeners();
    if (caughtUp) await reload();
  }

  Future<void> reload() async {
    try {
      final result = await _balanceRepository.balances(_uid);
      if (result == null || !result.fromServer) return;
      plans = [
        for (final friend in result.friends)
          if (friend.userId == _friendId) ...friend.plans,
      ]..sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (_) {
      return;
    }
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _queueSub.cancel();
    super.dispose();
  }
}
