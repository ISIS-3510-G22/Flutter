enum RsvpStatus { going, notGoing, invited }

class Invitation {
  final String userId;
  final RsvpStatus rsvp;
  final DateTime? invitedAt;

  const Invitation({required this.userId, required this.rsvp, this.invitedAt});

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'rsvp': rsvp.name,
    'invitedAt': invitedAt?.microsecondsSinceEpoch,
  };

  factory Invitation.fromJson(Map<String, dynamic> json) {
    final invitedAt = json['invitedAt'] as int?;
    return Invitation(
      userId: json['userId'] as String,
      rsvp: RsvpStatus.values.byName(json['rsvp'] as String),
      invitedAt: invitedAt == null
          ? null
          : DateTime.fromMicrosecondsSinceEpoch(invitedAt),
    );
  }
}
