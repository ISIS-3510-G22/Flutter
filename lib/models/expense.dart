class Expense {
  final String id;
  final String name;
  final double value;
  final String paidById;
  final DateTime createdAt;
  // Empty means the expense is shared by every participant of the plan.
  final List<String> splitAmongIds;

  const Expense({
    required this.id,
    required this.name,
    required this.value,
    required this.paidById,
    required this.createdAt,
    this.splitAmongIds = const [],
  });
}
