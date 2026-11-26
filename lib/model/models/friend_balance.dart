class PlanBalance {
  final String planId;
  final String name;
  final DateTime date;
  final int cents;

  const PlanBalance({
    required this.planId,
    required this.name,
    required this.date,
    required this.cents,
  });
}

class FriendBalance {
  final String userId;
  final String name;
  final String? photoUrl;
  final int totalCents;
  final List<PlanBalance> plans;

  const FriendBalance({
    required this.userId,
    this.name = '',
    this.photoUrl,
    required this.totalCents,
    required this.plans,
  });
}
