import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/group_outings_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/group_history.dart';
import 'package:plansync/model/models/user.dart';

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
  final _userRepository = UserRepository();

  late final StreamSubscription<bool> _connectivitySubscription;
  GroupHistory? _history;
  Map<String, User> _membersById = {};
  int _loadGeneration = 0;
  bool _isLoading = true;
  bool _disposed = false;

  GroupHistory? get history => _history;
  User? memberFor(String userId) => _membersById[userId];
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
      final profiles = <String, User>{};
      for (final attendance in result?.attendanceRanking ?? const []) {
        try {
          final user = await _userRepository.getUser(attendance.userId);
          if (user != null) profiles[user.id] = user;
        } catch (_) {}
        if (_disposed || generation != _loadGeneration) return;
      }
      _membersById = profiles;
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
