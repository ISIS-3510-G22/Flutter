import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/data/review_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/plan.dart';

class ExplorePlan {
  final Plan plan;
  final double totalCost;
  final double? rating;
  final String? photoUrl;

  const ExplorePlan({
    required this.plan,
    required this.totalCost,
    required this.rating,
    required this.photoUrl,
  });
}

class ExploreRepository {
  final _planRepository = PlanRepository();
  final _activityRepository = ActivityRepository();
  final _reviewRepository = ReviewRepository();

  /// Public plans that haven't happened yet, soonest first.
  Future<List<ExplorePlan>> getPlans() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final plans = (await _planRepository.publicPlans())
        .where((p) => !p.date.isBefore(startOfToday))
        .toList();
    plans.sort((a, b) => a.date.compareTo(b.date));

    final activities = await _activitiesOf(plans);
    final ratings = await Future.wait(plans.map((p) => _averageRating(p.id)));

    return [
      for (var i = 0; i < plans.length; i++)
        _toExplorePlan(plans[i], activities, ratings[i]),
    ];
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

  /// Public activities, alphabetically. They are not ranked by
  /// recommendations.
  Future<List<Activity>> getActivities() async {
    final activities = await _activityRepository.publicActivities();
    activities.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return activities;
  }

  /// Plan IDs the analytics pipeline recommends to [uid], best first. A
  /// failure here only means no recommendations, never an empty feed.
  Future<List<String>> recommendedPlanIds(String uid) async {
    try {
      return await _planRepository.recommendedPlanIds(uid);
    } catch (_) {
      return [];
    }
  }

  Future<double?> _averageRating(String planId) async {
    final reviews = await _reviewRepository.reviewsForPlan(planId);
    if (reviews.isEmpty) return null;
    final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
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
}
