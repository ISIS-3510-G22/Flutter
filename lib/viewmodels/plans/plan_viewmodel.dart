import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/app_notification.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/plan.dart';

enum PlanTab { upcoming, pendingInvite, past }

class MyPlansViewModel extends ChangeNotifier {
  MyPlansViewModel(this._userId) {
    _sub = _planRepository.plansForUser(_userId).listen((plans) {
      _plans = plans;
      isLoading = false;
      _loadPhotos();
      notifyListeners();
    });
  }

  final String _userId;
  final _planRepository = PlanRepository();
  final _userRepository = UserRepository();

  late final StreamSubscription<List<Plan>> _sub;

  bool isLoading = true;
  PlanTab selectedTab = PlanTab.upcoming;
  List<Plan> _plans = [];

  Map<String, String?> _photoUrls = {};

  Future<void> _loadPhotos() async {
    final ids = _plans
        .expand((p) => p.goingIds.take(2))
        .toSet()
        .take(30)
        .toList();
    final users = await _userRepository.getUsers(ids);
    _photoUrls = {for (final u in users) u.id: u.photoUrl};
    notifyListeners();
  }

  bool isGoing(Plan plan) => plan.rsvpFor(_userId) == RsvpStatus.going;

  List<String?> photoUrlsFor(Plan plan) => [
    for (final id in plan.goingIds.take(2)) _photoUrls[id],
  ];

  static const _lateAfter = Duration(days: 2);

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

  PlanTab? _tabFor(Plan plan) {
    final rsvp = plan.rsvpFor(_userId);
    if (plan.date.isBefore(DateTime.now())) {
      return rsvp == RsvpStatus.going ? PlanTab.past : null;
    }
    return rsvp == RsvpStatus.invited
        ? PlanTab.pendingInvite
        : PlanTab.upcoming;
  }

  AppNotification? notificationFor(Plan plan) {
    final invitation = plan.invitationFor(_userId);
    final invitedAt = invitation?.invitedAt;
    if (invitation?.rsvp != RsvpStatus.invited || invitedAt == null) {
      return null;
    }
    if (DateTime.now().difference(invitedAt) < _lateAfter) return null;
    return AppNotification.rsvpReminder(invitedAt);
  }
}
