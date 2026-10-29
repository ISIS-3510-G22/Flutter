import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/crew_write_queue.dart';
import 'package:plansync/model/data/local/crew_local_store.dart';
import 'package:plansync/model/data/local/json_file_store.dart';
import 'package:plansync/model/models/group.dart';
import 'package:plansync/model/models/group_invitation.dart';
import 'package:plansync/model/models/pending_write.dart';

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
    return _local.saveOptimisticGroup(group, creatorUid).then((_) {
      unawaited(
        CrewWriteQueue.instance.submit(
          PendingWrite(
            kind: CrewWriteKind.groupCreate,
            docId: groupRef.id,
            payload: {
              'name': name,
              'description': description,
              'creatorUid': creatorUid,
            },
          ),
        ),
      );
      return group;
    });
  }

  Future<({bool synced, String invitationId})> inviteUser(
    String groupId,
    String userId,
  ) async {
    final localStatus = await _local.membershipStatus(groupId, userId);
    if (localStatus == 'member') {
      throw StateError('This friend is already a group member.');
    }
    if (localStatus == 'invited') {
      throw StateError('This friend already has a pending invitation.');
    }
    if (ConnectivityRepository.instance.isOnline) {
      try {
        final membership = await _members
            .doc(_memberId(groupId, userId))
            .get(const GetOptions(source: Source.server));
        if (membership.exists) {
          throw StateError('This friend is already a group member.');
        }
        final sentInvitations = await _invitations
            .where('groupId', isEqualTo: groupId)
            .get(const GetOptions(source: Source.server));
        if (sentInvitations.docs.any((doc) {
          final data = doc.data();
          return data['userId'] == userId &&
              data['status'] == InvitationStatus.pending.name;
        })) {
          throw StateError('This friend already has a pending invitation.');
        }
      } on StateError {
        rethrow;
      } catch (_) {
        // The durable queue will retry the write if validation cannot reach
        // the server. Local membership and invitation state remains the guard.
      }
    }

    final sentOn = DateTime.now();
    final invitationRef = _invitations.doc();
    await _local.saveInvitedMember(groupId, userId);
    final synced = await CrewWriteQueue.instance.submit(
      PendingWrite(
        kind: CrewWriteKind.groupInvite,
        docId: invitationRef.id,
        payload: {
          'invitationId': invitationRef.id,
          'groupId': groupId,
          'userId': userId,
          'sentOn': sentOn.toIso8601String(),
        },
      ),
    );
    return (synced: synced, invitationId: invitationRef.id);
  }

  Future<Set<String>> pendingInviteeIdsForGroup(String groupId) async {
    final localIds = await _local.invitedIds(groupId);
    try {
      ConnectivityRepository.instance.ensureOnline();
      final snapshot = await _invitations
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.server));
      return snapshot.docs
          .where((doc) => doc.data()['status'] == InvitationStatus.pending.name)
          .map((doc) => doc.data()['userId'] as String)
          .toSet();
    } catch (_) {
      return localIds;
    }
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
    try {
      ConnectivityRepository.instance.ensureOnline();
      final docs = await Future.wait(
        ids.map(
          (id) => _groups.doc(id).get(const GetOptions(source: Source.server)),
        ),
      );
      return docs
          .where((d) => d.exists)
          .map((d) => Group.fromFirestore(d.id, d.data()!))
          .toList();
    } catch (_) {
      return _local.groupsByIds(ids);
    }
  }

  Future<List<Group>> cachedGroupsByIds(List<String> ids) =>
      _local.groupsByIds(ids);

  Future<bool> acceptInvitation(
    GroupInvitation invitation, {
    Group? group,
  }) async {
    if (group == null) {
      await _local.setMembershipStatus(
        invitation.groupId,
        invitation.userId,
        'member',
      );
    } else {
      await _local.saveOptimisticGroup(group, invitation.userId);
    }
    final synced = await CrewWriteQueue.instance.submit(
      PendingWrite(
        kind: CrewWriteKind.inviteAccept,
        docId: invitation.id,
        payload: {'groupId': invitation.groupId, 'userId': invitation.userId},
      ),
    );
    return synced;
  }

  Future<bool> denyInvitation(GroupInvitation invitation) async {
    await _local.removeMembership(invitation.groupId, invitation.userId);
    final synced = await CrewWriteQueue.instance.submit(
      PendingWrite(
        kind: CrewWriteKind.inviteDeny,
        docId: invitation.id,
        payload: const {},
      ),
    );
    return synced;
  }
}
