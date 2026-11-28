import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/recap_repository.dart';
import 'package:plansync/model/logic/recap.dart';
import 'package:plansync/model/models/month_recap.dart';

class RecapViewModel extends ChangeNotifier {
  RecapViewModel(this._uid) {
    _connectivitySub = ConnectivityRepository.instance.changes.listen((online) {
      if (online) load();
    });
    load();
  }

  final String _uid;
  final _repository = RecapRepository();
  late final StreamSubscription<bool> _connectivitySub;

  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  MonthRecap? recap;
  bool isLoading = true;

  bool get canGoNext {
    final now = DateTime.now();
    return month.isBefore(DateTime(now.year, now.month));
  }

  Future<void> load({bool refresh = false}) async {
    final key = monthKey(month);
    isLoading = true;
    notifyListeners();
    final result = await _repository.recap(_uid, key, refresh: refresh);
    if (key != monthKey(month)) return;
    recap = result;
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => load(refresh: true);

  void previousMonth() {
    month = DateTime(month.year, month.month - 1);
    load();
  }

  void nextMonth() {
    month = DateTime(month.year, month.month + 1);
    load();
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
