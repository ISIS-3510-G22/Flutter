import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/local/crew_local_store.dart';
import 'package:plansync/model/data/local/json_file_store.dart';
import 'package:plansync/model/models/group.dart';
import 'package:plansync/model/models/group_invitation.dart';

class GroupRepository {
  final _db = FirebaseFirestore.instance;
  final _local = CrewLocalStore();
  final _files = JsonFileStore();
  Future<void> _invitationFileWrite = Future<void>.value();
  CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection('groups');
  CollectionReference<Map<String, dynamic>> get _members =>
      _db.collection('groupMembers');
  CollectionReference<Map<String, dynamic>> get _invitations =>
      _db.collection('groupInvitations');

  String _memberId(String groupId, String userId) => '${groupId}_$userId';

  Stream<List<Group>> groupsForUser(String uid) async* {
    yield await _local.groups();
    yield* _serverGroupsForUser(uid);
  }

  Future<bool> hasSavedGroups() => _local.hasSavedGroups();

  Stream<List<Group>> _serverGroupsForUser(String uid) {
    final membershipStream = _members
        .where('userId', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true);
    final controller = StreamController<List<Group>>();
    var pendingEmission = Future<void>.value();

    Future<void> emit(QuerySnapshot<Map<String, dynamic>> snapshot) async {
      ConnectivityRepository.instance.ensureOnline();
      final groupIds = snapshot.docs
          .map((doc) => doc.data()['groupId'] as String)
          .toSet();
      final groupDocs = await Future.wait(
        groupIds.map(
          (id) => _groups.doc(id).get(const GetOptions(source: Source.server)),
        ),
      );
      final groups = groupDocs
          .where((doc) => doc.exists)
          .map((doc) => Group.fromFirestore(doc.id, doc.data()!))
          .toList();
      final memberEntries = await Future.wait(
        groups.map((group) async {
          final members = await _members
              .where('groupId', isEqualTo: group.id)
              .get(const GetOptions(source: Source.server));
          return MapEntry(
            group.id,
            members.docs.map((doc) => doc.data()['userId'] as String).toList(),
          );
        }),
      );
      await _local.saveGroups(groups, Map.fromEntries(memberEntries));
      if (!controller.isClosed) controller.add(groups);
    }

    final subscription = membershipStream.listen((snapshot) {
      if (snapshot.metadata.isFromCache || !controller.hasListener) return;
      pendingEmission = pendingEmission
          .then((_) => emit(snapshot))
          .catchError((Object _) {});
    }, onError: (Object _) {});
    controller.onCancel = subscription.cancel;
    return controller.stream;
  }

  Future<Map<String, int>> memberCounts() => _local.memberCounts();

  Future<List<String>> memberIdsForGroup(String groupId) async {
    final localIds = await _local.memberIds(groupId);
    try {
      ConnectivityRepository.instance.ensureOnline();
      final snapshot = await _members
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.server));
      final memberIds = snapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
      await _local.saveMemberIds(groupId, memberIds);
      return memberIds;
    } catch (_) {
      return localIds;
    }
  }

  Future<Group> createGroup({
    required String name,
    required String description,
    required String creatorUid,
  }) {
    final groupRef = _groups.doc();
    final group = Group(id: groupRef.id, name: name, description: description);
    final batch = _db.batch();
    batch.set(groupRef, group.toMap());
    batch.set(_members.doc(_memberId(groupRef.id, creatorUid)), {
      'groupId': groupRef.id,
      'userId': creatorUid,
    });
    return batch.commit().then((_) => group);
  }

  Future<void> inviteUser(String groupId, String userId) {
    return _members.doc(_memberId(groupId, userId)).get().then((
      membership,
    ) async {
      if (membership.exists) {
        throw StateError('This friend is already a group member.');
      }

      final groupInvitations = await _invitations
          .where('groupId', isEqualTo: groupId)
          .get();
      final hasPendingInvitation = groupInvitations.docs.any((doc) {
        final data = doc.data();
        return data['userId'] == userId &&
            data['status'] == InvitationStatus.pending.name;
      });
      if (hasPendingInvitation) {
        throw StateError('This friend already has a pending invitation.');
      }

      final invitation = GroupInvitation(
        id: '',
        groupId: groupId,
        userId: userId,
        sentOn: DateTime.now(),
      );
      await _invitations.add(invitation.toMap());
    });
  }

  Future<Set<String>> pendingInviteeIdsForGroup(String groupId) async {
    final snapshot = await _invitations
        .where('groupId', isEqualTo: groupId)
        .get();
    return snapshot.docs
        .where((doc) => doc.data()['status'] == InvitationStatus.pending.name)
        .map((doc) => doc.data()['userId'] as String)
        .toSet();
  }

  Stream<List<GroupInvitation>> pendingInvitationsForUser(String uid) {
    return _invitations
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map(
          (s) => s.docs
              .map((d) => GroupInvitation.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<List<CachedGroupInvitation>?> cachedInvitationsForUser(
    String uid,
  ) async {
    final contents = await _files.read('group_invites_$uid.json');
    if (contents == null) return null;
    try {
      return (jsonDecode(contents) as List)
          .map(
            (entry) => CachedGroupInvitation.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveInvitationsForUser(
    String uid,
    List<GroupInvitation> invitations,
    Map<String, Group> groupsById,
  ) {
    final cached = invitations
        .where((invitation) => groupsById.containsKey(invitation.groupId))
        .map(
          (invitation) => CachedGroupInvitation(
            invitation: invitation,
            group: groupsById[invitation.groupId]!,
          ),
        )
        .map((entry) => entry.toJson())
        .toList();
    final contents = jsonEncode(cached);
    _invitationFileWrite = _invitationFileWrite
        .catchError((Object _) {})
        .then((_) => _files.write('group_invites_$uid.json', contents));
    return _invitationFileWrite;
  }

  Future<Group> groupById(String id) async {
    ConnectivityRepository.instance.ensureOnline();
    final doc = await _groups
        .doc(id)
        .get(const GetOptions(source: Source.server));
    return Group.fromFirestore(doc.id, doc.data()!);
  }

  Future<List<Group>> groupsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final docs = await Future.wait(ids.map((id) => _groups.doc(id).get()));
    return docs
        .where((d) => d.exists)
        .map((d) => Group.fromFirestore(d.id, d.data()!))
        .toList();
  }

  Future<void> acceptInvitation(GroupInvitation invitation) {
    final batch = _db.batch();
    batch.update(_invitations.doc(invitation.id), {
      'status': InvitationStatus.accepted.name,
    });
    batch.set(_members.doc(_memberId(invitation.groupId, invitation.userId)), {
      'groupId': invitation.groupId,
      'userId': invitation.userId,
    });
    return batch.commit();
  }

  Future<void> denyInvitation(String invitationId) {
    return _invitations.doc(invitationId).update({
      'status': InvitationStatus.denied.name,
    });
  }
}
