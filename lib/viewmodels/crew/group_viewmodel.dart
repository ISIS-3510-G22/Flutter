import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/group_repository.dart';
import 'package:plansync/model/data/crew_write_queue.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/group.dart';
import 'package:plansync/model/models/group_invitation.dart';
import 'package:plansync/model/models/user.dart';

class CrewViewmodel extends ChangeNotifier {
  final _repository = GroupRepository();
  final _userRepository = UserRepository();
  final String _uid;

  late final StreamSubscription<List<Group>> _groupsSub;
  late final StreamSubscription<List<GroupInvitation>> _invitationsSub;
  late final Future<void> _cachedInvitationsReady;

  List<Group> _groups = [];
  List<GroupInvitation> _invitations = [];

  final Map<String, int> _memberCounts = {};
  final Map<String, Group> _invitedGroups = {};
  final Set<String> _waitingIds = {};
  final Map<String, String> _waitingPairDocIds = {};
  late final StreamSubscription<void> _queueSub = CrewWriteQueue
      .instance
      .changes
      .listen((_) {
        for (final group in _groups) {
          if (CrewWriteQueue.instance.pendingDocIds.contains(group.id)) {
            _waitingIds.add(group.id);
          }
        }
        _waitingIds.removeWhere(
          (id) => !CrewWriteQueue.instance.pendingDocIds.contains(id),
        );
        _notify();
      });

  bool _groupsLoaded = false;
  int _groupStreamEmissions = 0;
  bool _hasSavedGroups = false;
  bool _hasServerGroupResult = false;
  bool _invitationsLoaded = false;
  bool _disposed = false;
  String? error;

  List<Group> get groups => _groups;
  bool get areGroupsLoading => !_groupsLoaded;
  bool get hasSavedGroups => _hasSavedGroups || _hasServerGroupResult;
  List<GroupInvitation> get invitations => _invitations;
  bool get isLoading => !(_groupsLoaded && _invitationsLoaded);

  int memberCountFor(String groupId) => _memberCounts[groupId] ?? 0;
  Group? groupForInvitation(GroupInvitation invitation) =>
      _invitedGroups[invitation.groupId];
  bool isWaitingToSync(String id) => _waitingIds.contains(id);
  bool isInviteWaiting(String groupId, String userId) =>
      _waitingIds.contains(_waitingPairDocIds['${groupId}_$userId']);

  Future<List<User>> membersForGroup(String groupId) async {
    final memberIds = await _repository.memberIdsForGroup(groupId);
    final users = await _userRepository.getUsers(memberIds);
    final usersById = {for (final user in users) user.id: user};
    return memberIds
        .where(usersById.containsKey)
        .map((id) => usersById[id]!)
        .toList();
  }

  Future<Set<String>> pendingInviteeIdsForGroup(String groupId) =>
      _repository.pendingInviteeIdsForGroup(groupId);

  Future<bool> inviteFriend(String groupId, String userId) async {
    error = null;
    _notify();
    try {
      final result = await _repository.inviteUser(groupId, userId);
      if (!result.synced) {
        _waitingIds.add(result.invitationId);
        _waitingPairDocIds['${groupId}_$userId'] = result.invitationId;
      }
      _notify();
      return true;
    } catch (_) {
      error = 'Could not invite this friend. Please try again.';
      _notify();
      return false;
    }
  }

  CrewViewmodel(String uid) : _uid = uid {
    _groupsSub = _repository
        .groupsForUser(uid)
        .listen(
          (groups) async {
            _groups = groups;
            if (_groupStreamEmissions++ == 0) {
              _hasSavedGroups =
                  _hasSavedGroups || await _repository.hasSavedGroups();
            } else {
              _hasServerGroupResult = true;
              _hasSavedGroups = true;
            }
            for (final group in groups) {
              _memberCounts.remove(group.id);
            }
            await _loadMemberCounts(groups.map((g) => g.id));
            _groupsLoaded = true;
            _notify();
          },
          onError: (Object _) {
            _groupsLoaded = true;
            error =
                'Could not load your groups. Check your connection and try again.';
            _notify();
          },
        );

    _cachedInvitationsReady = _loadCachedInvitations(uid);
    _invitationsSub = _repository
        .pendingInvitationsForUser(uid)
        .listen(
          (invitations) async {
            await _cachedInvitationsReady;
            _invitations = invitations;
            await _loadInvitedGroups(invitations);
            await _repository.saveInvitationsForUser(
              uid,
              invitations,
              _invitedGroups,
            );
            _invitationsLoaded = true;
            _notify();
          },
          onError: (Object _) {
            _invitationsLoaded = true;
            error =
                'Could not load your invitations. Check your connection and try again.';
            _notify();
          },
        );
  }

