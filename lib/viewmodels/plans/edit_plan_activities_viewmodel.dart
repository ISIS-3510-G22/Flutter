import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/activity_repository.dart';
import 'package:plansync/model/data/pending_write_repository.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/pending_write.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/viewmodels/activities/my_activities_viewmodel.dart';

class EditPlanActivitiesViewModel extends ChangeNotifier {
  EditPlanActivitiesViewModel(this._plan, this._uid) {
    _subOwned = _activityRepository.ownedActivities(_uid).listen((activities) {
      ownedActivities = activities;
      notifyListeners();
    });
    _subLiked = _activityRepository.likedActivities(_uid).listen((activities) {
      likedActivities = activities;
      notifyListeners();
    });
  }

  Plan _plan;
  final String _uid;
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

  bool isAdded(Activity activity) => _plan.activityIds.contains(activity.id);

  Future<bool> toggleActivity(Activity activity) {
    final adding = !isAdded(activity);
    final before = _plan;
    _plan = _plan.withActivityIds([
      for (final id in _plan.activityIds)
        if (id != activity.id) id,
      if (adding) activity.id,
    ]);
    notifyListeners();

    return _planRepository
        .saveLocal(_uid, _plan)
        .then(
          (_) => PendingWriteRepository.instance.submit(
            PendingWrite(
              kind: adding
                  ? WriteKind.planAddActivity
                  : WriteKind.planRemoveActivity,
              docId: _plan.id,
              payload: {'activityId': activity.id},
            ),
          ),
        )
        .then((sent) => !sent)
        .catchError((_) {
          _plan = before;
          notifyListeners();
          return false;
        });
  }

  @override
  void dispose() {
    _subOwned.cancel();
    _subLiked.cancel();
    super.dispose();
  }
}
