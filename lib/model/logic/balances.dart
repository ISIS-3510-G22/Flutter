import 'package:plansync/model/logic/custom_split.dart';
import 'package:plansync/model/logic/debt_simplifier.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/settlement.dart';
import 'package:plansync/model/models/split_method.dart';

Map<String, int> balancesCents(
  List<Expense> expenses,
  List<Settlement> settlements,
  List<String> participantIds,
) {
  final balances = <String, int>{};
  void add(String id, int cents) {
    final current = balances[id];
    if (current == null) {
      balances[id] = cents;
    } else {
      balances[id] = current + cents;
    }
  }

  for (final expense in expenses) {
    if (expense.splitMethod == SplitMethod.custom) {
      add(expense.paidById, toCents(expense.value));
      customSharesCents(
        expense.customAmounts,
      ).forEach((id, cents) => add(id, -cents));
      continue;
    }
    var splitIds = expense.splitAmongIds;
    if (splitIds.isEmpty) splitIds = participantIds;
    if (splitIds.isEmpty) continue;
    final totalCents = toCents(expense.value);
    final shares = splitCents(totalCents, splitIds.length);
    add(expense.paidById, totalCents);
    for (var i = 0; i < splitIds.length; i++) {
      add(splitIds[i], -shares[i]);
    }
  }
  for (final s in settlements) {
    final cents = (s.amount * 100).round();
    add(s.fromId, cents);
    add(s.toId, -cents);
  }
  return balances;
}
