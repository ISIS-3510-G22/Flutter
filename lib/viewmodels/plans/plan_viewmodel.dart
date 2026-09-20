import 'package:flutter/material.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/plan.dart';

enum PlanTab { upcoming, pendingInvite, past }

class MyPlansViewModel extends ChangeNotifier {
  MyPlansViewModel(this._userId) {
    _load();
  }

  final String _userId;
  final _planRepository = PlanRepository();

  bool isLoading = true;
  PlanTab selectedTab = PlanTab.upcoming;
  List<Plan> _plans = [];

  List<Plan> get visiblePlans =>
      _plans.where((p) => _tabFor(p) == selectedTab).toList();

  void selectTab(PlanTab tab) {
    selectedTab = tab;
    notifyListeners();
  }

  RsvpStatus rsvpFor(Plan plan) {
    return plan.invitations
        .firstWhere(
          (i) => i.userId == _userId,
          orElse: () => Invitation(userId: _userId, rsvp: RsvpStatus.going),
        )
        .rsvp;
  }

  PlanTab _tabFor(Plan plan) {
    if (plan.date.isBefore(DateTime.now())) return PlanTab.past;
    return rsvpFor(plan) == RsvpStatus.invited
        ? PlanTab.pendingInvite
        : PlanTab.upcoming;
  }

  Future<void> _load() async {
    _plans = await _planRepository.getPlansForUser(_userId);
    isLoading = false;
    notifyListeners();
  }
}
