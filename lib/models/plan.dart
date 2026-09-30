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

  RsvpStatus? rsvpFor(String userId) {
    for (final i in invitations) {
      if (i.userId == userId) return i.rsvp;
    }
    return null;
  }
}
