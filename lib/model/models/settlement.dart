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
}
