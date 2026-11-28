import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/pending_write_repository.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/data/review_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/app_notification.dart';
import 'package:plansync/model/models/invitations.dart';
import 'package:plansync/model/models/plan.dart';

enum PlanTab { upcoming, pendingInvite, past }

class MyPlansViewModel extends ChangeNotifier {
  MyPlansViewModel(this._userId) {
    _queueSub = PendingWriteRepository.instance.changes.listen(
      (_) => _loadPlans(),
    );
    _loadPlans();
  }

  final String _userId;
  final _planRepository = PlanRepository();
  final _userRepository = UserRepository();
  final _reviewRepository = ReviewRepository();

  final reviewedIds = <String>{};

  StreamSubscription<List<Plan>>? _sub;
  late final StreamSubscription<void> _queueSub;

  bool isLoading = true;
  PlanTab selectedTab = PlanTab.upcoming;
  List<Plan> _plans = [];

  Map<String, String?> _photoUrls = {};

  Set<String> get pendingIds => PendingWriteRepository.instance.pendingDocIds;

  void _loadPlans() {
    _sub?.cancel();
    _sub = _planRepository.plansForUser(_userId).listen((plans) {
      _plans = plans;
      isLoading = false;
      _loadPhotos();
      notifyListeners();
    });
  }

  Future<void> _loadPhotos() async {
    final ids = _plans
        .expand((p) => p.goingIds.take(2))
        .toSet()
        .take(30)
        .toList();
    try {
      final users = await _userRepository.getUsers(ids);
      _photoUrls = {for (final u in users) u.id: u.photoUrl};
      notifyListeners();
    } catch (_) {}
  }

  bool isGoing(Plan plan) => plan.rsvpFor(_userId) == RsvpStatus.going;

  List<String?> photoUrlsFor(Plan plan) => [
    for (final id in plan.goingIds.take(2)) _photoUrls[id],
  ];

  static const _lateAfter = Duration(days: 2);

  List<Plan> get visiblePlans =>
      _plans.where((p) => _tabFor(p) == selectedTab).toList();

  void selectTab(PlanTab tab) {
    selectedTab = tab;
    notifyListeners();
    if (tab == PlanTab.past) _loadReviews();
  }

  Future<void> _loadReviews() async {
    final unchecked = visiblePlans
        .where((p) => !reviewedIds.contains(p.id))
        .toList();
    final reviews = await Future.wait(
      unchecked.map((p) => _reviewRepository.reviewBy(p.id, _userId)),
    );
    for (var i = 0; i < unchecked.length; i++) {
      if (reviews[i] != null) reviewedIds.add(unchecked[i].id);
    }
    notifyListeners();
  }

  void markReviewed(String planId) {
    reviewedIds.add(planId);
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

  @override
  void dispose() {
    _sub?.cancel();
    _queueSub.cancel();
    super.dispose();
  }
}
