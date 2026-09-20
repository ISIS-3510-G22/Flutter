import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/viewmodels/activities/my_activities_viewmodel.dart';

class AddActivityToPlanViewModel extends ChangeNotifier {
  AddActivityToPlanViewModel(this._planId, this._addedIds, String uid) {
    _subOwned = _activityRepository.ownedActivities(uid).listen((activities) {
      ownedActivities = activities;
      notifyListeners();
    });
    _subLiked = _activityRepository.likedActivities(uid).listen((activities) {
      likedActivities = activities;
      notifyListeners();
    });
  }

  final String _planId;
  final List<String> _addedIds;
  final _activityRepository = ActivityRepository();
  final _planRepository = PlanRepository();
  late final StreamSubscription<List<Activity>> _subOwned;
  late final StreamSubscription<List<Activity>> _subLiked;

  List<Activity> ownedActivities = [];
  List<Activity> likedActivities = [];

  ActivitiesTab currentTab = ActivitiesTab.private;

  void selectTab(ActivitiesTab tab) {
    currentTab = tab;
    notifyListeners();
  }

  List<Activity> get activities =>
      currentTab == ActivitiesTab.liked ? likedActivities : ownedActivities;

  bool isAdded(Activity activity) => _addedIds.contains(activity.id);

  Future<void> toggleActivity(Activity activity) {
    if (isAdded(activity)) {
      _addedIds.remove(activity.id);
      notifyListeners();
      return _planRepository.removeActivity(_planId, activity.id);
    }
    _addedIds.add(activity.id);
    notifyListeners();
    return _planRepository.addActivity(_planId, activity.id);
  }

  @override
  void dispose() {
    _subOwned.cancel();
    _subLiked.cancel();
    super.dispose();
  }
}
