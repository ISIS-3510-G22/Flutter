import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/group_outings_repository.dart';
import 'package:plansync/model/models/group_history.dart';

class GroupOutingsViewModel extends ChangeNotifier {
  GroupOutingsViewModel({required this.groupId, required this.uid}) {
    _connectivitySubscription = ConnectivityRepository.instance.changes.listen(
      (online) {
        if (online) unawaited(load());
      },
    );
    unawaited(load());
  }

  final String groupId;
  final String uid;
  final _repository = GroupOutingsRepository();

  late final StreamSubscription<bool> _connectivitySubscription;
  GroupHistory? _history;
  int _loadGeneration = 0;
  bool _isLoading = true;
  bool _disposed = false;

  GroupHistory? get history => _history;
  bool get isLoading => _isLoading;
  bool get isNeverStored => !_isLoading && _history == null;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.history(groupId, uid);
      if (_disposed || generation != _loadGeneration) return;
      _history = result;
    } catch (_) {
      if (_disposed || generation != _loadGeneration) return;
      _history = null;
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
