import 'package:plansync/model/models/group_history.dart';

class GroupOutingsCache {
  GroupOutingsCache({this.capacity = 10});

  final int capacity;
  final _entries = <String, GroupHistory>{};

  GroupHistory? get(String groupId) {
    final history = _entries.remove(groupId);
    if (history == null) return null;
    _entries[groupId] = history;
    return history;
  }

  void put(String groupId, GroupHistory history) {
    _entries.remove(groupId);
    _entries[groupId] = history;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}
