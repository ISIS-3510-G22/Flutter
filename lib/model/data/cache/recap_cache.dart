import 'package:plansync/model/models/month_recap.dart';

class RecapCache {
  static const capacity = 6;

  final _entries = <String, MonthRecap>{};

  MonthRecap? get(String month) {
    final recap = _entries.remove(month);
    if (recap != null) _entries[month] = recap;
    return recap;
  }

  void put(MonthRecap recap) {
    _entries.remove(recap.month);
    _entries[recap.month] = recap;
    if (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}
