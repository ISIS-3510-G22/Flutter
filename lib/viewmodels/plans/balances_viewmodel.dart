import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/model/data/balance_repository.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/settlement_repository.dart';
import 'package:plansync/model/data/split_outbox_repository.dart';
import 'package:plansync/model/logic/balances.dart';
import 'package:plansync/model/models/friend_balance.dart';

class BalancesViewModel extends ChangeNotifier {
  BalancesViewModel(this._uid) {
    _connectivitySub = ConnectivityRepository.instance.changes.listen((online) {
      if (online) refresh();
    });
    _hadPending = _queue.hasPending;
    _queueSub = _queue.changes.listen((_) => _onQueueChanged());
    refresh();
  }

  final String _uid;
  final _repository = BalanceRepository();
  final _settlementRepository = SettlementRepository();
  late final StreamSubscription<bool> _connectivitySub;
  late final StreamSubscription<void> _queueSub;
  late bool _hadPending;
  bool isSaving = false;

  SplitOutboxRepository get _queue => SplitOutboxRepository.instance;
  var _latestLoad = 0;

  List<FriendBalance>? friends;
  DateTime? savedAt;
  bool isLoading = true;
  bool isUpdating = false;
  bool failed = false;

  int get youOweCents {
    var total = 0;
    for (final friend in friends ?? const <FriendBalance>[]) {
      if (friend.totalCents < 0) total -= friend.totalCents;
    }
    return total;
  }

  int get owedToYouCents {
    var total = 0;
    for (final friend in friends ?? const <FriendBalance>[]) {
      if (friend.totalCents > 0) total += friend.totalCents;
    }
    return total;
  }

  Future<void> refresh() async {
    final load = ++_latestLoad;
    isLoading = friends == null;
    isUpdating = true;
    failed = false;
    notifyListeners();
    if (friends == null) {
      try {
        final saved = await _repository.savedBalances(_uid);
        if (load != _latestLoad) return;
        if (saved != null) {
          _show(saved.friends, saved.savedAt);
          isLoading = false;
          notifyListeners();
        }
      } catch (_) {
        if (load != _latestLoad) return;
        _finishLoad(failed: true);
        return;
      }
    }
    return _repository
        .balances(_uid)
        .then((result) {
          if (load != _latestLoad) return;
          if (result != null) _show(result.friends, result.savedAt);
          _finishLoad(failed: false);
        })
        .catchError((Object _) {
          if (load != _latestLoad) return;
          _finishLoad(failed: true);
        });
  }

  void _finishLoad({required bool failed}) {
    this.failed = failed;
    isLoading = false;
    isUpdating = false;
    notifyListeners();
  }

  void _show(List<FriendBalance> loaded, DateTime? time) {
    friends = [...loaded]
      ..sort((a, b) => b.totalCents.abs().compareTo(a.totalCents.abs()));
    for (final friend in friends!) {
      friend.plans.sort((a, b) => b.date.compareTo(a.date));
    }
    savedAt = time;
  }

  bool get hasPendingChanges => _queue.hasPending;

  bool isPending(FriendBalance friend) =>
      friend.plans.any((p) => _queue.hasPendingFor(p.planId));

  Future<({String message, List<({String planId, String id})> saved})>
  recordPayment(FriendBalance friend, int cents) async {
    final saved = <({String planId, String id})>[];
    var sent = true;
    String message;
    isSaving = true;
    notifyListeners();
    try {
      for (final part in splitPayment(friend.plans, cents)) {
        final settlement = paymentBetween(
          _settlementRepository.newId(part.planId),
          _uid,
          friend.userId,
          part.cents,
        );
        if (!await _settlementRepository.markPaid(part.planId, settlement)) {
          sent = false;
        }
        saved.add((planId: part.planId, id: settlement.id));
      }
      message = sent
          ? 'Payment recorded'
          : "Saved on your phone. It will sync when you're back online.";
    } catch (_) {
      message = "Couldn't save the whole payment on your phone.";
    }
    await refresh();
    isSaving = false;
    notifyListeners();
    return (message: message, saved: saved);
  }

  Future<String> undoPayment(List<({String planId, String id})> saved) async {
    var message = 'Payment undone';
    isSaving = true;
    notifyListeners();
    try {
      for (final part in saved) {
        if (!await _settlementRepository.undoPaid(part.planId, part.id)) {
          message = "Undone on your phone. It will sync when you're online.";
        }
      }
    } catch (_) {
      message = "Couldn't undo the whole payment on your phone.";
    }
    await refresh();
    isSaving = false;
    notifyListeners();
    return message;
  }

  Future<void> _onQueueChanged() async {
    final pending = _queue.hasPending;
    final caughtUp = _hadPending && !pending;
    _hadPending = pending;
    notifyListeners();
    if (caughtUp) await refresh();
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub.cancel();
    _queueSub.cancel();
    super.dispose();
  }
}
