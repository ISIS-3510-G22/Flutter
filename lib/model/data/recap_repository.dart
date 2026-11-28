import 'dart:isolate';

import 'package:plansync/model/data/activity_repository.dart';
import 'package:plansync/model/data/cache/recap_cache.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/logic/recap.dart';
import 'package:plansync/model/models/invitations.dart';
import 'package:plansync/model/models/month_recap.dart';
import 'package:plansync/model/services/local/recap_local_store.dart';

class RecapRepository {
  static final _cache = RecapCache();

  static void clearCache() => _cache.clear();

  final _plans = PlanRepository();
  final _activities = ActivityRepository();
  final _local = RecapLocalStore();

  Future<MonthRecap?> recap(
    String uid,
    String month, {
    bool refresh = false,
  }) async {
    if (!refresh) {
      final cached = _cache.get(month);
      if (cached != null) return cached;
    }
    try {
      ConnectivityRepository.instance.ensureOnline();
      final plans = (await _plans.serverPlans(uid))
          .where(
            (p) =>
                p.rsvpFor(uid) == RsvpStatus.going && monthKey(p.date) == month,
          )
          .toList();
      final ids = plans.expand((p) => p.activityIds).toSet().toList();
      final activities = await _activities.serverActivities(uid, ids);
      final recap = await Isolate.run(
        () => buildRecap(month, plans, activities),
      );
      await _local.save(uid, recap);
      _cache.put(recap);
      return recap;
    } catch (_) {
      return _local.read(uid, month);
    }
  }
}
