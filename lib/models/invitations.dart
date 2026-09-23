enum RsvpStatus { going, notGoing, invited }

class Invitation {
  final String userId;
  final RsvpStatus rsvp;

  const Invitation({
    required this.userId,
    required this.rsvp,
  });
}