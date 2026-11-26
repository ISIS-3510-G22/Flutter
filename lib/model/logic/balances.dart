import 'package:plansync/model/logic/custom_split.dart';
import 'package:plansync/model/logic/debt_simplifier.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/friend_balance.dart';
import 'package:plansync/model/models/settlement.dart';
import 'package:plansync/model/models/split_method.dart';

typedef PlanSplits = ({
  String planId,
  String name,
  DateTime date,
  List<Expense> expenses,
  List<Settlement> settlements,
  List<String> participantIds,
});

int planVersion(PlanSplits plan) => Object.hashAll([
  Object.hashAll(plan.participantIds),
  for (final e in plan.expenses)
    Object.hash(
      e.value,
      e.paidById,
      e.splitMethod,
      Object.hashAll(e.splitAmongIds),
      Object.hashAll([
        for (final c in e.customAmounts.entries) Object.hash(c.key, c.value),
      ]),
    ),
  for (final s in plan.settlements) Object.hash(s.fromId, s.toId, s.amount),
]);

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

({Map<String, List<Transfer>> computed, List<FriendBalance> friends})
myBalances(
  List<PlanSplits> plans,
  Map<String, List<Transfer>> cached,
  String uid,
) {
  final computed = <String, List<Transfer>>{};
  final byFriend = <String, List<PlanBalance>>{};
  for (final plan in plans) {
    var transfers = cached[plan.planId];
    if (transfers == null) {
      transfers = simplifyDebts(
        balancesCents(plan.expenses, plan.settlements, plan.participantIds),
      );
      computed[plan.planId] = transfers;
    }
    for (final t in transfers) {
      if (t.fromId != uid && t.toId != uid) continue;
      final owesMe = t.toId == uid;
      final friendId = owesMe ? t.fromId : t.toId;
      byFriend
          .putIfAbsent(friendId, () => [])
          .add(
            PlanBalance(
              planId: plan.planId,
              name: plan.name,
              date: plan.date,
              cents: owesMe ? t.amountCents : -t.amountCents,
            ),
          );
    }
  }

  final friends = <FriendBalance>[];
  for (final entry in byFriend.entries) {
    var total = 0;
    for (final plan in entry.value) {
      total += plan.cents;
    }
    if (total == 0) continue;
    friends.add(
      FriendBalance(userId: entry.key, totalCents: total, plans: entry.value),
    );
  }
  return (computed: computed, friends: friends);
}
