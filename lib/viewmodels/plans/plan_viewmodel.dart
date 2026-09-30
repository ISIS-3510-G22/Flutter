import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/plan.dart';

enum PlanTab { upcoming, pendingInvite, past }

class MyPlansViewModel extends ChangeNotifier {
  MyPlansViewModel(this._userId) {
    _sub = _planRepository.plansForUser(_userId).listen((plans) {
      _plans = plans;
      isLoading = false;
      notifyListeners();
    });
  }

  final String _userId;
  final _planRepository = PlanRepository();
  late final StreamSubscription<List<Plan>> _sub;

  bool isLoading = true;
  PlanTab selectedTab = PlanTab.upcoming;
  List<Plan> _plans = [];

  bool isGoing(Plan plan) => plan.rsvpFor(_userId) == RsvpStatus.going;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  List<Plan> get visiblePlans =>
      _plans.where((p) => _tabFor(p) == selectedTab).toList();

  void selectTab(PlanTab tab) {
    selectedTab = tab;
    notifyListeners();
  }

  PlanTab _tabFor(Plan plan) {
    if (plan.date.isBefore(DateTime.now())) return PlanTab.past;
    return plan.rsvpFor(_userId) == RsvpStatus.invited
        ? PlanTab.pendingInvite
        : PlanTab.upcoming;
  }
}
