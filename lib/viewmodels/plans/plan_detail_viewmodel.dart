import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/models/user.dart';

class PlanDetailViewModel extends ChangeNotifier {
  PlanDetailViewModel(Plan plan) : plan = plan {
    _sub = _planRepository.planById(plan.id).listen(_onPlanUpdate);
  }

  final _planRepository = PlanRepository();
  final _activityRepository = ActivityRepository();
  final _userRepository = UserRepository();
  late final StreamSubscription<Plan> _sub;

  Plan plan;
  List<Activity> activities = [];
  List<User> participants = [];
  bool isLoading = true;

  Future<void> _onPlanUpdate(Plan updated) async {
    plan = updated;
    final userIds = updated.invitations.map((i) => i.userId).toList();
    activities = await _activityRepository.getByIds(updated.activityIds);
    if (!setEquals(tags, updated.tags.toSet())) {
      _planRepository.updateTags(updated.id, tags);
    }
    participants = await _userRepository.getUsers(userIds);
    isLoading = false;
    notifyListeners();
  }

  Set<String> get tags => activities.expand((a) => a.tags).toSet();

  double get estimatedCostPerPerson {
    if (activities.isEmpty || participants.isEmpty) return 0;
    final total = activities.fold<double>(0, (sum, a) => sum + a.expectedPrice);
    return total / participants.length;
  }

  Future<void> addActivity(String activityId) {
    return _planRepository.addActivity(plan.id, activityId);
  }

  int get isActive => plan.date.compareTo(DateTime.now());

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
