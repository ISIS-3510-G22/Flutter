import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._internal();

  static Future<Database>? _database;

  static Future<Database> get instance => _database ??= _open();

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'plansync.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
    await db.execute('''
      CREATE TABLE pending_writes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        docId TEXT NOT NULL,
        payload TEXT NOT NULL
      )
    ''');
    await _createCrewTables(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createCrewTables(db);
    }
    // Version 1 databases get the current crew schema from _createCrewTables.
    // Version 2 already has the crew tables and needs only these two columns.
    if (oldVersion >= 2 && oldVersion < 3) {
      await db.execute('ALTER TABLE people ADD COLUMN methods TEXT');
      await db.execute(
        'ALTER TABLE people ADD COLUMN synced_at INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 4) {
      await _createCrewCacheState(db);
      await db.execute('''
        INSERT OR IGNORE INTO crew_cache_state (cacheKey, value)
        SELECT 'friends_saved', CASE
          WHEN EXISTS (SELECT 1 FROM people WHERE is_friend = 1) THEN 1
          ELSE 0
        END
      ''');
    }
  }

  static Future<void> _createCrewTables(Database db) async {
    await db.execute('''
      CREATE TABLE people (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lastName TEXT NOT NULL,
        username TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        photoUrl TEXT,
        methods TEXT,
        is_friend INTEGER NOT NULL DEFAULT 0,
        synced_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE crew_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE group_members (
        groupId TEXT NOT NULL REFERENCES crew_groups(id),
        userId TEXT NOT NULL REFERENCES people(id),
        status TEXT NOT NULL CHECK (status IN ('member', 'invited')),
        PRIMARY KEY (groupId, userId)
      )
    ''');
    await _createCrewCacheState(db);
  }

  static Future<void> _createCrewCacheState(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS crew_cache_state (
        cacheKey TEXT PRIMARY KEY,
        value INTEGER NOT NULL
      )
    ''');
  }
}
