import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/activity_repository.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/local/json_file_store.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/data/review_repository.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/explore_filters.dart';
import 'package:plansync/model/models/explore_plan.dart';
import 'package:plansync/model/models/explore_snapshot.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExploreRepository {
  final _planRepository = PlanRepository();
  final _activityRepository = ActivityRepository();
  final _reviewRepository = ReviewRepository();
  final _connectivity = ConnectivityRepository.instance;
  final _files = JsonFileStore();
  final _prefs = SharedPreferencesAsync();

  static const _snapshotFile = 'explore.json';
  static const _tagKey = 'explore_tag';
  static const _dateKey = 'explore_date';
  static const _priceKey = 'explore_price';
  static const _ratingKey = 'explore_rating';
  static const _radiusKey = 'map_radius_km';

  /// Strategy 5: the saved snapshot first (if any), then the server's.
  /// If the server load fails the stream just ends, so the saved one stays.
  Stream<ExploreSnapshot> snapshot(String uid) async* {
    final saved = await savedSnapshot();
    if (saved != null) yield saved;
    try {
      _connectivity.ensureOnline();
      final fresh = await _snapshotFromServer(uid);
      await _files.write(_snapshotFile, jsonEncode(fresh.toJson()));
      yield fresh;
    } catch (_) {}
  }

  /// `null` means Explore was never loaded online on this phone.
  Future<ExploreSnapshot?> savedSnapshot() async {
    final text = await _files.read(_snapshotFile);
    if (text == null) return null;
    try {
      final saved = ExploreSnapshot.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
      return ExploreSnapshot(
        plans: saved.plans.where((p) => _isUpcoming(p.plan)).toList(),
        activities: saved.activities,
        planActivities: saved.planActivities,
        recommendedIds: saved.recommendedIds,
      );
    } catch (_) {
      return null;
    }
  }

  /// Server first; offline or on failure, the activities saved in the
  /// snapshot. `null` when nothing was ever saved.
  Future<List<Activity>?> planActivities(Plan plan) async {
    Map<String, Activity> byId;
    try {
      _connectivity.ensureOnline();
      byId = await _activitiesOf([plan]);
    } catch (_) {
      final saved = await savedSnapshot();
      if (saved == null) return null;
      byId = saved.planActivities;
    }
    return [for (final id in plan.activityIds) ?byId[id]];
  }

  Future<ExploreSnapshot> _snapshotFromServer(String uid) async {
    final results = await Future.wait([
      _planRepository.publicPlans(),
      _activityRepository.publicActivities(),
      _recommendedPlanIds(uid),
    ]);
    final plans = (results[0] as List<Plan>).where(_isUpcoming).toList();
    plans.sort((a, b) => a.date.compareTo(b.date));
    final activities = results[1] as List<Activity>;
    activities.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    final planActivities = await _activitiesOf(plans);
    final ratings = await Future.wait(plans.map((p) => _averageRating(p.id)));

    return ExploreSnapshot(
      plans: [
        for (var i = 0; i < plans.length; i++)
          _toExplorePlan(plans[i], planActivities, ratings[i]),
      ],
      activities: activities,
      planActivities: planActivities,
      recommendedIds: results[2] as List<String>,
    );
  }

  ExplorePlan _toExplorePlan(
    Plan plan,
    Map<String, Activity> activitiesById,
    double? rating,
  ) {
    var totalCost = 0.0;
    String? photoUrl;
    for (final id in plan.activityIds) {
      final activity = activitiesById[id];
      if (activity == null) continue;
      totalCost += activity.expectedPrice;
      if (photoUrl == null && activity.photoUrl != null) {
        photoUrl = activity.photoUrl;
      }
    }
    return ExplorePlan(
      plan: plan,
      totalCost: totalCost,
      rating: rating,
      photoUrl: photoUrl,
    );
  }

  bool _isUpcoming(Plan plan) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return !plan.date.isBefore(startOfToday);
  }

  Future<List<String>> _recommendedPlanIds(String uid) async {
    try {
      return await _planRepository.recommendedPlanIds(uid);
    } catch (_) {
      return [];
    }
  }

  Future<double?> _averageRating(String planId) async {
    final reviews = await _reviewRepository.reviewsForPlan(planId);
    if (reviews.isEmpty) return null;
    final total = reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return total / reviews.length;
  }

  Future<Map<String, Activity>> _activitiesOf(List<Plan> plans) async {
    final ids = plans.expand((p) => p.activityIds).toSet().toList();
    final byId = <String, Activity>{};
    for (var i = 0; i < ids.length; i += 30) {
      var end = i + 30;
      if (end > ids.length) end = ids.length;
      final chunk = await _activityRepository
          .getByIds(ids.sublist(i, end), source: Source.server)
          .timeout(const Duration(seconds: 8));
      for (final a in chunk) {
        byId[a.id] = a;
      }
    }
    return byId;
  }

  Future<ExploreFilters> savedFilters() async => ExploreFilters(
    tag: await _prefs.getString(_tagKey),
    when: await _prefs.getString(_dateKey),
    price: await _prefs.getString(_priceKey),
    rating: await _prefs.getString(_ratingKey),
  );

  Future<void> saveFilters(ExploreFilters filters) async {
    await _saveOrRemove(_tagKey, filters.tag);
    await _saveOrRemove(_dateKey, filters.when);
    await _saveOrRemove(_priceKey, filters.price);
    await _saveOrRemove(_ratingKey, filters.rating);
  }

  Future<double?> savedRadiusKm() => _prefs.getDouble(_radiusKey);

  Future<void> saveRadiusKm(double km) => _prefs.setDouble(_radiusKey, km);

  Future<void> _saveOrRemove(String key, String? value) {
    if (value == null) return _prefs.remove(key);
    return _prefs.setString(key, value);
  }
}
