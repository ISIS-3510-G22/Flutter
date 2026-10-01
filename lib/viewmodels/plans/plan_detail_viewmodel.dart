import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/data/friend_repository.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/models/user.dart';

class PlanDetailViewModel extends ChangeNotifier {
  PlanDetailViewModel(this.plan, this._uid) {
    _sub = _planRepository.planById(plan.id).listen(_onPlanUpdate);
  }

  final _planRepository = PlanRepository();
  final _activityRepository = ActivityRepository();
  final _userRepository = UserRepository();
  final _friendRepository = FriendRepository();
  late final StreamSubscription<Plan> _sub;

  final String _uid;
  Plan plan;
  List<Activity> activities = [];
  List<User> invitees = [];
  bool isLoading = true;
  bool showInvitees = true;

  bool get isCreator => plan.creatorId == _uid;

  RsvpStatus? get myRsvp => plan.rsvpFor(_uid);

  List<User> get participants =>
      invitees.where((u) => plan.rsvpFor(u.id) == RsvpStatus.going).toList();

  void setShowInvitees(bool value) {
    showInvitees = value;
    notifyListeners();
  }

  Future<void> setPublic(bool value) =>
      _planRepository.setPublic(plan.id, value);

  Future<void> _onPlanUpdate(Plan updated) async {
    plan = updated;
    final userIds = updated.invitations.map((i) => i.userId).toList();
    activities = await _activityRepository.getByIds(updated.activityIds);
    if (!setEquals(tags, updated.tags.toSet())) {
      _planRepository.updateTags(updated.id, tags);
    }
    invitees = await _userRepository.getUsers(userIds);
    isLoading = false;
    notifyListeners();
  }

  Set<String> get tags => activities.expand((a) => a.tags).toSet();

  double get estimatedCostPerPerson {
    if (activities.isEmpty || participants.isEmpty) return 0;
    final total = activities.fold<double>(0, (sum, a) => sum + a.expectedPrice);
    return total / participants.length;
  }

  Future<void> addActivity(String activityId) {
    return _planRepository.addActivity(plan.id, activityId);
  }

  int get isActive => plan.date.compareTo(DateTime.now());

  Future<List<User>> invitableFriends() async {
    final invited = plan.invitations.map((i) => i.userId).toSet();
    final friends = await _friendRepository.friendsForUser(_uid).first;
    return friends.where((f) => !invited.contains(f.id)).toList();
  }

  Future<void> invite(List<String> userIds) =>
      _planRepository.invite(plan.id, userIds);

  Future<bool> respondRsvp(bool going) async {
    try {
      await _planRepository.setRsvp(
        plan.id,
        _uid,
        going ? RsvpStatus.going : RsvpStatus.notGoing,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
