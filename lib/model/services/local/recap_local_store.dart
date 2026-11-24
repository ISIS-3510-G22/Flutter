import 'dart:convert';

import 'package:plansync/model/models/month_recap.dart';
import 'package:plansync/model/services/local/activity_local_store.dart';
import 'package:plansync/model/services/local/local_database.dart';
import 'package:sqflite/sqflite.dart';

class RecapLocalStore {
  Future<void> save(String uid, MonthRecap recap) async {
    final db = await LocalDatabase.instance;
    await db.transaction((txn) async {
      await txn.insert('recap_months', {
        'uid': uid,
        'month': recap.month,
        'plans': recap.plans,
        'activities': recap.activities,
        'spend': recap.spend,
        'topTags': jsonEncode(recap.topTags),
        'updatedAt': recap.updatedAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete(
        'recap_places',
        where: 'uid = ? AND month = ?',
        whereArgs: [uid, recap.month],
      );
      for (final place in recap.places) {
        await txn.insert('recap_places', {
          'uid': uid,
          'month': recap.month,
          'activityId': place.activity.id,
          'times': place.times,
        });
      }
    });
  }

  Future<MonthRecap?> read(String uid, String month) async {
    final db = await LocalDatabase.instance;
    final rows = await db.query(
      'recap_months',
      where: 'uid = ? AND month = ?',
      whereArgs: [uid, month],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final places = await db.rawQuery(
      '''
      SELECT a.*, p.times FROM recap_places p
      JOIN activities a ON a.id = p.activityId
      WHERE p.uid = ? AND p.month = ?
      ORDER BY p.times DESC
      ''',
      [uid, month],
    );
    return MonthRecap(
      month: month,
      plans: row['plans'] as int,
      activities: row['activities'] as int,
      spend: (row['spend'] as num).toDouble(),
      topTags: (jsonDecode(row['topTags'] as String) as List).cast<String>(),
      places: [
        for (final p in places)
          (activity: ActivityLocalStore.fromRow(p), times: p['times'] as int),
      ],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updatedAt'] as int),
    );
  }
}
