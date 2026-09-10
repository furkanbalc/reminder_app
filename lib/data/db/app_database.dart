import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  /// [path] verilmezse uygulamanın veritabanı klasörü kullanılır (testlerde geçici dosya).
  static Future<Database> open({String? path}) async {
    final dbPath =
        path ?? p.join(await getDatabasesPath(), 'su_hatirlatici.db');
    return openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE water_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount_ml INTEGER NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_water_ts ON water_entries(timestamp)',
        );
        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            date_time INTEGER NOT NULL,
            repeat TEXT NOT NULL,
            alert_type TEXT NOT NULL,
            sound TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL,
            pre_alert_min INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE reminders ADD COLUMN pre_alert_min INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }
}
