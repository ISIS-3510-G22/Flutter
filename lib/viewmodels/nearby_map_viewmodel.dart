import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/services/location_service.dart';
import 'package:plansync/utils/recommendation.dart';

enum NearbyStatus { loading, locationError, error, ready }

class NearbyItem {
  final Plan? plan;
  final Activity? activity;
  final LatLng point;
  final double distanceKm;
  final double affinity;
  final List<String> matchedTags;

  const NearbyItem({
    this.plan,
    this.activity,
    required this.point,
    required this.distanceKm,
    required this.affinity,
    required this.matchedTags,
  });

  bool get isPlan => plan != null;

  String get name {
    if (plan != null) return plan!.name;
    return activity!.name;
  }

  String get id {
    if (plan != null) return 'plan-${plan!.id}';
    return 'activity-${activity!.id}';
  }
}

class NearbyMapViewModel extends ChangeNotifier {
  NearbyMapViewModel(this._userId) {
    load();
  }

  static const radiusOptions = [2.0, 5.0, 10.0];
  static const _maxRecommendations = 5;

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
  List<NearbyItem> items = [];
  List<NearbyItem> recommended = [];
  Set<String> recommendedIds = {};
  bool hasTasteProfile = false;

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
        _planRepository.plansForUser(_userId).first,
        _activityRepository.ownedActivities(_userId).first,
        _activityRepository.likedActivities(_userId).first,
      ]);
      final publicPlans = results[0] as List<Plan>;
      final publicActivities = results[1] as List<Activity>;
      final myPlans = results[2] as List<Plan>;
      final myActivities = results[3] as List<Activity>;
      final likedActivities = results[4] as List<Activity>;

      final profile = buildTagProfile([
        for (final p in myPlans) p.tags,
        for (final a in myActivities) a.tags,
        for (final a in likedActivities) a.tags,
      ]);
      hasTasteProfile = profile.isNotEmpty;

      final upcomingPlans = publicPlans
          .where((p) => _isUpcoming(p) && !_isMine(p))
          .toList();
      final planActivities = await _activitiesOf(upcomingPlans);

      _allItems = [
        for (final plan in upcomingPlans)
          ?_planItem(plan, planActivities, profile),
        for (final activity in publicActivities)
          if (activity.ownerId != _userId) ?_activityItem(activity, profile),
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

  void _applyRadius() {
    items = _allItems.where((i) => i.distanceKm <= radiusKm).toList();
    final scored = [
      for (final i in items)
        (
          item: i,
          score: recommendationScore(
            affinity: i.affinity,
            distanceKm: i.distanceKm,
            radiusKm: radiusKm,
            daysUntil: _daysUntil(i.plan),
          ),
        ),
    ];
    scored.sort((a, b) => b.score.compareTo(a.score));
    recommended = [for (final s in scored.take(_maxRecommendations)) s.item];
    recommendedIds = recommended.map((i) => i.id).toSet();
  }

  bool _isUpcoming(Plan plan) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return !plan.date.isBefore(startOfToday);
  }

  bool _isMine(Plan plan) {
    if (plan.creatorId == _userId) return true;
    return plan.invitations.any((i) => i.userId == _userId);
  }

  int? _daysUntil(Plan? plan) {
    if (plan == null) return null;
    final days = plan.date.difference(DateTime.now()).inDays;
    if (days < 0) return 0;
    return days;
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

  NearbyItem? _planItem(
    Plan plan,
    Map<String, Activity> activitiesById,
    Map<String, double> profile,
  ) {
    for (final id in plan.activityIds) {
      final activity = activitiesById[id];
      if (activity == null) continue;
      final point = _pointOf(activity);
      if (point == null) continue;
      return NearbyItem(
        plan: plan,
        point: point,
        distanceKm: _distanceKm(point),
        affinity: tagAffinity(profile, plan.tags),
        matchedTags: matchingTags(profile, plan.tags),
      );
    }
    return null;
  }

  NearbyItem? _activityItem(Activity activity, Map<String, double> profile) {
    final point = _pointOf(activity);
    if (point == null) return null;
    return NearbyItem(
      activity: activity,
      point: point,
      distanceKm: _distanceKm(point),
      affinity: tagAffinity(profile, activity.tags),
      matchedTags: matchingTags(profile, activity.tags),
    );
  }
}
