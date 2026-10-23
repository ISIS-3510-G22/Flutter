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
        name TEXT NOT NULL
      )
    ''');
  }
}
