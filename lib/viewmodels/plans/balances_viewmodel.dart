import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/model/data/balance_repository.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/models/friend_balance.dart';

class BalancesViewModel extends ChangeNotifier {
  BalancesViewModel(this._uid) {
    _connectivitySub = ConnectivityRepository.instance.changes.listen((online) {
      if (online) refresh();
    });
    refresh();
  }

  final String _uid;
  final _repository = BalanceRepository();
  late final StreamSubscription<bool> _connectivitySub;
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
    try {
      if (friends == null) {
        final saved = await _repository.savedBalances(_uid);
        if (load != _latestLoad) return;
        if (saved != null) {
          _show(saved.friends, saved.savedAt);
          isLoading = false;
          notifyListeners();
        }
      }
      final result = await _repository.balances(_uid);
      if (load != _latestLoad) return;
      if (result != null) _show(result.friends, result.savedAt);
    } catch (_) {
      if (load != _latestLoad) return;
      failed = true;
    }
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

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub.cancel();
    super.dispose();
  }
}
