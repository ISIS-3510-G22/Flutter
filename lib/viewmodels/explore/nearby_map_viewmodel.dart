import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/explore_repository.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/explore_snapshot.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/model/services/location_service.dart';

enum NearbyStatus { loading, locationError, neverSaved, ready }

class NearbyItem {
  final Plan? plan;
  final Activity? activity;
  final LatLng point;
  final double distanceKm;

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
    _connectivitySub = ConnectivityRepository.instance.changes.listen((online) {
      if (online && position != null) _loadSnapshot();
    });
    load();
  }

  static const radiusOptions = [2.0, 5.0, 10.0];
  static const _defaultRadiusKm = 5.0;

  final String _userId;
  final _locationService = LocationService();
  final _repository = ExploreRepository();
  final _distance = const Distance();
  late final StreamSubscription<bool> _connectivitySub;
  StreamSubscription<ExploreSnapshot>? _snapshotSub;

  NearbyStatus status = NearbyStatus.loading;
  LocationError? locationError;
  LatLng? position;
  double radiusKm = _defaultRadiusKm;

  List<NearbyItem> _allItems = [];
  Map<String, int> _recommendedRank = {};

  List<NearbyItem> items = [];

  List<NearbyItem> nearbyPlans = [];

  Future<void> load() async {
    status = NearbyStatus.loading;
    locationError = null;
    notifyListeners();

    final savedRadius = await _repository.savedRadiusKm();
    if (radiusOptions.contains(savedRadius)) radiusKm = savedRadius!;

    try {
      final location = await _locationService.currentPosition();
      if (location.error != null) {
        locationError = location.error;
        status = NearbyStatus.locationError;
        notifyListeners();
        return;
      }
      position = location.position;
    } catch (_) {
      status = NearbyStatus.locationError;
      notifyListeners();
      return;
    }
    _loadSnapshot();
  }

  void _loadSnapshot() {
    _snapshotSub?.cancel();
    _snapshotSub = _repository
        .snapshot(_userId)
        .listen(
          _show,
          onDone: () {
            if (status == NearbyStatus.loading) {
              status = NearbyStatus.neverSaved;
            }
            notifyListeners();
          },
        );
  }

  void _show(ExploreSnapshot snapshot) {
    _recommendedRank = {
      for (var i = 0; i < snapshot.recommendedIds.length; i++)
        snapshot.recommendedIds[i]: i,
    };
    _allItems = [
      for (final item in snapshot.plans)
        ?_planItem(item.plan, snapshot.planActivities),
      for (final activity in snapshot.activities) ?_activityItem(activity),
    ];
    _applyRadius();
    status = NearbyStatus.ready;
    notifyListeners();
  }

  void selectRadius(double km) {
    radiusKm = km;
    _applyRadius();
    notifyListeners();
    unawaited(_repository.saveRadiusKm(km));
  }

  Future<void> openSettings() {
    if (locationError == LocationError.serviceDisabled) {
      return _locationService.openLocationSettings();
    }
    return _locationService.openSettings();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _snapshotSub?.cancel();
    super.dispose();
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

  LatLng? _pointOf(Activity activity) {
    final lat = activity.lat;
    final lng = activity.lng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  double _distanceKm(LatLng point) =>
      _distance.as(LengthUnit.Meter, position!, point) / 1000;

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
