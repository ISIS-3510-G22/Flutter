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
}
