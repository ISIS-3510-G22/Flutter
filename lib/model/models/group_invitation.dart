import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, denied }

class GroupInvitation {
  final String id;
  final String groupId;
  final String userId;
  final DateTime sentOn;
  final InvitationStatus status;

  const GroupInvitation({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.sentOn,
    this.status = InvitationStatus.pending,
  });

  factory GroupInvitation.fromFirestore(String id, Map<String, dynamic> data) {
    return GroupInvitation(
      id: id,
      groupId: data['groupId'] as String,
      userId: data['userId'] as String,
      sentOn: (data['sentOn'] as Timestamp).toDate(),
      status: InvitationStatus.values.byName(data['status'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'userId': userId,
    'sentOn': Timestamp.fromDate(sentOn),
    'status': status.name,
  };
}
