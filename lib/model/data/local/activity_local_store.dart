import 'dart:convert';

import 'package:plansync/model/data/local/local_database.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:sqflite/sqflite.dart';

enum ActivityList { owned, liked, recommended }

class ActivityLocalStore {
  Map<String, Object?> _toRow(Activity activity) => {
    ...activity.toJson(),
    'tags': jsonEncode(activity.tags),
    'likedBy': jsonEncode(activity.likedBy),
  };

  Activity _fromRow(Map<String, Object?> row) => Activity.fromJson({
    ...row,
    'tags': jsonDecode(row['tags'] as String),
    'likedBy': jsonDecode(row['likedBy'] as String),
  });

  Future<List<Activity>> list(String uid, ActivityList list) async {
    final db = await LocalDatabase.instance;
    final rows = await db.rawQuery(
      '''
      SELECT a.* FROM activities a
      JOIN activity_lists l ON l.activityId = a.id
      WHERE l.uid = ? AND l.list = ?
      ORDER BY l.position
      ''',
      [uid, list.name],
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> saveList(
    String uid,
    ActivityList list,
    List<Activity> activities,
  ) async {
    final db = await LocalDatabase.instance;
    final batch = db.batch();
    batch.delete(
      'activity_lists',
      where: 'uid = ? AND list = ?',
      whereArgs: [uid, list.name],
    );
    for (final (i, activity) in activities.indexed) {
      batch.insert(
        'activities',
        _toRow(activity),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert('activity_lists', {
        'uid': uid,
        'list': list.name,
        'activityId': activity.id,
        'position': i,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsert(String uid, Activity activity) async {
    final db = await LocalDatabase.instance;
    final batch = db.batch();
    batch.insert(
      'activities',
      _toRow(activity),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _setMember(
      batch,
      uid,
      ActivityList.owned,
      activity.id,
      activity.ownerId == uid,
    );
    _setMember(
      batch,
      uid,
      ActivityList.liked,
      activity.id,
      activity.likedBy.contains(uid),
    );
    await batch.commit(noResult: true);
  }

  void _setMember(
    Batch batch,
    String uid,
    ActivityList list,
    String activityId,
    bool member,
  ) {
    if (member) {
      batch.insert('activity_lists', {
        'uid': uid,
        'list': list.name,
        'activityId': activityId,
        'position': -1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      batch.delete(
        'activity_lists',
        where: 'uid = ? AND list = ? AND activityId = ?',
        whereArgs: [uid, list.name, activityId],
      );
    }
  }

  Future<List<Activity>> byIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final db = await LocalDatabase.instance;
    final rows = await db.query(
      'activities',
      where: 'id IN (${List.filled(ids.length, '?').join(', ')})',
      whereArgs: ids,
    );
    return rows.map(_fromRow).toList();
  }
}
