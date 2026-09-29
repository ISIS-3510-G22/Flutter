class Expense {
  final String id;
  final String name;
  final double value;
  final String paidById;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.name,
    required this.value,
    required this.paidById,
    required this.createdAt,
  });
}
