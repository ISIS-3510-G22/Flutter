import 'dart:async';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/cache/plan_balance_cache.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/expense_repository.dart';
import 'package:plansync/model/data/plan_payment_repository.dart';
import 'package:plansync/model/data/settlement_repository.dart';
import 'package:plansync/model/logic/balances.dart';
import 'package:plansync/model/logic/debt_simplifier.dart';
import 'package:plansync/model/models/friend_balance.dart';
import 'package:plansync/model/models/invitations.dart';
import 'package:plansync/model/models/offline_exception.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/local/split_local_store.dart';

Future<({Map<String, List<Transfer>> computed, List<FriendBalance> friends})>
_computeInIsolate(
  List<PlanSplits> plans,
  Map<String, List<Transfer>> cached,
  String uid,
) => Isolate.run(() => myBalances(plans, cached, uid));

class BalanceRepository {
  static final _cache = PlanBalanceCache();

  static void clearCache() => _cache.clear();

  final _expenseRepository = ExpenseRepository();
  final _settlementRepository = SettlementRepository();
  final _paymentRepository = PlanPaymentRepository();
  final _local = SplitLocalStore();
  final _connectivity = ConnectivityRepository.instance;

  Future<({List<FriendBalance> friends, DateTime? savedAt, bool fromServer})?>
  balances(String uid) async {
    try {
      _connectivity.ensureOnline();
      final plans = await _serverPlanSplits(uid);

      final versions = <String, int>{};
      final cached = <String, List<Transfer>>{};
      for (final plan in plans) {
        final version = planVersion(plan);
        versions[plan.planId] = version;
        final transfers = _cache.get(plan.planId, version);
        if (transfers != null) cached[plan.planId] = transfers;
      }

      final result = await _computeInIsolate(plans, cached, uid);
      for (final entry in result.computed.entries) {
        _cache.put(entry.key, versions[entry.key]!, entry.value);
      }

      final friends = await _withProfiles(result.friends);
      await _local.saveBalances(uid, friends);
      return (friends: friends, savedAt: DateTime.now(), fromServer: true);
    } catch (e) {
      if (e is! OfflineException &&
          e is! TimeoutException &&
          e is! FirebaseException) {
        rethrow;
      }
      final stored = await _local.balances(uid);
      if (stored == null) return null;
      return (
        friends: stored.friends,
        savedAt: stored.savedAt,
        fromServer: false,
      );
    }
  }

  Future<List<PlanSplits>> _serverPlanSplits(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('plans')
        .where('participantsIds', arrayContains: uid)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 8));
    final plans = <PlanSplits>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final goingIds = [
        for (final i in data['invitations'] as List)
          if (i['rsvp'] == RsvpStatus.going.name) i['userId'] as String,
      ]..sort();
      plans.add((
        planId: doc.id,
        name: data['name'] as String,
        date: (data['date'] as Timestamp).toDate(),
        expenses: await _expenseRepository.serverExpenses(doc.id),
        settlements: await _settlementRepository.serverSettlements(doc.id),
        participantIds: goingIds,
      ));
    }
    return plans;
  }

  Future<List<FriendBalance>> _withProfiles(List<FriendBalance> friends) async {
    final idsByPlan = <String, List<String>>{};
    for (final friend in friends) {
      idsByPlan
          .putIfAbsent(friend.plans.first.planId, () => [])
          .add(friend.userId);
    }
    final people = <String, User>{};
    for (final entry in idsByPlan.entries) {
      final users = await _paymentRepository.participants(
        entry.key,
        entry.value,
      );
      for (final user in users) {
        people[user.id] = user;
      }
    }
    return [
      for (final friend in friends)
        FriendBalance(
          userId: friend.userId,
          name: switch (people[friend.userId]) {
            final user? => '${user.name} ${user.lastName}',
            null => '',
          },
          photoUrl: people[friend.userId]?.photoUrl,
          totalCents: friend.totalCents,
          plans: friend.plans,
        ),
    ];
  }
}
