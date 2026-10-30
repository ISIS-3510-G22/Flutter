import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:plansync/model/data/activity_repository.dart';
import 'package:plansync/model/data/crew_write_queue.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/friend_repository.dart';
import 'package:plansync/model/data/group_repository.dart';
import 'package:plansync/model/data/pending_write_repository.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/group.dart';
import 'package:plansync/model/models/invitations.dart';
import 'package:plansync/model/models/invite_suggestion.dart';
import 'package:plansync/model/models/invite_suggestion_ids.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/model/models/user.dart';

class PlanDetailViewModel extends ChangeNotifier {
  PlanDetailViewModel(this.plan, this._uid) {
    _queueSub = PendingWriteRepository.instance.changes.listen(
      (_) => _loadSaved(),
    );
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
  late final StreamSubscription<void> _queueSub;
  late final StreamSubscription<void> _crewQueueSub = CrewWriteQueue
      .instance
      .changes
      .listen((_) {
        waitingToSync = CrewWriteQueue.instance.pendingDocIds.contains(plan.id);
        notifyListeners();
      });

  final String _uid;
  Plan plan;
  List<Activity> activities = [];
  List<User> invitees = [];
  bool isLoading = true;
  bool showInvitees = true;
  bool waitingToSync = false;

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

  Future<void> invite(List<String> userIds) async {
    final invitedAt = DateTime.now();
    plan = plan.withInvitations([
      ...plan.invitations.where((i) => !userIds.contains(i.userId)),
      for (final id in userIds)
        Invitation(userId: id, rsvp: RsvpStatus.invited, invitedAt: invitedAt),
    ]);
    waitingToSync = true;
    notifyListeners();
    final synced = await _planRepository.invite(
      _uid,
      plan,
      userIds,
      invitedAt: invitedAt,
    );
    waitingToSync = !synced;
    notifyListeners();
  }

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
  bool suggestionsNeedConnection = false;

  List<InviteSuggestion> get suggestedPeople {
    final invited = plan.invitations.map((i) => i.userId).toSet();
    return _allSuggestedPeople
        .where((s) => !invited.contains(s.user.id))
        .toList();
  }

  Future<void> loadSuggestions() async {
    try {
      final online = ConnectivityRepository.instance.isOnline;
      var useLocalData = !online;
      InviteSuggestionIds? ids;
      if (online) {
        try {
          ids = await _planRepository.inviteSuggestions(_uid);
          await _planRepository.saveInviteSuggestions(_uid, ids);
        } catch (_) {
          ids = await _planRepository.cachedInviteSuggestions(_uid);
          useLocalData = true;
        }
      } else {
        ids = await _planRepository.cachedInviteSuggestions(_uid);
      }

      if (ids == null) {
        suggestionsNeedConnection = true;
        _allSuggestedPeople = [];
        suggestedGroups = [];
        notifyListeners();
        return;
      }

      suggestionsNeedConnection = false;
      List<User> users;
      if (useLocalData) {
        users = await _userRepository.cachedUsersByIds(ids.userIds);
      } else {
        try {
          users = await _userRepository.getUsers(
            ids.userIds,
            source: Source.server,
          );
        } catch (_) {
          users = await _userRepository.cachedUsersByIds(ids.userIds);
        }
      }
      final groups = useLocalData
          ? await _groupRepository.cachedGroupsByIds(ids.groupIds)
          : await _groupRepository.groupsByIds(ids.groupIds);
      final userById = {for (final u in users) u.id: u};

      _allSuggestedPeople = [
        for (var i = 0; i < ids.userIds.length; i++)
          if (userById[ids.userIds[i]] != null)
            InviteSuggestion(
              userById[ids.userIds[i]]!,
              i < ids.invitesSent.length ? ids.invitesSent[i] : 0,
              i < ids.sharedPlans.length ? ids.sharedPlans[i] : 0,
            ),
      ];
      suggestedGroups = groups;
      notifyListeners();
    } catch (e) {
      debugPrint('Invite suggestions failed: $e');
      suggestionsNeedConnection = true;
      _allSuggestedPeople = [];
      suggestedGroups = [];
      notifyListeners();
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
    _queueSub.cancel();
    _crewQueueSub.cancel();
    super.dispose();
  }
}
