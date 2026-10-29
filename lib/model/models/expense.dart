class Expense {
  final String id;
  final String name;
  final double value;
  final String paidById;
  final DateTime createdAt;
  final List<String> splitAmongIds;

  const Expense({
    required this.id,
    required this.name,
    required this.value,
    required this.paidById,
    required this.createdAt,
    this.splitAmongIds = const [],
  });

  // Keys match the `expenses` table columns, so a row is this plus `plan_id`.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'value': value,
    'paid_by_id': paidById,
    'created_at': createdAt.millisecondsSinceEpoch,
    'split_among': splitAmongIds,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    name: json['name'] as String,
    value: (json['value'] as num).toDouble(),
    paidById: json['paid_by_id'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    splitAmongIds: (json['split_among'] as List).cast<String>(),
  );
}
