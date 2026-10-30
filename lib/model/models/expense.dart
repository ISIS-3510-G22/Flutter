import 'package:plansync/model/models/split_method.dart';

class Expense {
  final String id;
  final String name;
  final double value;
  final String paidById;
  final DateTime createdAt;
  final List<String> splitAmongIds;
  final SplitMethod splitMethod;
  final Map<String, double> customAmounts;

  const Expense({
    required this.id,
    required this.name,
    required this.value,
    required this.paidById,
    required this.createdAt,
    this.splitAmongIds = const [],
    this.splitMethod = SplitMethod.equal,
    this.customAmounts = const {},
  });

  // Keys match the `expenses` table columns, so a row is this plus `plan_id`.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'value': value,
    'paid_by_id': paidById,
    'created_at': createdAt.millisecondsSinceEpoch,
    'split_among': splitAmongIds,
    'split_method': splitMethod.name,
    'custom_amounts': customAmounts,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    name: json['name'] as String,
    value: (json['value'] as num).toDouble(),
    paidById: json['paid_by_id'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    splitAmongIds: (json['split_among'] as List).cast<String>(),
    // Missing keys (older expenses, payloads already queued) read as equal.
    splitMethod:
        SplitMethod.values.asNameMap()[json['split_method']] ??
        SplitMethod.equal,
    customAmounts: {
      for (final entry
          in (json['custom_amounts'] as Map<String, dynamic>? ?? {}).entries)
        entry.key: (entry.value as num).toDouble(),
    },
  );
}
