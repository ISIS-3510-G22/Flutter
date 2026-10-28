import 'dart:convert';

import 'package:plansync/model/data/local/local_database.dart';
import 'package:plansync/model/models/pending_write.dart';

class WriteQueueStore<K extends Enum> {
  WriteQueueStore(this._table, this._kinds);

  final String _table;
  final List<K> _kinds;

  Map<String, Object?> _toRow(PendingWrite<K> write) => {
    'kind': write.kind.name,
    'docId': write.docId,
    'payload': jsonEncode(write.payload),
  };

  PendingWrite<K> _fromRow(Map<String, Object?> row) => PendingWrite(
    id: row['id'] as int,
    kind: _kinds.byName(row['kind'] as String),
    docId: row['docId'] as String,
    payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
  );

  Future<void> add(PendingWrite<K> write) async {
    final db = await LocalDatabase.instance;
    await db.insert(_table, _toRow(write));
  }

  Future<List<PendingWrite<K>>> all() async {
    final db = await LocalDatabase.instance;
    final rows = await db.query(_table, orderBy: 'id');
    return rows.map(_fromRow).toList();
  }

  Future<void> remove(int id) async {
    final db = await LocalDatabase.instance;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await LocalDatabase.instance;
    await db.delete(_table);
  }
}
