import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/services/connectivity_service.dart';

enum ActivitiesTab { liked, private, recommended }

class MyActivitiesViewmodel extends ChangeNotifier {
  final _repository = ActivityRepository();
  late final StreamSubscription<List<Activity>> _ownedSub;
  List<Activity> _owned = [];
  ActivitiesTab currentTab = ActivitiesTab.private;

  late final StreamSubscription<List<Activity>> _likedSub;
  List<Activity> _liked = [];
  List<Activity> _recommended = [];

  final String _uid;
  StreamSubscription<List<Activity>>? _recommendedSub;

  MyActivitiesViewmodel(this._uid) {
    _ownedSub = _repository.ownedActivities(_uid).listen((activities) {
      _owned = activities;
      notifyListeners();
    });

    _likedSub = _repository.likedActivities(_uid).listen((activities) {
      _liked = activities;
      notifyListeners();
    });

    _loadRecommended();
  }

  void _loadRecommended() {
    _recommendedSub?.cancel();
    _recommendedSub = _repository.recommended(_uid).listen((activities) {
      _recommended = activities;
      notifyListeners();
    });
  }

  void _onConnectivityChanged() {
    if (ConnectivityService.instance.isOnline) _loadRecommended();
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
    _recommendedSub?.cancel();
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
