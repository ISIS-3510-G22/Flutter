import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/models/group.dart';

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

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      userId: json['userId'] as String,
      sentOn: DateTime.parse(json['sentOn'] as String),
      status: InvitationStatus.values.byName(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupId': groupId,
    'userId': userId,
    'sentOn': sentOn.toIso8601String(),
    'status': status.name,
  };

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'userId': userId,
    'sentOn': Timestamp.fromDate(sentOn),
    'status': status.name,
  };
}

class CachedGroupInvitation {
  final GroupInvitation invitation;
  final Group group;

  const CachedGroupInvitation({required this.invitation, required this.group});

  factory CachedGroupInvitation.fromJson(Map<String, dynamic> json) {
    final groupData = Map<String, dynamic>.from(json['group'] as Map);
    return CachedGroupInvitation(
      invitation: GroupInvitation.fromJson(json),
      group: Group(
        id: groupData['id'] as String,
        name: groupData['name'] as String,
        description: groupData['description'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    ...invitation.toJson(),
    'group': {
      'id': group.id,
      'name': group.name,
      'description': group.description,
    },
  };
}
