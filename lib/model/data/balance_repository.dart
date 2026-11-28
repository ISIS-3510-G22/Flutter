import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/cache/plan_balance_cache.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/expense_repository.dart';
import 'package:plansync/model/data/plan_payment_repository.dart';
import 'package:plansync/model/data/settlement_repository.dart';
import 'package:plansync/model/logic/balances.dart';
import 'package:plansync/model/logic/debt_simplifier.dart';
import 'package:plansync/model/models/balances_filter.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/friend_balance.dart';
import 'package:plansync/model/models/invitations.dart';
import 'package:plansync/model/models/offline_exception.dart';
import 'package:plansync/model/models/settlement.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/local/json_file_store.dart';
import 'package:plansync/model/services/local/split_local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<({Map<String, List<Transfer>> computed, List<FriendBalance> friends})>
_computeInIsolate(
  List<PlanSplits> plans,
  Map<String, List<Transfer>> cached,
  String uid,
) => Isolate.run(() => myBalances(plans, cached, uid));

class BalanceRepository {
  static final _cache = PlanBalanceCache();

  static void clearCache() => _cache.clear();

  static const _filterKey = 'balances_filter';

  static String _seenFile(String uid) => 'balances_seen_$uid.json';

  final _expenseRepository = ExpenseRepository();
  final _settlementRepository = SettlementRepository();
  final _paymentRepository = PlanPaymentRepository();
  final _local = SplitLocalStore();
  final _connectivity = ConnectivityRepository.instance;
  final _prefs = SharedPreferencesAsync();
  final _files = JsonFileStore();

  Future<BalancesFilter> savedFilter() async {
    final saved = await _prefs.getString(_filterKey);
    return BalancesFilter.values.asNameMap()[saved] ?? BalancesFilter.all;
  }

  Future<void> saveFilter(BalancesFilter filter) =>
      _prefs.setString(_filterKey, filter.name);

  Future<Map<String, int>?> seenBalances(String uid) async {
    final text = await _files.read(_seenFile(uid));
    if (text == null) return null;
    try {
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          entry.key: (entry.value as num).toInt(),
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSeenBalances(String uid, Map<String, int> cents) =>
      _files.write(_seenFile(uid), jsonEncode(cents));

  Future<({List<FriendBalance> friends, DateTime savedAt})?> savedBalances(
    String uid,
  ) async {
    final stored = await _local.balances(uid);
    if (stored == null) return null;
    final plans = <PlanSplits>[];
    for (final plan in await _local.balancePlans(uid)) {
      final expenses = await _expenseRepository.savedExpenses(plan.planId);
      final settlements = await _settlementRepository.savedSettlements(
        plan.planId,
      );
      if (expenses == null || settlements == null) return stored;
      plans.add((
        planId: plan.planId,
        name: plan.name,
        date: plan.date,
        expenses: expenses,
        settlements: settlements,
        participantIds: plan.participantIds,
      ));
    }
    final known = {for (final friend in stored.friends) friend.userId: friend};
    final friends = <FriendBalance>[];
    for (final friend in await _compute(plans, uid)) {
      friends.add(
        FriendBalance(
          userId: friend.userId,
          name:
              known[friend.userId]?.name ??
              await _local.personName(friend.userId),
          photoUrl: known[friend.userId]?.photoUrl,
          totalCents: friend.totalCents,
          plans: friend.plans,
        ),
      );
    }
    return (friends: friends, savedAt: stored.savedAt);
  }

  Future<({List<FriendBalance> friends, DateTime? savedAt, bool fromServer})?>
  balances(String uid) async {
    try {
      _connectivity.ensureOnline();
      final plans = await _serverPlanSplits(uid);
      final friends = await _withProfiles(await _compute(plans, uid));
      await _local.saveBalances(uid, friends, plans);
      return (friends: friends, savedAt: DateTime.now(), fromServer: true);
    } catch (e) {
      if (e is! OfflineException &&
          e is! TimeoutException &&
          e is! FirebaseException) {
        rethrow;
      }
      final stored = await savedBalances(uid);
      if (stored == null) return null;
      return (
        friends: stored.friends,
        savedAt: stored.savedAt,
        fromServer: false,
      );
    }
  }

  List<Transfer> planTransfers(
    String planId,
    List<Expense> expenses,
    List<Settlement> settlements,
    List<String> participantIds,
  ) {
    final version = splitsVersion(expenses, settlements, participantIds);
    final cached = _cache.get(planId, version);
    if (cached != null) return cached;
    final transfers = simplifyDebts(
      balancesCents(expenses, settlements, participantIds),
    );
    _cache.put(planId, version, transfers);
    return transfers;
  }

  Future<List<FriendBalance>> _compute(
    List<PlanSplits> plans,
    String uid,
  ) async {
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
    return result.friends;
  }

  Future<List<PlanSplits>> _serverPlanSplits(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('plans')
        .where('participantsIds', arrayContains: uid)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 8));
    return Future.wait(snapshot.docs.map(_planSplits));
  }

  Future<PlanSplits> _planSplits(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final goingIds = [
      for (final i in data['invitations'] as List)
        if (i['rsvp'] == RsvpStatus.going.name) i['userId'] as String,
    ]..sort();
    final expenses = _expenseRepository.serverExpenses(doc.id);
    final settlements = _settlementRepository.serverSettlements(doc.id);
    await Future.wait<Object>([expenses, settlements]);
    return (
      planId: doc.id,
      name: data['name'] as String,
      date: (data['date'] as Timestamp).toDate(),
      expenses: await expenses,
      settlements: await settlements,
      participantIds: goingIds,
    );
  }

  Future<List<FriendBalance>> _withProfiles(List<FriendBalance> friends) async {
    final idsByPlan = <String, Set<String>>{};
    for (final friend in friends) {
      for (final plan in friend.plans) {
        idsByPlan
            .putIfAbsent(plan.planId, () => {...plan.participantIds})
            .add(friend.userId);
      }
    }
    final usersByPlan = await Future.wait([
      for (final entry in idsByPlan.entries)
        _paymentRepository.participants(entry.key, entry.value.toList()),
    ]);
    final people = <String, User>{
      for (final users in usersByPlan)
        for (final user in users) user.id: user,
    };
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
