import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/explore_repository.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/plan.dart';

class PublicPlanDetailViewModel extends ChangeNotifier {
  PublicPlanDetailViewModel(this.plan) {
    _connectivitySub = ConnectivityRepository.instance.changes.listen((online) {
      if (online) _load();
    });
    _load();
  }

  final Plan plan;
  final _repository = ExploreRepository();
  late final StreamSubscription<bool> _connectivitySub;

  /// `null` until loaded, and also when offline with no saved Explore snapshot.
  List<Activity>? activities;
  bool isLoading = true;

  Future<void> _load() async {
    try {
      final loaded = await _repository.planActivities(plan);
      if (loaded != null) activities = loaded;
    } catch (_) {
      // Keep whatever is on screen.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }
}
