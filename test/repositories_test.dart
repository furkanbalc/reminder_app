import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:su_hatirlatici/data/db/app_database.dart';
import 'package:su_hatirlatici/data/models/enums.dart';
import 'package:su_hatirlatici/data/models/reminder.dart';
import 'package:su_hatirlatici/data/repositories/reminder_repository.dart';
import 'package:su_hatirlatici/data/repositories/water_repository.dart';

import 'helpers.dart';

void main() {
  setUpAll(initSqfliteForTests);

  group('WaterRepository', () {
    late Database db;
    late WaterRepository repo;

    setUp(() async {
      db = await openTempDb();
      repo = WaterRepository(db);
    });

    tearDown(() => db.close());

    test('ekle, listele, toplam', () async {
      final t1 = DateTime(2026, 9, 5, 9, 0);
      final t2 = DateTime(2026, 9, 5, 12, 30);
      final t3 = DateTime(2026, 9, 6, 8, 0);
      await repo.add(330, t1);
      await repo.add(200, t2);
      await repo.add(500, t3);

      final day = await repo.entriesBetween(
        DateTime(2026, 9, 5),
        DateTime(2026, 9, 6),
      );
      expect(day.map((e) => e.amountMl), [330, 200]);
      expect(day.first.timestamp, t1, reason: 'zaman sırasına göre');
      expect(
        await repo.totalBetween(DateTime(2026, 9, 5), DateTime(2026, 9, 6)),
        530,
      );
      expect(
        await repo.totalBetween(DateTime(2026, 9, 7), DateTime(2026, 9, 8)),
        0,
      );
      expect((await repo.all()).length, 3);
    });

    test('güncelle ve sil', () async {
      final e = await repo.add(330, DateTime(2026, 9, 5, 9, 0));
      await repo.update(e.id, amountMl: 250, at: DateTime(2026, 9, 5, 10, 0));
      final updated = await repo.byId(e.id);
      expect(updated!.amountMl, 250);
      expect(updated.timestamp, DateTime(2026, 9, 5, 10, 0));
      await repo.delete(e.id);
      expect(await repo.byId(e.id), isNull);
    });

    test('aynı zaman ve miktar var mı (içe aktarma için)', () async {
      final at = DateTime(2026, 9, 5, 9, 0);
      await repo.add(330, at);
      expect(await repo.exists(330, at), isTrue);
      expect(await repo.exists(200, at), isFalse);
    });
  });

  group('ReminderRepository', () {
    late Database db;
    late ReminderRepository repo;

    Reminder make(String title) => Reminder(
      id: Reminder.newId,
      title: title,
      dateTime: DateTime(2026, 9, 5, 16, 0),
      repeat: RepeatRule.daily,
      alertType: AlertType.escalating,
      sound: AlarmSound.klasikZil,
      enabled: true,
      createdAt: DateTime(2026, 9, 1),
      preAlertMin: 10,
    );

    setUp(() async {
      db = await openTempDb();
      repo = ReminderRepository(db);
    });

    tearDown(() => db.close());

    test('ekle, oku, güncelle, sil', () async {
      final saved = await repo.insert(make('Kargo'));
      expect(saved.id, isNot(Reminder.newId));

      final read = await repo.byId(saved.id);
      expect(read!.title, 'Kargo');
      expect(read.repeat, RepeatRule.daily);
      expect(read.alertType, AlertType.escalating);
      expect(read.sound, AlarmSound.klasikZil);
      expect(read.preAlertMin, 10);

      await repo.update(read.copyWith(enabled: false, title: 'Kargo (alındı)'));
      final after = await repo.byId(saved.id);
      expect(after!.enabled, isFalse);
      expect(after.title, 'Kargo (alındı)');

      await repo.delete(saved.id);
      expect(await repo.all(), isEmpty);
    });
  });

  test('v1 şemasından v2 ye geçiş pre_alert_min sütununu ekler', () async {
    final dir = await openTempDb().then((d) async {
      final path = d.path;
      await d.close();
      return path;
    });
    // v1 şemasını elle yaz
    await databaseFactory.deleteDatabase(dir);
    final v1 = await openDatabase(
      dir,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          '''
          CREATE TABLE water_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, amount_ml INTEGER NOT NULL, timestamp INTEGER NOT NULL)''',
        );
        await db.execute(
          '''
          CREATE TABLE reminders (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, date_time INTEGER NOT NULL,
            repeat TEXT NOT NULL, alert_type TEXT NOT NULL, sound TEXT NOT NULL, enabled INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL)''',
        );
      },
    );
    await v1.insert('reminders', {
      'title': 'Eski',
      'date_time': DateTime(2026, 9, 5, 16).millisecondsSinceEpoch,
      'repeat': 'none',
      'alert_type': 'alarm',
      'sound': 'damla',
      'enabled': 1,
      'created_at': DateTime(2026, 9, 1).millisecondsSinceEpoch,
    });
    await v1.close();

    final v2 = await AppDatabase.open(path: dir);
    final cols = (await v2.rawQuery(
      'PRAGMA table_info(reminders)',
    )).map((r) => r['name']).toList();
    expect(cols, contains('pre_alert_min'));
    final old = (await ReminderRepository(v2).all()).single;
    expect(old.title, 'Eski');
    expect(old.preAlertMin, 0);
    await v2.close();
  });
}
