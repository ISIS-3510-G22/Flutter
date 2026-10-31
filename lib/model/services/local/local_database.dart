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
      version: 9,
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
    await _createSplitTables(db);
    await _createCrewOutbox(db);
    await _createSplitOutbox(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createCrewTables(db);
    }
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
    if (oldVersion < 5) {
      await db.execute('''
        INSERT OR IGNORE INTO crew_cache_state (cacheKey, value)
        SELECT 'groups_saved', CASE
          WHEN EXISTS (
            SELECT 1 FROM group_members WHERE status = 'member'
          ) THEN 1
          ELSE 0
        END
      ''');
    }
    if (oldVersion < 6) {
      await _createSplitTables(db);
    }
    if (oldVersion < 8) {
      await _createCrewOutbox(db);
      await _createSplitOutbox(db);
    }
    if (oldVersion >= 6 && oldVersion < 9) {
      await db.execute(
        "ALTER TABLE expenses ADD COLUMN split_method TEXT NOT NULL "
        "DEFAULT 'equal'",
      );
      await db.execute(
        "ALTER TABLE expenses ADD COLUMN custom_amounts TEXT NOT NULL "
        "DEFAULT '{}'",
      );
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

  static Future<void> _createSplitTables(Database db) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        name TEXT NOT NULL,
        value REAL NOT NULL,
        paid_by_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        split_among TEXT NOT NULL,
        split_method TEXT NOT NULL DEFAULT 'equal',
        custom_amounts TEXT NOT NULL DEFAULT '{}'
      )
    ''');
    await db.execute('''
      CREATE TABLE settlements (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        from_id TEXT NOT NULL,
        to_id TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE plan_people (
        plan_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        methods TEXT NOT NULL,
        chosen_method_id TEXT,
        PRIMARY KEY (plan_id, user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE split_saved (
        plan_id TEXT NOT NULL,
        list TEXT NOT NULL,
        PRIMARY KEY (plan_id, list)
      )
    ''');
  }

  static Future<void> _createCrewOutbox(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS crew_outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        docId TEXT NOT NULL,
        payload TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createSplitOutbox(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS split_outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        docId TEXT NOT NULL,
        payload TEXT NOT NULL
      )
    ''');
  }
}
