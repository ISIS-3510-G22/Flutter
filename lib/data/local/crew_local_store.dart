import 'dart:convert';

import 'package:plansync/data/local/local_database.dart';
import 'package:plansync/models/group.dart';
import 'package:plansync/models/reimbursement_method.dart';
import 'package:plansync/models/user.dart';
import 'package:sqflite/sqflite.dart';

class CrewLocalStore {
  Future<Database> get _db => LocalDatabase.instance;

  Future<List<User>> friends() async {
    final db = await _db;
    final rows = await db.query(
      'people',
      where: 'is_friend = 1',
      orderBy: 'name COLLATE NOCASE, lastName COLLATE NOCASE',
    );
    return rows.map(_userFromRow).toList();
  }

  Future<bool> hasSavedFriends() async {
    final db = await _db;
    final rows = await db.query(
      'crew_cache_state',
      columns: ['value'],
      where: 'cacheKey = ?',
      whereArgs: ['friends_saved'],
      limit: 1,
    );
    return rows.isNotEmpty && rows.first['value'] == 1;
  }

  Future<bool> hasSavedGroups() async {
    final db = await _db;
    final rows = await db.query(
      'crew_cache_state',
      columns: ['value'],
      where: 'cacheKey = ?',
      whereArgs: ['groups_saved'],
      limit: 1,
    );
    return rows.isNotEmpty && rows.first['value'] == 1;
  }

  Future<void> saveFriends(List<User> friends) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('people', {
        'is_friend': 0,
        'email': null,
        'phone': null,
        'methods': null,
      });
      for (final friend in friends) {
        await _saveUser(
          txn,
          friend,
          isFriend: true,
          includePrivateFields: true,
        );
      }
      await txn.insert('crew_cache_state', {
        'cacheKey': 'friends_saved',
        'value': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<User>> directory() async {
    final db = await _db;
    final rows = await db.query(
      'people',
      orderBy: 'name COLLATE NOCASE, lastName COLLATE NOCASE',
    );
    return rows.map(_userFromRow).toList();
  }

  Future<void> saveDirectory(List<User> users) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final user in users) {
        await _saveUser(
          txn,
          user,
          isFriend: false,
          includePrivateFields: false,
        );
      }
    });
  }

  Future<List<Group>> groups() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT DISTINCT g.id, g.name, g.description
      FROM crew_groups AS g
      INNER JOIN group_members AS gm ON gm.groupId = g.id
      WHERE gm.status = 'member'
      ORDER BY g.name COLLATE NOCASE
    ''');
    return rows
        .map(
          (row) => Group(
            id: row['id'] as String,
            name: row['name'] as String,
            description: row['description'] as String,
          ),
        )
        .toList();
  }

  Future<void> saveGroups(
    List<Group> groups,
    Map<String, List<String>> memberIds,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('group_members', where: "status = 'member'");

      for (final group in groups) {
        await txn.insert('crew_groups', {
          'id': group.id,
          'name': group.name,
          'description': group.description,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final userId in memberIds[group.id] ?? const <String>[]) {
          await txn.insert('group_members', {
            'groupId': group.id,
            'userId': userId,
            'status': 'member',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      await txn.insert('crew_cache_state', {
        'cacheKey': 'groups_saved',
        'value': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> saveMemberIds(String groupId, List<String> memberIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'group_members',
        where: "groupId = ? AND status = 'member'",
        whereArgs: [groupId],
      );
      for (final userId in memberIds) {
        await txn.insert('group_members', {
          'groupId': groupId,
          'userId': userId,
          'status': 'member',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<Map<String, int>> memberCounts() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT groupId, COUNT(*) AS memberCount
      FROM group_members
      WHERE status = 'member'
      GROUP BY groupId
    ''');
    return {
      for (final row in rows)
        row['groupId'] as String: row['memberCount'] as int,
    };
  }

  Future<List<String>> memberIds(String groupId) async {
    final db = await _db;
    final rows = await db.query(
      'group_members',
      columns: ['userId'],
      where: "groupId = ? AND status = 'member'",
      whereArgs: [groupId],
      orderBy: 'userId',
    );
    return rows.map((row) => row['userId'] as String).toList();
  }

  Future<List<User>> members(String groupId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT p.*
      FROM people AS p
      INNER JOIN group_members AS gm ON gm.userId = p.id
      WHERE gm.groupId = ? AND gm.status = 'member'
      ORDER BY p.name COLLATE NOCASE, p.lastName COLLATE NOCASE
      ''',
      [groupId],
    );
    return rows.map(_userFromRow).toList();
  }

  Future<void> _saveUser(
    DatabaseExecutor db,
    User user, {
    required bool isFriend,
    required bool includePrivateFields,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('people', {
      'id': user.id,
      'name': user.name,
      'lastName': user.lastName,
      'username': user.username,
      'email': includePrivateFields ? user.email : null,
      'phone': includePrivateFields ? user.phone : null,
      'photoUrl': user.photoUrl,
      'methods': includePrivateFields
          ? jsonEncode(user.reimbursementMethods.map(_methodToMap).toList())
          : null,
      'is_friend': isFriend ? 1 : 0,
      'synced_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final update = <String, Object?>{
      'name': user.name,
      'lastName': user.lastName,
      'username': user.username,
      'photoUrl': user.photoUrl,
      'synced_at': now,
    };
    if (includePrivateFields) {
      update.addAll({
        'email': user.email,
        'phone': user.phone,
        'methods': jsonEncode(
          user.reimbursementMethods.map(_methodToMap).toList(),
        ),
        'is_friend': 1,
      });
    }
    await db.update('people', update, where: 'id = ?', whereArgs: [user.id]);
  }

  User _userFromRow(Map<String, Object?> row) {
    final methods = row['methods'] as String?;
    final decodedMethods = methods == null
        ? const <dynamic>[]
        : jsonDecode(methods) as List<dynamic>;
    return User(
      id: row['id'] as String,
      name: row['name'] as String,
      lastName: row['lastName'] as String,
      username: row['username'] as String,
      email: row['email'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      photoUrl: row['photoUrl'] as String?,
      reimbursementMethods: decodedMethods
          .map((method) => _methodFromMap(method as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, String> _methodToMap(ReimbursementMethod method) => {
    'id': method.id,
    'type': method.type,
    'account': method.account,
  };

  ReimbursementMethod _methodFromMap(Map<String, dynamic> method) =>
      ReimbursementMethod(
        id: method['id'] as String,
        type: method['type'] as String,
        account: method['account'] as String,
      );
}
