import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/write_queue.dart';
import 'package:plansync/model/models/pending_write.dart';

enum CrewWriteKind {
  requestSend,
  requestAccept,
  requestDeny,
  groupCreate,
  groupInvite,
  inviteAccept,
  inviteDeny,
  planInvite,
}

class CrewWriteQueue extends WriteQueue<CrewWriteKind> {
  CrewWriteQueue._() : super('crew_outbox', CrewWriteKind.values);

  static final instance = CrewWriteQueue._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _friendRequests =>
      _db.collection('friendRequests');
  CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection('groups');
  CollectionReference<Map<String, dynamic>> get _groupMembers =>
      _db.collection('groupMembers');
  CollectionReference<Map<String, dynamic>> get _groupInvitations =>
      _db.collection('groupInvitations');
  CollectionReference<Map<String, dynamic>> get _plans =>
      _db.collection('plans');

  String _groupMemberId(String groupId, String userId) => '${groupId}_$userId';

  DateTime _dateTime(Object? value) => DateTime.parse(value as String);

  @override
  Future<void> send(PendingWrite<CrewWriteKind> write) async {
    final payload = write.payload;
    try {
      await switch (write.kind) {
        CrewWriteKind.requestSend => _friendRequests.doc(write.docId).set({
          'fromUserId': payload['fromUserId'] as String,
          'toUserId': payload['toUserId'] as String,
          'sentOn': Timestamp.fromDate(_dateTime(payload['sentOn'])),
          'status': 'pending',
        }),
        CrewWriteKind.requestAccept => _friendRequests.doc(write.docId).update({
          'status': 'accepted',
        }),
        CrewWriteKind.requestDeny => _friendRequests.doc(write.docId).update({
          'status': 'denied',
        }),
        CrewWriteKind.groupCreate => _createGroup(write.docId, payload),
        CrewWriteKind.groupInvite => _groupInvitations.doc(write.docId).set({
          'groupId': payload['groupId'] as String,
          'userId': payload['userId'] as String,
          'sentOn': Timestamp.fromDate(_dateTime(payload['sentOn'])),
          'status': 'pending',
        }),
        CrewWriteKind.inviteAccept => _acceptGroupInvitation(
          write.docId,
          payload,
        ),
        CrewWriteKind.inviteDeny => _groupInvitations.doc(write.docId).update({
          'status': 'denied',
        }),
        CrewWriteKind.planInvite => _inviteToPlan(write.docId, payload),
      };
    } on FirebaseException catch (error) {
      // A plan created in another queue may not exist yet. Keep its invite
      // queued so it can be retried after the plan creation syncs.
      if (write.kind == CrewWriteKind.planInvite && error.code == 'not-found') {
        throw TimeoutException('The plan is not available yet.');
      }
      rethrow;
    }
  }

  Future<void> _createGroup(
    String groupId,
    Map<String, dynamic> payload,
  ) async {
    final creatorUid = payload['creatorUid'] as String;
    final batch = _db.batch();
    batch.set(_groups.doc(groupId), {
      'name': payload['name'] as String,
      'description': payload['description'] as String,
    });
    batch.set(_groupMembers.doc(_groupMemberId(groupId, creatorUid)), {
      'groupId': groupId,
      'userId': creatorUid,
    });
    await batch.commit();
  }

  Future<void> _acceptGroupInvitation(
    String invitationId,
    Map<String, dynamic> payload,
  ) async {
    final groupId = payload['groupId'] as String;
    final userId = payload['userId'] as String;
    final batch = _db.batch();
    batch.update(_groupInvitations.doc(invitationId), {'status': 'accepted'});
    batch.set(_groupMembers.doc(_groupMemberId(groupId, userId)), {
      'groupId': groupId,
      'userId': userId,
    });
    await batch.commit();
  }

  Future<void> _inviteToPlan(String planId, Map<String, dynamic> payload) {
    final userIds = (payload['userIds'] as List).cast<String>();
    final invitedAt = Timestamp.fromDate(_dateTime(payload['invitedAt']));
    return _plans.doc(planId).update({
      'participantsIds': FieldValue.arrayUnion(userIds),
      'invitations': FieldValue.arrayUnion([
        for (final userId in userIds)
          {'userId': userId, 'rsvp': 'invited', 'invitedAt': invitedAt},
      ]),
    });
  }

  @override
  String describeDropped(PendingWrite<CrewWriteKind> write) {
    final item = write.payload['name'] as String?;
    final displayName = (item == null || item.isEmpty) ? 'this item' : item;
    return switch (write.kind) {
      CrewWriteKind.requestSend =>
        "We couldn't send the friend request to $displayName.",
      CrewWriteKind.requestAccept =>
        "We couldn't accept $displayName's friend request.",
      CrewWriteKind.requestDeny =>
        "We couldn't deny $displayName's friend request.",
      CrewWriteKind.groupCreate => "We couldn't create the group $displayName.",
      CrewWriteKind.groupInvite =>
        "We couldn't invite $displayName to the group.",
      CrewWriteKind.inviteAccept =>
        "We couldn't accept the invitation to $displayName.",
      CrewWriteKind.inviteDeny =>
        "We couldn't decline the invitation to $displayName.",
      CrewWriteKind.planInvite =>
        "We couldn't invite $displayName to the plan.",
    };
  }
}
