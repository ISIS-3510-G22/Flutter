import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/route_repository.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/model/models/plan_route.dart';

/// What the map is drawing, so the view picks the message.
enum RouteShown { real, saved, straightLines }

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
    _connectivitySub = ConnectivityRepository.instance.changes.listen((online) {
      if (online && shown == RouteShown.straightLines) loadRoute();
    });
    loadRoute();
  }

  final Plan plan;
  final _repository = RouteRepository();
  late final StreamSubscription<bool> _connectivitySub;

  final List<RouteStop> stops = [];
  final List<Activity> missingLocation = [];

  TravelMode mode = TravelMode.walk;
  PlanRoute? route;
  bool isLoading = false;
  RouteShown shown = RouteShown.straightLines;

  bool get usingStraightLines => shown == RouteShown.straightLines;

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
    notifyListeners();

    final result = await _repository.route(plan.id, stopPoints, mode);
    route = result?.route;
    if (result == null) {
      shown = RouteShown.straightLines;
    } else if (result.saved) {
      shown = RouteShown.saved;
    } else {
      shown = RouteShown.real;
    }

    isLoading = false;
    notifyListeners();
  }

  // The route can finish loading after the view closed.
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub.cancel();
    super.dispose();
  }
}