  Future<void> _loadCachedInvitations(String uid) async {
    try {
      final cached = await _repository.cachedInvitationsForUser(uid);
      if (cached == null) {
        _invitationsLoaded = true;
        _notify();
        return;
      }
      _invitations = cached.map((entry) => entry.invitation).toList();
      _invitedGroups.addEntries(
        cached.map((entry) => MapEntry(entry.group.id, entry.group)),
      );
      await _loadMemberCounts(cached.map((entry) => entry.group.id));
      _invitationsLoaded = true;
      _notify();
    } catch (_) {
      error = 'Could not load your saved invitations.';
      _invitationsLoaded = true;
      _notify();
    }
  }

  Future<void> _loadMemberCounts(Iterable<String> groupIds) async {
    try {
      final counts = await _repository.memberCounts();
      for (final id in groupIds) {
        _memberCounts[id] = counts[id] ?? 0;
      }
    } catch (_) {
      error = 'Could not load group member counts.';
    }
  }

  Future<void> _loadInvitedGroups(List<GroupInvitation> invitations) async {
    try {
      final ids = invitations.map((invitation) => invitation.groupId).toSet();
      await _loadMemberCounts(ids);
      await Future.wait(
        invitations.map((i) async {
          _invitedGroups[i.groupId] = await _repository.groupById(i.groupId);
          await _repository.memberIdsForGroup(i.groupId);
          await _loadMemberCounts([i.groupId]);
        }),
      );
    } catch (_) {
      error = 'Could not load group invitation details.';
    }
  }

  Future<Group> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      error = null;
      final group = await _repository.createGroup(
        name: name,
        description: description,
        creatorUid: _uid,
      );
      if (!_groups.any((item) => item.id == group.id)) {
        _groups = [..._groups, group];
        _memberCounts[group.id] = 1;
      }
      if (CrewWriteQueue.instance.pendingDocIds.contains(group.id)) {
        _waitingIds.add(group.id);
      }
      _notify();
      return group;
    } catch (_) {
      error = 'Could not create the group. Please try again.';
      _notify();
      rethrow;
    }
  }

  Future<void> acceptInvitation(GroupInvitation invitation) async {
    await _run(() async {
      _invitations = _invitations
          .where((item) => item.id != invitation.id)
          .toList();
      final group = _invitedGroups[invitation.groupId];
      if (group != null && !_groups.any((item) => item.id == group.id)) {
        _groups = [..._groups, group];
        _memberCounts[group.id] = (_memberCounts[group.id] ?? 0) + 1;
      }
      _notify();
      await _repository.saveInvitationsForUser(
        _uid,
        _invitations,
        _invitedGroups,
      );
      final synced = await _repository.acceptInvitation(
        invitation,
        group: group,
        itemName: group?.name,
      );
      if (!synced) _waitingIds.add(invitation.id);
    }, 'Could not accept the invitation');
  }

  Future<void> denyInvitation(GroupInvitation invitation) async {
    await _run(() async {
      _invitations = _invitations
          .where((item) => item.id != invitation.id)
          .toList();
      _notify();
      await _repository.saveInvitationsForUser(
        _uid,
        _invitations,
        _invitedGroups,
      );
      final synced = await _repository.denyInvitation(
        invitation,
        itemName: _invitedGroups[invitation.groupId]?.name,
      );
      if (!synced) _waitingIds.add(invitation.id);
    }, 'Could not deny the invitation');
  }

  void clearError() {
    error = null;
    _notify();
  }

  Future<void> _run(Future<void> Function() action, String message) async {
    try {
      await action();
    } catch (_) {
      error = '$message. Please try again.';
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _groupsSub.cancel();
    _invitationsSub.cancel();
    _queueSub.cancel();
    super.dispose();
  }
}
