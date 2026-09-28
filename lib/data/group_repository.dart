import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/group.dart';
import 'package:plansync/models/group_invitation.dart';

class GroupRepository {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection('groups');
  CollectionReference<Map<String, dynamic>> get _members =>
      _db.collection('groupMembers');
  CollectionReference<Map<String, dynamic>> get _invitations =>
      _db.collection('groupInvitations');

  String _memberId(String groupId, String userId) => '${groupId}_$userId';

  //groups user belongs to: look up membership records, then fetch each group.
  Stream<List<Group>> groupsForUser(String uid) {
    return _members.where('userId', isEqualTo: uid).snapshots().asyncMap((
      snapshot,
    ) async {
      final groupIds = snapshot.docs
          .map((d) => d.data()['groupId'] as String)
          .toList();
      final docs = await Future.wait(
        groupIds.map((id) => _groups.doc(id).get()),
      );
      return docs
          .where((d) => d.exists)
          .map((d) => Group.fromFirestore(d.id, d.data()!))
          .toList();
    });
  }

  Future<int> memberCount(String groupId) async {
    final result = await _members
        .where('groupId', isEqualTo: groupId)
        .count()
        .get();
    return result.count ?? 0;
  }

  Future<List<String>> memberIdsForGroup(String groupId) async {
    final snapshot = await _members.where('groupId', isEqualTo: groupId).get();
    return snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
  }

  //writes the group and the creator's membership together.
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
    final invitation = GroupInvitation(
      id: '',
      groupId: groupId,
      userId: userId,
      sentOn: DateTime.now(),
    );
    return _invitations.add(invitation.toMap());
  }

  Stream<List<GroupInvitation>> pendingInvitationsForUser(String uid) {
    return _invitations
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => GroupInvitation.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<Group> groupById(String id) async {
    final doc = await _groups.doc(id).get();
    return Group.fromFirestore(doc.id, doc.data()!);
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
