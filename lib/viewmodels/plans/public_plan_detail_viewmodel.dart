import 'package:flutter/material.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/plan.dart';

class PublicPlanDetailViewModel extends ChangeNotifier {
  PublicPlanDetailViewModel(this.plan) {
    _load();
  }

  final Plan plan;
  final _activityRepository = ActivityRepository();
  List<Activity> activities = [];
  bool isLoading = true;

  Future<void> _load() async {
    activities = await _activityRepository.getByIds(plan.activityIds);
    isLoading = false;
    notifyListeners();
  }
}
