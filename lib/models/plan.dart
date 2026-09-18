class Participant {
  final String id;
  final String initials;

  const Participant({required this.id, required this.initials});
}

class Plan {
  final String id;
  final String title;
  final String date;
  final int estimatedCostPerPerson;
  final List<Participant> participants;
  final int activityCount;
  final double rating;
  final String category;
  final String planType;

  const Plan({
    required this.id,
    required this.title,
    required this.date,
    required this.estimatedCostPerPerson,
    required this.participants,
    required this.activityCount,
    this.rating = 0,
    this.category = '',
    this.planType = '',
  });

  /// Buckets [estimatedCostPerPerson] into a price tier chip label.
  String get priceTier => switch (estimatedCostPerPerson) {
    <= 0 => 'Free',
    <= 30 => r'$',
    <= 80 => r'$$',
    _ => r'$$$',
  };
}
