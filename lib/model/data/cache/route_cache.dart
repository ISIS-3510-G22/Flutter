import 'package:plansync/model/models/plan_route.dart';

class RouteCache {
  RouteCache({required this.maxPoints});

  final int maxPoints;

  final _routes = <String, PlanRoute>{};
  int _totalPoints = 0;

  int get totalPoints => _totalPoints;

  PlanRoute? get(String key) {
    final route = _routes.remove(key);
    if (route == null) return null;
    _routes[key] = route;
    return route;
  }

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
