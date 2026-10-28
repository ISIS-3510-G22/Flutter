import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/activity_repository.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/pending_write_repository.dart';
import 'package:plansync/model/models/activity.dart';

enum ActivitiesTab { liked, private, recommended }

class MyActivitiesViewmodel extends ChangeNotifier {
  final _repository = ActivityRepository();

  StreamSubscription<List<Activity>>? _ownedSub;
  late final StreamSubscription<bool> _connectivitySub;
  late final StreamSubscription<void> _queueSub;
  List<Activity> _owned = [];
  ActivitiesTab currentTab = ActivitiesTab.private;

  StreamSubscription<List<Activity>>? _likedSub;
  List<Activity> _liked = [];
  List<Activity> _recommended = [];

  final String _uid;
  StreamSubscription<List<Activity>>? _recommendedSub;

  MyActivitiesViewmodel(this._uid) {
    _connectivitySub = ConnectivityRepository.instance.changes.listen(
      _onConnectivityChanged,
    );
    _queueSub = PendingWriteRepository.instance.changes.listen(
      (_) => _loadSaved(),
    );

    _loadSaved();

    _loadRecommended();
  }

  Set<String> get pendingIds => PendingWriteRepository.instance.pendingDocIds;

  void _loadRecommended() {
    _recommendedSub?.cancel();
    _recommendedSub = _repository.recommended(_uid).listen((activities) {
      _recommended = activities;
      notifyListeners();
    });
  }

  void _loadSaved() {
    _ownedSub?.cancel();
    _ownedSub = _repository.ownedActivities(_uid).listen((activities) {
      _owned = activities;
      notifyListeners();
    });
    _likedSub?.cancel();
    _likedSub = _repository.likedActivities(_uid).listen((activities) {
      _liked = activities;
      notifyListeners();
    });
  }

  void _onConnectivityChanged(bool online) {
    if (online) _loadRecommended();
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
    _ownedSub?.cancel();
    _likedSub?.cancel();
    _recommendedSub?.cancel();
    _connectivitySub.cancel();
    _queueSub.cancel();
    super.dispose();
  }
}
