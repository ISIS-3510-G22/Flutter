import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/data/group_repository.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/group.dart';
import 'package:plansync/models/group_invitation.dart';
import 'package:plansync/models/user.dart';

class CrewViewmodel extends ChangeNotifier {
  final _repository = GroupRepository();
  final _userRepository = UserRepository();
  final String _uid;

  late final StreamSubscription<List<Group>> _groupsSub;
  late final StreamSubscription<List<GroupInvitation>> _invitationsSub;

  List<Group> _groups = [];
  List<GroupInvitation> _invitations = [];

  //extra data the cards need, keyed by group ID.
  final Map<String, int> _memberCounts = {};
  final Map<String, Group> _invitedGroups = {};

  bool _groupsLoaded = false;
  bool _invitationsLoaded = false;
  bool _disposed = false;
  String? error;

  List<Group> get groups => _groups;
  List<GroupInvitation> get invitations => _invitations;
  bool get isLoading => !(_groupsLoaded && _invitationsLoaded);

  int memberCountFor(String groupId) => _memberCounts[groupId] ?? 0;
  Group? groupForInvitation(GroupInvitation invitation) =>
      _invitedGroups[invitation.groupId];

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
      await _repository.inviteUser(groupId, userId);
      return true;
    } catch (e) {
      error = 'Could not invite this friend: $e';
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
            for (final group in groups) {
              _memberCounts.remove(group.id);
            }
            await _loadMemberCounts(groups.map((g) => g.id));
            _groupsLoaded = true;
            _notify();
          },
          onError: (Object e) {
            _groupsLoaded = true;
            error = 'Could not load your groups: $e';
            _notify();
          },
        );

    _invitationsSub = _repository
        .pendingInvitationsForUser(uid)
        .listen(
          (invitations) async {
            _invitations = invitations;
            await _loadInvitedGroups(invitations);
            _invitationsLoaded = true;
            _notify();
          },
          onError: (Object e) {
            _invitationsLoaded = true;
            error = 'Could not load your invitations: $e';
            _notify();
          },
        );
  }

  //fetches counts for groups we haven't looked up yet.
  Future<void> _loadMemberCounts(Iterable<String> groupIds) async {
    try {
      await Future.wait(
        groupIds.where((id) => !_memberCounts.containsKey(id)).map((id) async {
          _memberCounts[id] = await _repository.memberCount(id);
        }),
      );
    } catch (e) {
      error = 'Could not load member counts: $e';
    }
  }

  //fetches the group (and count) behind each pending invitation.
  Future<void> _loadInvitedGroups(List<GroupInvitation> invitations) async {
    try {
      await Future.wait(
        invitations.where((i) => !_invitedGroups.containsKey(i.groupId)).map((
          i,
        ) async {
          _invitedGroups[i.groupId] = await _repository.groupById(i.groupId);
          _memberCounts[i.groupId] = await _repository.memberCount(i.groupId);
        }),
      );
    } catch (e) {
      error = 'Could not load invitation details: $e';
    }
  }

  Future<Group> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      error = null;
      return await _repository.createGroup(
        name: name,
        description: description,
        creatorUid: _uid,
      );
    } catch (e) {
      error = 'Could not create the group: $e';
      _notify();
      rethrow;
    }
  }

  Future<void> acceptInvitation(GroupInvitation invitation) {
    return _run(
      () => _repository.acceptInvitation(invitation),
      'Could not accept the invitation',
    );
  }

  Future<void> denyInvitation(GroupInvitation invitation) {
    return _run(
      () => _repository.denyInvitation(invitation.id),
      'Could not deny the invitation',
    );
  }

  void clearError() {
    error = null;
    _notify();
  }

  Future<void> _run(Future<void> Function() action, String message) async {
    try {
      await action();
    } catch (e) {
      error = '$message: $e';
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
    super.dispose();
  }
}
