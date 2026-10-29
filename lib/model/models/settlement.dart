class Settlement {
  final String id;
  final String fromId;
  final String toId;
  final double amount;

  const Settlement({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.amount,
  });

  // Keys match the `settlements` table columns, so a row is this plus `plan_id`.
  Map<String, dynamic> toJson() => {
    'id': id,
    'from_id': fromId,
    'to_id': toId,
    'amount': amount,
  };

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
    id: json['id'] as String,
    fromId: json['from_id'] as String,
    toId: json['to_id'] as String,
    amount: (json['amount'] as num).toDouble(),
  );
}
