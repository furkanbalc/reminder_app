import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:su_hatirlatici/core/utils/stats.dart';
import 'package:su_hatirlatici/data/models/enums.dart';
import 'package:su_hatirlatici/data/models/water_settings.dart';
import 'package:su_hatirlatici/data/repositories/settings_repository.dart';
import 'package:su_hatirlatici/services/reminder_scheduler.dart';
import 'package:su_hatirlatici/services/water_scheduler.dart';

void main() {
  group('WaterSettings', () {
    test('hafta sonu saatleri yalnızca açıkken kullanılır', () {
      const s = WaterSettings(
        activeStartMin: 8 * 60,
        activeEndMin: 23 * 60,
        weekendEnabled: true,
        weekendStartMin: 10 * 60,
        weekendEndMin: 20 * 60,
      );
      expect(s.activeWindowFor(DateTime(2026, 9, 5)), (
        10 * 60,
        20 * 60,
      )); // Cumartesi
      expect(s.activeWindowFor(DateTime(2026, 9, 7)), (
        8 * 60,
        23 * 60,
      )); // Pazartesi
      expect(
        s.copyWith(weekendEnabled: false).activeWindowFor(DateTime(2026, 9, 5)),
        (8 * 60, 23 * 60),
      );
    });

    test('json gidiş dönüş ve eksik alanlarda varsayılanlar', () {
      const s = WaterSettings(
        goalMl: 3200,
        alertType: AlertType.alarm,
        sound: AlarmSound.klasikZil,
        snoozeMin: 15,
      );
      final back = WaterSettings.fromJson(s.toJson());
      expect(back.goalMl, 3200);
      expect(back.alertType, AlertType.alarm);
      expect(back.sound, AlarmSound.klasikZil);
      expect(back.snoozeMin, 15);

      final partial = WaterSettings.fromJson({'goalMl': 2000});
      expect(partial.goalMl, 2000);
      expect(partial.intervalMin, const WaterSettings().intervalMin);
      expect(partial.alertType, AlertType.notification);
    });

    test('bilinmeyen enum adları varsayılana düşer', () {
      expect(AlertType.fromName('yok'), AlertType.notification);
      expect(RepeatRule.fromName(null), RepeatRule.none);
      expect(AlarmSound.fromName('x'), AlarmSound.damla);
      expect(AppThemeMode.fromName('dark'), AppThemeMode.dark);
    });

    test('uyarı tipi bildirim ve alarm kullanımı', () {
      expect(AlertType.notification.usesAlarm, isFalse);
      expect(AlertType.notification.usesNotification, isTrue);
      expect(AlertType.alarm.usesAlarm, isTrue);
      expect(AlertType.alarm.usesNotification, isFalse);
      expect(AlertType.escalating.usesAlarm, isTrue);
      expect(AlertType.escalating.usesNotification, isTrue);
    });
  });

  group('SettingsRepository', () {
    test('kaydet ve yükle', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = SettingsRepository(await SharedPreferences.getInstance());
      expect(repo.load().onboardingDone, isFalse);
      await repo.save(
        const WaterSettings(
          goalMl: 1800,
          intervalMin: 45,
          onboardingDone: true,
          themeMode: AppThemeMode.dark,
        ),
      );
      final s = repo.load();
      expect(s.goalMl, 1800);
      expect(s.intervalMin, 45);
      expect(s.onboardingDone, isTrue);
      expect(s.themeMode, AppThemeMode.dark);
    });

    test('bozuk kayıt varsayılanlara döner', () async {
      SharedPreferences.setMockInitialValues({'settings_json': '{bozuk'});
      final repo = SettingsRepository(await SharedPreferences.getInstance());
      expect(repo.load().goalMl, const WaterSettings().goalMl);
    });
  });

  group('computeStreak', () {
    final today = DateTime(2026, 9, 9);
    DateTime d(int daysAgo) => today.subtract(Duration(days: daysAgo));

    test('bugün hedefe ulaşıldıysa bugün dahil sayılır', () {
      final totals = {today: 2500, d(1): 2600, d(2): 2500, d(3): 1000};
      expect(computeStreak(totals, today, 2500), 3);
    });

    test('bugün henüz ulaşılmadıysa dünle biten seri korunur', () {
      final totals = {today: 800, d(1): 2600, d(2): 2500};
      expect(computeStreak(totals, today, 2500), 2);
    });

    test('dün de kaçırıldıysa seri sıfır', () {
      final totals = {today: 800, d(1): 900, d(2): 2500};
      expect(computeStreak(totals, today, 2500), 0);
    });
  });

  group('kimlik yardımcıları', () {
    test('hatırlatıcı bildirim ve alarm kimlikleri çakışmaz', () {
      final ids = <int>{};
      for (var r = 1; r <= 50; r++) {
        for (var k = 0; k < 20; k++) {
          expect(ids.add(ReminderScheduler.notifId(r, k)), isTrue);
        }
      }
      expect(
        ids.every((id) => !WaterScheduler.isWaterId(id)),
        isTrue,
        reason: 'su kimlikleriyle çakışmamalı',
      );
      for (var r = 1; r <= 50; r++) {
        for (var j = 0; j < 2; j++) {
          final id = ReminderScheduler.alarmId(r, j);
          expect(ReminderScheduler.isReminderAlarmId(id), isTrue);
          expect(ReminderScheduler.reminderIdFromAlarmId(id), r);
          expect(WaterScheduler.isWaterId(id), isFalse);
        }
      }
    });

    test('payload yazılır ve okunur', () {
      expect(
        ReminderScheduler.reminderIdFromPayload(
          ReminderScheduler.payloadFor(42),
        ),
        42,
      );
      expect(ReminderScheduler.reminderIdFromPayload('water'), isNull);
      expect(ReminderScheduler.reminderIdFromPayload(null), isNull);
    });

    test('su kimlik aralıkları', () {
      expect(WaterScheduler.isWaterId(WaterScheduler.baseId), isTrue);
      expect(WaterScheduler.isWaterId(WaterScheduler.snoozeId), isTrue);
      expect(WaterScheduler.isSnoozeId(WaterScheduler.snoozeId + 1), isTrue);
      expect(WaterScheduler.isWaterId(WaterScheduler.eveningId), isTrue);
      expect(WaterScheduler.isWaterId(2000), isFalse);
    });
  });
}
