import 'package:plansync/model/models/user.dart';

class UserCache {
  UserCache({
    this.capacity = 50,
    this.timeToLive = const Duration(minutes: 10),
  });

  final int capacity;
  final Duration timeToLive;
  final _entries = <String, _CachedUser>{};

  User? get(String id, {bool allowStale = false}) {
    final entry = _entries.remove(id);
    if (entry == null) return null;
    _entries[id] = entry;
    if (!allowStale && DateTime.now().difference(entry.savedAt) >= timeToLive) {
      return null;
    }
    return entry.user;
  }

  void put(User user) {
    _entries.remove(user.id);
    _entries[user.id] = _CachedUser(user, DateTime.now());
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void invalidate(String id) => _entries.remove(id);
}

class _CachedUser {
  const _CachedUser(this.user, this.savedAt);

  final User user;
  final DateTime savedAt;
}
