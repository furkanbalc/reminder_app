import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Future<Database> open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'su_hatirlatici.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE water_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount_ml INTEGER NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_water_ts ON water_entries(timestamp)');
        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            date_time INTEGER NOT NULL,
            repeat TEXT NOT NULL,
            alert_type TEXT NOT NULL,
            sound TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }
}
