import 'package:plansync/models/invitations.dart';

class Plan {
  final String id;
  final String name;
  final DateTime date;
  final List<String> tags;
  final String creatorId;
  final List<String> activityIds;
  final List<Invitation> invitations;
  final bool isPublic;

  const Plan({
    required this.id,
    required this.name,
    required this.date,
    required this.creatorId,
    this.tags = const [],
    this.activityIds = const [],
    this.invitations = const [],
    this.isPublic = false,
  });

  Invitation? invitationFor(String userId) {
    for (final i in invitations) {
      if (i.userId == userId) return i;
    }
    return null;
  }

  RsvpStatus? rsvpFor(String userId) => invitationFor(userId)?.rsvp;

  List<String> get goingIds => [
    for (final i in invitations)
      if (i.rsvp == RsvpStatus.going) i.userId,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date.microsecondsSinceEpoch,
    'tags': tags,
    'creatorId': creatorId,
    'activityIds': activityIds,
    'invitations': [for (final i in invitations) i.toJson()],
    'isPublic': isPublic,
  };

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json['id'] as String,
    name: json['name'] as String,
    date: DateTime.fromMicrosecondsSinceEpoch(json['date'] as int),
    tags: (json['tags'] as List).cast<String>(),
    creatorId: json['creatorId'] as String,
    activityIds: (json['activityIds'] as List).cast<String>(),
    invitations: [
      for (final i in json['invitations'] as List)
        Invitation.fromJson(i as Map<String, dynamic>),
    ],
    isPublic: json['isPublic'] as bool,
  );

  Plan withActivityIds(List<String> ids) => Plan(
    id: id,
    name: name,
    date: date,
    creatorId: creatorId,
    tags: tags,
    activityIds: ids,
    invitations: invitations,
    isPublic: isPublic,
  );
}
