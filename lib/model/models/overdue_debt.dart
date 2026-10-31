class OverdueDebt {
  final String fromId;
  final String toId;
  final double amount;
  final int daysOverdue;

  const OverdueDebt({
    required this.fromId,
    required this.toId,
    required this.amount,
    required this.daysOverdue,
  });

  String get id => '${fromId}_$toId';
}
