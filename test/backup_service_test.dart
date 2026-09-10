import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:su_hatirlatici/data/models/enums.dart';
import 'package:su_hatirlatici/data/models/reminder.dart';
import 'package:su_hatirlatici/data/models/water_settings.dart';
import 'package:su_hatirlatici/data/repositories/reminder_repository.dart';
import 'package:su_hatirlatici/data/repositories/water_repository.dart';
import 'package:su_hatirlatici/services/backup_service.dart';

import 'helpers.dart';

void main() {
  setUpAll(initSqfliteForTests);

  late Database source;
  late Database target;

  setUp(() async {
    source = await openTempDb('source.db');
    target = await openTempDb('target.db');
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  test('dışa aktarılan yedek başka bir cihaza içe aktarılır', () async {
    final water = WaterRepository(source);
    await water.add(330, DateTime(2026, 9, 5, 9, 0));
    await water.add(200, DateTime(2026, 9, 5, 12, 0));
    await ReminderRepository(source).insert(
      Reminder(
        id: Reminder.newId,
        title: 'Kargo',
        dateTime: DateTime(2026, 9, 6, 16, 0),
        repeat: RepeatRule.weekly,
        alertType: AlertType.alarm,
        sound: AlarmSound.damla,
        enabled: true,
        createdAt: DateTime(2026, 9, 1),
      ),
    );
    const settings = WaterSettings(
      goalMl: 3000,
      intervalMin: 60,
      alertType: AlertType.escalating,
    );

    final file = await BackupService(
      water,
      ReminderRepository(source),
    ).writeExport(settings);
    final json = jsonDecode(await file.readAsString()) as Map;
    expect(json['app'], 'su_hatirlatici');
    expect((json['waterEntries'] as List).length, 2);
    expect((json['reminders'] as List).length, 1);

    final targetWater = WaterRepository(target);
    final targetReminders = ReminderRepository(target);
    final result = await BackupService(
      targetWater,
      targetReminders,
    ).importFile(file, current: const WaterSettings());
    expect(result.entriesAdded, 2);
    expect(result.remindersAdded, 1);
    expect(result.settings!.goalMl, 3000);
    expect(result.settings!.intervalMin, 60);
    expect(result.settings!.alertType, AlertType.escalating);
    expect((await targetReminders.all()).single.repeat, RepeatRule.weekly);

    // Aynı yedeği ikinci kez almak su kayıtlarını çoğaltmaz.
    final again = await BackupService(
      targetWater,
      targetReminders,
    ).importFile(file, current: const WaterSettings());
    expect(again.entriesAdded, 0);
    expect((await targetWater.all()).length, 2);
  });

  test('başka bir uygulamanın dosyası reddedilir', () async {
    final dir = await Directory.systemTemp.createTemp('su_test_');
    final file = File('${dir.path}/yabanci.json')
      ..writeAsStringSync('{"app": "baska", "waterEntries": []}');
    final service = BackupService(
      WaterRepository(target),
      ReminderRepository(target),
    );
    expect(
      () => service.importFile(file, current: const WaterSettings()),
      throwsA(isA<FormatException>()),
    );
  });
}
