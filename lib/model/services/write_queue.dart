import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:plansync/model/data/local/write_queue_store.dart';
import 'package:plansync/model/models/pending_write.dart';
import 'package:plansync/model/services/connectivity_service.dart';

abstract class WriteQueue<K extends Enum> extends ChangeNotifier {
  WriteQueue(String table, List<K> kinds)
    : _store = WriteQueueStore(table, kinds);

  final WriteQueueStore<K> _store;
  List<PendingWrite<K>> _pending = [];

  bool _flushing = false;
  String? _dropped;
  bool _started = false;

  Set<String> get pendingDocIds => {for (final w in _pending) w.docId};
  bool get hasPending => _pending.isNotEmpty;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    ConnectivityService.instance.addListener(flush);
    await _reload();
    await flush();
  }

  Future<void> clear() async {
    await _store.clear();
    await _reload();
  }

  Future<void> send(PendingWrite<K> write);

  Future<void> _reload() async {
    _pending = await _store.all();
    notifyListeners();
  }

  Future<bool> submit(PendingWrite<K> write) {
    if (!ConnectivityService.instance.isOnline || hasPending) {
      return _enqueue(write).then((_) => false);
    }
    return send(write)
        .timeout(const Duration(seconds: 8))
        .then((_) => true)
        .catchError((_) => _enqueue(write).then((_) => false));
  }

  Future<void> _enqueue(PendingWrite<K> write) async {
    await _store.add(write);
    await _reload();
    unawaited(flush());
  }

  static const _dropCodes = {
    'not-found',
    'invalid-argument',
    'failed-precondition',
  };

  bool _canRetry(Object error) =>
      error is TimeoutException ||
      (error is FirebaseException && !_dropCodes.contains(error.code));

  Future<void> flush() async {
    if (_flushing || !ConnectivityService.instance.isOnline) return;
    _flushing = true;
    try {
      while (_pending.isNotEmpty) {
        final write = _pending.first;
        try {
          await send(write).timeout(const Duration(seconds: 8));
        } catch (error) {
          if (_canRetry(error)) break;
          _dropped = describeDropped(write);
        }
        await _store.remove(write.id!);
        await _reload();
      }
    } finally {
      _flushing = false;
    }
  }

  String describeDropped(PendingWrite<K> write);

  String? takeDropped() {
    final message = _dropped;
    _dropped = null;
    return message;
  }
}
