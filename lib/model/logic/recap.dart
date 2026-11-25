import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/month_recap.dart';
import 'package:plansync/model/models/plan.dart';

String monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

MonthRecap buildRecap(
  String month,
  List<Plan> plans,
  List<Activity> activities,
) {
  final byId = {for (final a in activities) a.id: a};
  final times = <String, int>{};
  final tagCounts = <String, int>{};
  var count = 0;
  var spend = 0.0;

  for (final plan in plans) {
    for (final id in plan.activityIds) {
      final activity = byId[id];
      if (activity == null) continue;
      count++;
      spend += activity.expectedPrice;
      times[id] = (times[id] ?? 0) + 1;
      for (final tag in activity.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
  }

  final topTags = tagCounts.keys.toList()
    ..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));

  final places = [
    for (final entry in times.entries)
      (activity: byId[entry.key]!, times: entry.value),
  ]..sort((a, b) => b.times.compareTo(a.times));

  return MonthRecap(
    month: month,
    plans: plans.length,
    activities: count,
    spend: spend,
    topTags: topTags.take(3).toList(),
    places: places,
    updatedAt: DateTime.now(),
  );
}
