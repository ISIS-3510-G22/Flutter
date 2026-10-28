import 'package:plansync/model/models/place.dart';

class PlaceSearchCache {
  static const capacity = 20;
  static const evictionWindow = 5;

  final _entries = <String, List<Place>>{};

  List<Place>? get(String query) {
    final places = _entries.remove(query);
    if (places != null) _entries[query] = places;
    return places;
  }

  void put(String query, List<Place> places) {
    _entries.remove(query);
    _entries[query] = places;
    if (_entries.length > capacity) {
      final oldest = _entries.keys.take(evictionWindow).toList();
      for (final key in oldest) {
        _entries.remove(key);
      }
    }
  }
}
