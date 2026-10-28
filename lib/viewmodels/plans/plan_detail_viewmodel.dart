import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/model/data/activity_repository.dart';
import 'package:plansync/model/data/friend_repository.dart';
import 'package:plansync/model/data/group_repository.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/group.dart';
import 'package:plansync/model/models/invitations.dart';
import 'package:plansync/model/models/invite_suggestion.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/pending_write_service.dart';

class PlanDetailViewModel extends ChangeNotifier {
  PlanDetailViewModel(this.plan, this._uid) {
    PendingWriteService.instance.addListener(_loadSaved);
    _onPlanUpdate(plan);
    _sub = _planRepository.planById(plan.id).listen(_onPlanUpdate);
    loadSuggestions();
  }

  final _planRepository = PlanRepository();
  final _activityRepository = ActivityRepository();
  final _userRepository = UserRepository();
  final _friendRepository = FriendRepository();
  final _groupRepository = GroupRepository();
  late final StreamSubscription<Plan> _sub;

  final String _uid;
  Plan plan;
  List<Activity> activities = [];
  List<User> invitees = [];
  bool isLoading = true;
  bool showInvitees = true;

  bool get isCreator => plan.creatorId == _uid;

  RsvpStatus? get myRsvp => plan.rsvpFor(_uid);

  Future<void> refresh() => _onPlanUpdate(plan);

  List<User> get participants =>
      invitees.where((u) => plan.rsvpFor(u.id) == RsvpStatus.going).toList();

  void setShowInvitees(bool value) {
    showInvitees = value;
    notifyListeners();
  }

  Future<void> _loadSaved() async {
    final saved = await _planRepository.savedPlan(_uid, plan.id);
    if (saved != null) _onPlanUpdate(saved);
  }

  Future<void> _onPlanUpdate(Plan updated) async {
    plan = updated;
    final userIds = updated.invitations.map((i) => i.userId).toList();
    activities = await _activityRepository.planActivities(
      _uid,
      updated.activityIds,
    );
    if (!setEquals(tags, updated.tags.toSet())) {
      _planRepository.updateTags(updated.id, tags);
    }
    invitees = await _userRepository.planPeople(updated.id, userIds);
    isLoading = false;
    notifyListeners();
  }

  Set<String> get tags => activities.expand((a) => a.tags).toSet();

  double get estimatedCostPerPerson {
    final going = plan.goingIds.length;
    if (activities.isEmpty || going == 0) return 0;
    final total = activities.fold<double>(0, (sum, a) => sum + a.expectedPrice);
    return total / going;
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
      await _planRepository
          .setRsvp(
            plan.id,
            _uid,
            going ? RsvpStatus.going : RsvpStatus.notGoing,
          )
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (_) {
      return false;
    }
  }

  List<InviteSuggestion> _allSuggestedPeople = [];
  List<Group> suggestedGroups = [];

  List<InviteSuggestion> get suggestedPeople {
    final invited = plan.invitations.map((i) => i.userId).toSet();
    return _allSuggestedPeople
        .where((s) => !invited.contains(s.user.id))
        .toList();
  }

  Future<void> loadSuggestions() async {
    try {
      final ids = await _planRepository.inviteSuggestions(_uid);
      final users = await _userRepository.getUsers(ids.userIds);
      final groups = await _groupRepository.groupsByIds(ids.groupIds);
      final userById = {for (final u in users) u.id: u};

      _allSuggestedPeople = [
        for (var i = 0; i < ids.userIds.length; i++)
          if (userById[ids.userIds[i]] != null)
            InviteSuggestion(
              userById[ids.userIds[i]]!,
              ids.invitesSent[i],
              ids.sharedPlans[i],
            ),
      ];
      suggestedGroups = groups;
      notifyListeners();
    } catch (e) {
      debugPrint('Invite suggestions failed: $e');
    }
  }

  Future<List<String>> invitableMemberIds(Group group) async {
    final invited = plan.invitations.map((i) => i.userId).toSet();
    final members = await _groupRepository.memberIdsForGroup(group.id);
    return members.where((id) => id != _uid && !invited.contains(id)).toList();
  }

  @override
  void dispose() {
    _sub.cancel();
    PendingWriteService.instance.removeListener(_loadSaved);
    super.dispose();
  }
}
