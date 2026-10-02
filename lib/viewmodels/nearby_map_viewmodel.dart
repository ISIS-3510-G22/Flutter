import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/services/location_service.dart';

enum NearbyStatus { loading, locationError, error, ready }

class NearbyItem {
  final Plan? plan;
  final Activity? activity;
  final LatLng point;
  final double distanceKm;

  /// Recommended by the analytics pipeline (plans only).
  final bool isRecommended;

  const NearbyItem({
    this.plan,
    this.activity,
    required this.point,
    required this.distanceKm,
    this.isRecommended = false,
  });

  bool get isPlan => plan != null;

  String get name {
    if (plan != null) return plan!.name;
    return activity!.name;
  }
}

class NearbyMapViewModel extends ChangeNotifier {
  NearbyMapViewModel(this._userId) {
    load();
  }

  static const radiusOptions = [2.0, 5.0, 10.0];

  final String _userId;
  final _locationService = LocationService();
  final _planRepository = PlanRepository();
  final _activityRepository = ActivityRepository();
  final _distance = const Distance();

  NearbyStatus status = NearbyStatus.loading;
  LocationError? locationError;
  LatLng? position;
  double radiusKm = 5;

  List<NearbyItem> _allItems = [];
  Map<String, int> _recommendedRank = {};

  /// Everything inside the radius, shown as markers.
  List<NearbyItem> items = [];

  /// Plans inside the radius: recommended ones first (pipeline order), then
  /// the rest by distance.
  List<NearbyItem> nearbyPlans = [];

  Future<void> load() async {
    status = NearbyStatus.loading;
    locationError = null;
    notifyListeners();

    try {
      final location = await _locationService.currentPosition();
      if (location.error != null) {
        locationError = location.error;
        status = NearbyStatus.locationError;
        notifyListeners();
        return;
      }
      position = location.position;

      final results = await Future.wait([
        _planRepository.publicPlans(),
        _activityRepository.publicActivities(),
        _recommendedPlanIds(),
      ]);
      final publicPlans = results[0] as List<Plan>;
      final publicActivities = results[1] as List<Activity>;
      final recommended = results[2] as List<String>;
      _recommendedRank = {
        for (var i = 0; i < recommended.length; i++) recommended[i]: i,
      };

      final upcomingPlans = publicPlans.where(_isUpcoming).toList();
      final planActivities = await _activitiesOf(upcomingPlans);

      _allItems = [
        for (final plan in upcomingPlans) ?_planItem(plan, planActivities),
        for (final activity in publicActivities) ?_activityItem(activity),
      ];
      _applyRadius();
      status = NearbyStatus.ready;
    } catch (_) {
      status = NearbyStatus.error;
    }
    notifyListeners();
  }

  void selectRadius(double km) {
    radiusKm = km;
    _applyRadius();
    notifyListeners();
  }

  Future<void> openSettings() {
    if (locationError == LocationError.serviceDisabled) {
      return _locationService.openLocationSettings();
    }
    return _locationService.openSettings();
  }

  /// A failure here only means no recommendations, never an empty map.
  Future<List<String>> _recommendedPlanIds() async {
    try {
      return await _planRepository.recommendedPlanIds(_userId);
    } catch (_) {
      return [];
    }
  }

  void _applyRadius() {
    items = _allItems.where((i) => i.distanceKm <= radiusKm).toList();
    nearbyPlans = items.where((i) => i.isPlan).toList();
    nearbyPlans.sort((a, b) {
      final rankA = _recommendedRank[a.plan!.id];
      final rankB = _recommendedRank[b.plan!.id];
      if (rankA != null && rankB != null) return rankA.compareTo(rankB);
      if (rankA != null) return -1;
      if (rankB != null) return 1;
      return a.distanceKm.compareTo(b.distanceKm);
    });
  }

  bool _isUpcoming(Plan plan) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return !plan.date.isBefore(startOfToday);
  }

  Future<Map<String, Activity>> _activitiesOf(List<Plan> plans) async {
    final ids = plans.expand((p) => p.activityIds).toSet().toList();
    final byId = <String, Activity>{};
    for (var i = 0; i < ids.length; i += 30) {
      var end = i + 30;
      if (end > ids.length) end = ids.length;
      final chunk = await _activityRepository.getByIds(ids.sublist(i, end));
      for (final a in chunk) {
        byId[a.id] = a;
      }
    }
    return byId;
  }

  LatLng? _pointOf(Activity activity) {
    final lat = activity.lat;
    final lng = activity.lng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  double _distanceKm(LatLng point) =>
      _distance.as(LengthUnit.Meter, position!, point) / 1000;

  /// A plan is placed at its first activity that has a location.
  NearbyItem? _planItem(Plan plan, Map<String, Activity> activitiesById) {
    for (final id in plan.activityIds) {
      final activity = activitiesById[id];
      if (activity == null) continue;
      final point = _pointOf(activity);
      if (point == null) continue;
      return NearbyItem(
        plan: plan,
        point: point,
        distanceKm: _distanceKm(point),
        isRecommended: _recommendedRank.containsKey(plan.id),
      );
    }
    return null;
  }

  NearbyItem? _activityItem(Activity activity) {
    final point = _pointOf(activity);
    if (point == null) return null;
    return NearbyItem(
      activity: activity,
      point: point,
      distanceKm: _distanceKm(point),
    );
  }
}
