class GroupOuting {
  final String planId;
  final String name;
  final DateTime date;
  final List<String> attendingMemberIds;

  const GroupOuting({
    required this.planId,
    required this.name,
    required this.date,
    required this.attendingMemberIds,
  });
}
