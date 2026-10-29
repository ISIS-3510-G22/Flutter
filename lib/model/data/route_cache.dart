import 'package:plansync/model/models/plan_route.dart';

/// LRU of routes, limited by the total number of points held (size by cost),
/// not by how many routes: a cross-city drive can have many times the points
/// of a short walk.
class RouteCache {
  RouteCache({required this.maxPoints});

  final int maxPoints;

  // A map literal is a LinkedHashMap: it keeps insertion order, which here is
  // recency order. The first key is the least recently used, the last one the
  // most recent. Remove + re-insert moves a key to the end in O(1).
  final _routes = <String, PlanRoute>{};
  int _totalPoints = 0;

  int get totalPoints => _totalPoints;

  /// A hit moves the route to the most recent end.
  PlanRoute? get(String key) {
    final route = _routes.remove(key);
    if (route == null) return null;
    _routes[key] = route;
    return route;
  }

  /// Evicts the least recently used routes until the new one fits. A route
  /// bigger than [maxPoints] isn't kept (it would empty the cache).
  void put(String key, PlanRoute route) {
    final old = _routes.remove(key);
    if (old != null) _totalPoints -= old.points.length;

    final cost = route.points.length;
    if (cost > maxPoints) return;

    while (_totalPoints + cost > maxPoints) {
      final oldest = _routes.keys.first;
      _totalPoints -= _routes.remove(oldest)!.points.length;
    }
    _routes[key] = route;
    _totalPoints += cost;
  }
}
