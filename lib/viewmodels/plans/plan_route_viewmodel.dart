import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/route_repository.dart';
import 'package:plansync/model/data/split_outbox_repository.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/invitations.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/model/models/plan_route.dart';

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
  PlanRouteViewModel(this._uid, this.plan, List<Activity> activities) {
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
    _savedStops = List.of(stops);
    _connectivitySub = ConnectivityRepository.instance.changes.listen((online) {
      if (online && shown == RouteShown.straightLines) loadRoute();
    });
    _readOrderPending();
    _queueSub = SplitOutboxRepository.instance.changes.listen((_) {
      _readOrderPending();
      notifyListeners();
    });
    loadRoute();
  }

  final String _uid;
  Plan plan;
  final _repository = RouteRepository();
  late final StreamSubscription<bool> _connectivitySub;
  late final StreamSubscription<void> _queueSub;

  List<RouteStop> _savedStops = [];

  bool orderPending = false;

  bool get canReorder =>
      plan.date.isAfter(DateTime.now()) &&
      plan.rsvpFor(_uid) == RsvpStatus.going;

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

  void _readOrderPending() {
    orderPending = SplitOutboxRepository.instance
        .pendingIdsFor(plan.id)
        .contains('order');
  }

  void _setStops(List<RouteStop> ordered) {
    final renumbered = [
      for (var i = 0; i < ordered.length; i++)
        RouteStop(
          number: i + 1,
          activity: ordered[i].activity,
          point: ordered[i].point,
        ),
    ];
    stops
      ..clear()
      ..addAll(renumbered);
  }

  void moveStop(int oldIndex, int newIndex) {
    final ordered = List.of(stops);
    final stop = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, stop);
    _setStops(ordered);
    loadRoute();
  }

  void cancelReorder() {
    _setStops(_savedStops);
    loadRoute();
  }

  Future<String?> saveOrder() {
    final placed = [for (final s in stops) s.activity.id];
    if (listEquals(placed, [for (final s in _savedStops) s.activity.id])) {
      return Future.value(null);
    }
    final previousPlan = plan;
    final previousStops = _savedStops;
    plan = plan.withActivityIds([
      ...placed,
      ...plan.activityIds.where((id) => !placed.contains(id)),
    ]);
    _savedStops = List.of(stops);

    return _repository
        .saveStopOrder(_uid, plan)
        .then(
          (sent) => sent
              ? 'Route order saved'
              : "Route order saved on your phone. Everyone sees it when "
                    "you're back online.",
        )
        .catchError((Object _) {
          plan = previousPlan;
          _savedStops = previousStops;
          _setStops(previousStops);
          loadRoute();
          return "Couldn't save the new order on your phone. The previous "
              'order is back.';
        });
  }

  int _routeRequest = 0;

  Future<void> loadRoute() async {
    if (stops.length < 2) return;
    isLoading = true;
    notifyListeners();

    final request = ++_routeRequest;
    final result = await _repository.route(plan.id, stopPoints, mode);
    if (request != _routeRequest) return;
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

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub.cancel();
    _queueSub.cancel();
    super.dispose();
  }
}
