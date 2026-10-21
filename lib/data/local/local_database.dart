import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._internal();

  static Future<Database>? _database;

  static Future<Database> get instance => _database ??= _open();

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'plansync.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        ownerId TEXT NOT NULL,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        expectedPrice REAL NOT NULL,
        notes TEXT NOT NULL,
        tags TEXT NOT NULL,
        visibility TEXT NOT NULL,
        likedBy TEXT NOT NULL,
        photoUrl TEXT,
        lat REAL,
        lng REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE activity_lists (
        uid TEXT NOT NULL,
        list TEXT NOT NULL,
        activityId TEXT NOT NULL REFERENCES activities(id),
        position INTEGER NOT NULL,
        PRIMARY KEY (uid, list, activityId)
      )
    ''');
  }
}
