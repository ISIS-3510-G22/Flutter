class Transfer {
  final String fromId;
  final String toId;
  final int amountCents;

  const Transfer({
    required this.fromId,
    required this.toId,
    required this.amountCents,
  });

  double get amount => amountCents / 100;
}

class _Balance {
  _Balance(this.id, this.cents);

  final String id;
  int cents;
}

/// Turns net balances (positive = must receive, negative = must pay) into
/// the transfers that settle everyone. Equal amounts are matched first, then
/// the biggest debtor pays the biggest creditor, so there are at most n - 1
/// transfers.
List<Transfer> simplifyDebts(Map<String, int> balancesCents) {
  final creditors = <_Balance>[];
  final debtors = <_Balance>[];
  balancesCents.forEach((id, cents) {
    if (cents > 0) creditors.add(_Balance(id, cents));
    if (cents < 0) debtors.add(_Balance(id, -cents));
  });

  final transfers = <Transfer>[];

  for (final debtor in debtors) {
    for (final creditor in creditors) {
      if (creditor.cents > 0 && creditor.cents == debtor.cents) {
        transfers.add(
          Transfer(
            fromId: debtor.id,
            toId: creditor.id,
            amountCents: debtor.cents,
          ),
        );
        creditor.cents = 0;
        debtor.cents = 0;
        break;
      }
    }
  }

  while (true) {
    creditors.removeWhere((b) => b.cents == 0);
    debtors.removeWhere((b) => b.cents == 0);
    if (creditors.isEmpty || debtors.isEmpty) break;

    creditors.sort((a, b) => b.cents.compareTo(a.cents));
    debtors.sort((a, b) => b.cents.compareTo(a.cents));
    final creditor = creditors.first;
    final debtor = debtors.first;

    var amount = debtor.cents;
    if (creditor.cents < amount) amount = creditor.cents;

    transfers.add(
      Transfer(fromId: debtor.id, toId: creditor.id, amountCents: amount),
    );
    creditor.cents -= amount;
    debtor.cents -= amount;
  }

  return transfers;
}

/// Splits [totalCents] in [parts] shares that add up exactly to the total.
List<int> splitCents(int totalCents, int parts) {
  final base = totalCents ~/ parts;
  final remainder = totalCents % parts;
  return [
    for (var i = 0; i < parts; i++)
      if (i < remainder) base + 1 else base,
  ];
}
