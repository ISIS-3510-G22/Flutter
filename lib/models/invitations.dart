enum RsvpStatus { going, notGoing, invited }

class Invitation {
  final String userId;
  final RsvpStatus rsvp;
  final DateTime? invitedAt;

  const Invitation({required this.userId, required this.rsvp, this.invitedAt});
}
