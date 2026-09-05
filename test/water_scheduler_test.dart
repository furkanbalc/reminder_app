import 'package:flutter_test/flutter_test.dart';
import 'package:su_hatirlatici/data/models/enums.dart';
import 'package:su_hatirlatici/data/models/water_settings.dart';
import 'package:su_hatirlatici/services/alarm_service.dart';
import 'package:su_hatirlatici/services/alarmkit_service.dart';
import 'package:su_hatirlatici/services/notification_service.dart';
import 'package:su_hatirlatici/services/water_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late WaterScheduler scheduler;
  const settings = WaterSettings(
    activeStartMin: 8 * 60,
    activeEndMin: 23 * 60,
    intervalMin: 90,
  );
  // 5 Eylül 2026 Cumartesi, 13:45
  final now = DateTime(2026, 9, 5, 13, 45);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    scheduler = WaterScheduler(
      NotificationService(),
      AlarmService(prefs, AlarmKitService()),
    );
  });

  group('WaterScheduler.slots', () {
    test('sıradaki dilim aktif saatler içinde ve aralığa göre hesaplanır', () {
      final next = scheduler.next(settings, now, goalReachedToday: false);
      // 08:00, 09:30, 11:00, 12:30, 14:00 ...
      expect(next, DateTime(2026, 9, 5, 14, 0));
    });

    test('geçmiş dilimler kurulmaz, ileri günler de eklenir', () {
      final slots = scheduler.slots(settings, now, goalReachedToday: false);
      expect(slots.every((s) => s.at.isAfter(now)), isTrue);
      expect(slots.any((s) => s.at.day == 6 && s.at.hour == 8), isTrue);
      final ids = slots.map((s) => s.id).toSet();
      expect(ids.length, slots.length, reason: 'kimlikler benzersiz olmalı');
      expect(ids.every(WaterScheduler.isWaterId), isTrue);
    });

    test('hedefe ulaşıldıysa bugünkü dilimler atlanır', () {
      final slots = scheduler.slots(settings, now, goalReachedToday: true);
      expect(slots.any((s) => s.at.day == 5), isFalse);
      expect(slots.first.at, DateTime(2026, 9, 6, 8, 0));
    });

    test('birkaç gün ileriye kurulur ama toplam sınırı aşmaz', () {
      final slots = scheduler.slots(settings, now, goalReachedToday: false);
      expect(
        slots.length,
        lessThanOrEqualTo(WaterScheduler.maxSlotsFor(AlertType.notification)),
      );
      expect(
        slots.map((s) => s.at.day).toSet().length,
        greaterThanOrEqualTo(3),
      );
    });

    test('yükselen modda daha az dilim kurulur (iOS bildirim sınırı)', () {
      const esc = WaterSettings(
        intervalMin: 30,
        alertType: AlertType.escalating,
      );
      final slots = scheduler.slots(esc, now, goalReachedToday: false);
      expect(slots.length, WaterScheduler.maxSlotsFor(AlertType.escalating));
    });

    test('5 dk test aralığında dilimler sınıra kadar sık kurulur', () {
      const fast = WaterSettings(
        activeStartMin: 8 * 60,
        activeEndMin: 23 * 60,
        intervalMin: 5,
      );
      final slots = scheduler.slots(fast, now, goalReachedToday: false);
      expect(slots.length, WaterScheduler.maxSlotsFor(AlertType.notification));
      expect(slots.first.at, DateTime(2026, 9, 5, 13, 50));
      expect(slots[1].at.difference(slots[0].at), const Duration(minutes: 5));
    });

    test('az önce su içildiyse hemen sonraki dilim atlanır', () {
      final justDrank = DateTime(2026, 9, 5, 13, 40);
      final next = scheduler.next(
        settings,
        now,
        goalReachedToday: false,
        lastIntakeAt: justDrank,
      );
      // 14:00 dilimi son içişe 20 dk uzak (< 45 dk), atlanır; sıradaki 15:30
      expect(next, DateTime(2026, 9, 5, 15, 30));
    });

    test('hafta sonu saatleri açıksa cumartesi farklı pencere kullanılır', () {
      const weekend = WaterSettings(
        activeStartMin: 8 * 60,
        activeEndMin: 23 * 60,
        intervalMin: 90,
        weekendEnabled: true,
        weekendStartMin: 14 * 60,
        weekendEndMin: 20 * 60,
      );
      final slots = scheduler.slots(weekend, now, goalReachedToday: false);
      final saturday = slots.where((s) => s.at.day == 5).toList();
      expect(saturday.first.at, DateTime(2026, 9, 5, 14, 0));
      expect(saturday.every((s) => s.at.hour <= 20), isTrue);
      // Pazartesi normal saatler
      final monday = slots.where((s) => s.at.day == 7).toList();
      expect(monday.first.at, DateTime(2026, 9, 7, 8, 0));
    });

    test('aktif saat bitince sıradaki yarın sabah olur', () {
      final late = DateTime(2026, 9, 5, 23, 30);
      expect(
        scheduler.next(settings, late, goalReachedToday: false),
        DateTime(2026, 9, 6, 8, 0),
      );
    });
  });

  test('kiloya göre hedef önerisi', () {
    expect(WaterSettings.suggestedGoal(70), 2500);
    expect(WaterSettings.suggestedGoal(40), 1500);
    expect(WaterSettings.suggestedGoal(150), 5000);
  });
}
