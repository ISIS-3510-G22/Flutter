import 'package:plansync/model/logic/debt_simplifier.dart';

class PlanBalanceCache {
  static const capacity = 20;

  final _entries = <String, ({int version, List<Transfer> transfers})>{};

  List<Transfer>? get(String planId, int version) {
    final entry = _entries.remove(planId);
    if (entry == null || entry.version != version) return null;
    _entries[planId] = entry;
    return entry.transfers;
  }

  void put(String planId, int version, List<Transfer> transfers) {
    _entries.remove(planId);
    _entries[planId] = (version: version, transfers: transfers);
    if (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}
