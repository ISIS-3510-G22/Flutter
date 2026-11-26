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
    failed = false;
    notifyListeners();
    try {
      final result = await _repository.balances(_uid);
      if (load != _latestLoad) return;
      if (result != null) {
        friends = [...result.friends]
          ..sort((a, b) => b.totalCents.abs().compareTo(a.totalCents.abs()));
        savedAt = result.savedAt;
      }
    } catch (_) {
      if (load != _latestLoad) return;
      failed = true;
    }
    isLoading = false;
    notifyListeners();
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
