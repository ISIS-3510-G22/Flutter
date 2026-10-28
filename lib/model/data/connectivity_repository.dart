import 'dart:async';

import 'package:plansync/model/models/offline_exception.dart';
import 'package:plansync/model/services/connectivity_service.dart';

class ConnectivityRepository {
  ConnectivityRepository._internal();

  static final instance = ConnectivityRepository._internal();

  final _service = ConnectivityService();
  final _changes = StreamController<bool>.broadcast();
  bool _isOnline = true;

  bool get isOnline => _isOnline;
  Stream<bool> get changes => _changes.stream;

  Future<void> init() async {
    _isOnline = await _service.isOnline();
    _service.onChange.listen(_update);
  }

  void _update(bool online) {
    if (online == _isOnline) return;
    _isOnline = online;
    _changes.add(online);
  }

  void ensureOnline() {
    if (!_isOnline) throw const OfflineException();
  }
}
