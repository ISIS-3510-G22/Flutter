import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/models/activity.dart';

enum ActivitiesTab { liked, private, recommended }

class MyActivitiesViewmodel extends ChangeNotifier {
  final _repository = ActivityRepository();
  late final StreamSubscription<List<Activity>> _ownedSub;
  List<Activity> _owned = [];
  ActivitiesTab currentTab = ActivitiesTab.private;

  late final StreamSubscription<List<Activity>> _likedSub;
  List<Activity> _liked = [];
  List<Activity> _recommended = [];

  MyActivitiesViewmodel(String uid) {
    _ownedSub = _repository.ownedActivities(uid).listen((activities) {
      _owned = activities;
      notifyListeners();
    });

    _likedSub = _repository.likedActivities(uid).listen((activities) {
      _liked = activities;
      notifyListeners();
    });

    _repository.recommended(uid).then((activities) {
      _recommended = activities;
      notifyListeners();
    }, onError: (_) {});
  }

  void selectTab(ActivitiesTab tab) {
    currentTab = tab;
    notifyListeners();
  }

  List<Activity> get activities => switch (currentTab) {
    ActivitiesTab.liked => _liked,
    ActivitiesTab.private => _owned,
    ActivitiesTab.recommended => _recommended,
  };

  @override
  void dispose() {
    _ownedSub.cancel();
    _likedSub.cancel();
    super.dispose();
  }
}
