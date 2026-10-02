import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:plansync/data/route_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/plan.dart';

class RouteStop {
  final int number;
  final Activity activity;
  final LatLng point;

  const RouteStop({
    required this.number,
    required this.activity,
    required this.point,
  });
}

class PlanRouteViewModel extends ChangeNotifier {
  PlanRouteViewModel(this.plan, List<Activity> activities) {
    final byId = {for (final a in activities) a.id: a};
    for (final id in plan.activityIds) {
      final activity = byId[id];
      if (activity == null) continue;
      final lat = activity.lat;
      final lng = activity.lng;
      if (lat == null || lng == null) {
        missingLocation.add(activity);
        continue;
      }
      stops.add(
        RouteStop(
          number: stops.length + 1,
          activity: activity,
          point: LatLng(lat, lng),
        ),
      );
    }
    loadRoute();
  }

  final Plan plan;
  final _repository = RouteRepository();

  final List<RouteStop> stops = [];
  final List<Activity> missingLocation = [];

  TravelMode mode = TravelMode.walk;
  PlanRoute? route;
  bool isLoading = false;
  bool usingStraightLines = false;

  List<LatLng> get stopPoints => stops.map((s) => s.point).toList();

  List<LatLng> get linePoints {
    final current = route;
    if (current == null) return stopPoints;
    return current.points;
  }

  Future<void> selectMode(TravelMode value) async {
    if (value == mode) return;
    mode = value;
    await loadRoute();
  }

  Future<void> loadRoute() async {
    if (stops.length < 2) return;
    isLoading = true;
    usingStraightLines = false;
    notifyListeners();

    try {
      route = await _repository.route(stopPoints, mode);
      if (route == null) usingStraightLines = true;
    } catch (_) {
      route = null;
      usingStraightLines = true;
    }

    isLoading = false;
    notifyListeners();
  }
}
