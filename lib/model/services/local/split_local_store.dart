import 'dart:convert';

import 'package:plansync/model/services/local/local_database.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/friend_balance.dart';
import 'package:plansync/model/models/reimbursement_method.dart';
import 'package:plansync/model/models/settlement.dart';
import 'package:plansync/model/models/user.dart';
import 'package:sqflite/sqflite.dart';

class SplitLocalStore {
  Future<Database> get _db => LocalDatabase.instance;

  static const _expensesList = 'expenses';
  static const _settlementsList = 'settlements';

  Future<List<Expense>?> expenses(String planId) async {
    final db = await _db;
    if (!await _isSaved(db, planId, _expensesList)) return null;
    final rows = await db.query(
      'expenses',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'created_at DESC',
    );
    return [
      for (final row in rows)
        Expense.fromJson({
          ...row,
          'split_among': jsonDecode(row['split_among'] as String),
          'custom_amounts': jsonDecode(row['custom_amounts'] as String),
        }),
    ];
  }

  Future<void> saveExpenses(String planId, List<Expense> expenses) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('expenses', where: 'plan_id = ?', whereArgs: [planId]);
      for (final e in expenses) {
        await txn.insert('expenses', {
          ...e.toJson(),
          'plan_id': planId,
          'split_among': jsonEncode(e.splitAmongIds),
          'custom_amounts': jsonEncode(e.customAmounts),
        });
      }
      await _markSaved(txn, planId, _expensesList);
    });
  }

  Future<void> saveExpense(String planId, Expense e) async {
    final db = await _db;
    await db.insert('expenses', {
      ...e.toJson(),
      'plan_id': planId,
      'split_among': jsonEncode(e.splitAmongIds),
      'custom_amounts': jsonEncode(e.customAmounts),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeExpense(String id) async {
    final db = await _db;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Settlement>?> settlements(String planId) async {
    final db = await _db;
    if (!await _isSaved(db, planId, _settlementsList)) return null;
    final rows = await db.query(
      'settlements',
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    return [for (final row in rows) Settlement.fromJson(row)];
  }

  Future<void> saveSettlements(
    String planId,
    List<Settlement> settlements,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'settlements',
        where: 'plan_id = ?',
        whereArgs: [planId],
      );
      for (final s in settlements) {
        await txn.insert('settlements', {...s.toJson(), 'plan_id': planId});
      }
      await _markSaved(txn, planId, _settlementsList);
    });
  }

  Future<void> saveSettlement(String planId, Settlement s) async {
    final db = await _db;
    await db.insert('settlements', {
      ...s.toJson(),
      'plan_id': planId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeSettlement(String id) async {
    final db = await _db;
    await db.delete('settlements', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<User>> people(String planId) async {
    final db = await _db;
    final rows = await db.query(
      'plan_people',
      where: "plan_id = ? AND name != ''",
      whereArgs: [planId],
    );
    return [
      for (final row in rows)
        User(
          id: row['user_id'] as String,
          name: row['name'] as String,
          lastName: row['last_name'] as String,
          username: '',
          email: '',
          phone: '',
          reimbursementMethods: [
            for (final m in jsonDecode(row['methods'] as String) as List)
              ReimbursementMethod.fromJson(m as Map<String, dynamic>),
          ],
        ),
    ];
  }

  Future<void> savePeople(String planId, List<User> people) async {
    final db = await _db;
    await db.transaction((txn) async {
      final chosen = await _choices(txn, planId);
      for (final u in people) {
        await txn.insert('plan_people', {
          'plan_id': planId,
          'user_id': u.id,
          'name': u.name,
          'last_name': u.lastName,
          'methods': jsonEncode([
            for (final m in u.reimbursementMethods) m.toJson(),
          ]),
          'chosen_method_id': chosen[u.id],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<Map<String, String>> choices(String planId) async =>
      _choices(await _db, planId);

  Future<void> saveChoice(String planId, String userId, String methodId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final updated = await txn.update(
        'plan_people',
        {'chosen_method_id': methodId},
        where: 'plan_id = ? AND user_id = ?',
        whereArgs: [planId, userId],
      );
      if (updated > 0) return;
      await txn.insert('plan_people', {
        'plan_id': planId,
        'user_id': userId,
        'name': '',
        'last_name': '',
        'methods': '[]',
        'chosen_method_id': methodId,
      });
    });
  }

  Future<Map<String, String>> _choices(
    DatabaseExecutor db,
    String planId,
  ) async {
    final rows = await db.query(
      'plan_people',
      columns: ['user_id', 'chosen_method_id'],
      where: 'plan_id = ? AND chosen_method_id IS NOT NULL',
      whereArgs: [planId],
    );
    return {
      for (final row in rows)
        row['user_id'] as String: row['chosen_method_id'] as String,
    };
  }

  Future<void> saveBalances(String uid, List<FriendBalance> friends) async {
    final db = await _db;
    final computedAt = DateTime.now().millisecondsSinceEpoch;
    final plans = {
      for (final friend in friends)
        for (final plan in friend.plans) plan.planId: plan,
    };
    await db.transaction((txn) async {
      await txn.delete('balances', where: 'uid = ?', whereArgs: [uid]);
      await txn.delete('balance_plans', where: 'uid = ?', whereArgs: [uid]);
      for (final plan in plans.values) {
        await txn.insert('balance_plans', {
          'uid': uid,
          'plan_id': plan.planId,
          'name': plan.name,
          'date': plan.date.millisecondsSinceEpoch,
          'computed_at': computedAt,
        });
      }
      for (final friend in friends) {
        for (final plan in friend.plans) {
          await txn.insert('balances', {
            'uid': uid,
            'plan_id': plan.planId,
            'user_id': friend.userId,
            'cents': plan.cents,
            'photo_url': friend.photoUrl,
          });
        }
      }
      await txn.insert('balance_saved', {
        'uid': uid,
        'computed_at': computedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<({List<FriendBalance> friends, DateTime savedAt})?> balances(
    String uid,
  ) async {
    final db = await _db;
    final saved = await db.query(
      'balance_saved',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (saved.isEmpty) return null;
    final totals = await db.rawQuery(
      '''
      SELECT user_id, MAX(photo_url) AS photo_url, SUM(cents) AS cents
      FROM balances
      WHERE uid = ?
      GROUP BY user_id
      HAVING SUM(cents) != 0
      ''',
      [uid],
    );
    final details = await db.rawQuery(
      '''
      SELECT b.user_id, b.plan_id, b.cents, p.name, p.date
      FROM balances b
      JOIN balance_plans p ON p.uid = b.uid AND p.plan_id = b.plan_id
      WHERE b.uid = ?
      ORDER BY p.date DESC
      ''',
      [uid],
    );
    final friends = <FriendBalance>[];
    for (final total in totals) {
      final userId = total['user_id'] as String;
      friends.add(
        FriendBalance(
          userId: userId,
          name: await _personName(db, userId),
          photoUrl: total['photo_url'] as String?,
          totalCents: total['cents'] as int,
          plans: [
            for (final row in details)
              if (row['user_id'] == userId)
                PlanBalance(
                  planId: row['plan_id'] as String,
                  name: row['name'] as String,
                  date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
                  cents: row['cents'] as int,
                ),
          ],
        ),
      );
    }
    return (
      friends: friends,
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        saved.first['computed_at'] as int,
      ),
    );
  }

  Future<String> _personName(DatabaseExecutor db, String userId) async {
    final rows = await db.query(
      'plan_people',
      columns: ['name', 'last_name'],
      where: "user_id = ? AND name != ''",
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return '';
    return '${rows.first['name']} ${rows.first['last_name']}';
  }

  Future<bool> _isSaved(DatabaseExecutor db, String planId, String list) async {
    final rows = await db.query(
      'split_saved',
      where: 'plan_id = ? AND list = ?',
      whereArgs: [planId, list],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _markSaved(DatabaseExecutor db, String planId, String list) =>
      db.insert('split_saved', {
        'plan_id': planId,
        'list': list,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
}
