import 'dart:convert';

import 'package:plansync/model/services/local/local_database.dart';
import 'package:plansync/model/models/expense.dart';
import 'package:plansync/model/models/reimbursement_method.dart';
import 'package:plansync/model/models/settlement.dart';
import 'package:plansync/model/models/user.dart';
import 'package:sqflite/sqflite.dart';

class SplitLocalStore {
  Future<Database> get _db => LocalDatabase.instance;

  static const _expensesList = 'expenses';
  static const _settlementsList = 'settlements';

  /// `null` when this plan's expenses were never saved on this phone.
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
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeExpense(String id) async {
    final db = await _db;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// `null` when this plan's settlements were never saved on this phone.
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

  /// Adds or updates these people without dropping the others: Plan expenses
  /// also saves the signed-in user, who may not be going. Each person's
  /// chosen payment method is kept.
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

  /// Upsert: if the person isn't saved yet, a placeholder row (empty name)
  /// keeps the choice until `savePeople` fills it in. `people` skips it.
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
