import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/explore_plan.dart';

class ExploreSnapshot {
  final List<ExplorePlan> plans;
  final List<Activity> activities;
  final Map<String, Activity> planActivities;
  final List<String> recommendedIds;

  const ExploreSnapshot({
    required this.plans,
    required this.activities,
    required this.planActivities,
    required this.recommendedIds,
  });

  Map<String, dynamic> toJson() => {
    'plans': [for (final p in plans) p.toJson()],
    'activities': [for (final a in activities) a.toJson()],
    'planActivities': {
      for (final entry in planActivities.entries)
        entry.key: entry.value.toJson(),
    },
    'recommendedIds': recommendedIds,
  };

  factory ExploreSnapshot.fromJson(Map<String, dynamic> json) =>
      ExploreSnapshot(
        plans: [
          for (final p in json['plans'] as List)
            ExplorePlan.fromJson(p as Map<String, dynamic>),
        ],
        activities: [
          for (final a in json['activities'] as List)
            Activity.fromJson(a as Map<String, dynamic>),
        ],
        planActivities: {
          for (final entry
              in (json['planActivities'] as Map<String, dynamic>).entries)
            entry.key: Activity.fromJson(entry.value as Map<String, dynamic>),
        },
        recommendedIds: (json['recommendedIds'] as List).cast<String>(),
      );
}
