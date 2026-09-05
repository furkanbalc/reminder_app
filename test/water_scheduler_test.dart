import 'package:flutter_test/flutter_test.dart';
import 'package:su_hatirlatici/data/models/water_settings.dart';
import 'package:su_hatirlatici/services/alarm_service.dart';
import 'package:su_hatirlatici/services/notification_service.dart';
import 'package:su_hatirlatici/services/water_scheduler.dart';

void main() {
  final scheduler = WaterScheduler(NotificationService(), AlarmService());
  const settings = WaterSettings(activeStartMin: 8 * 60, activeEndMin: 23 * 60, intervalMin: 90);
  final now = DateTime(2026, 9, 5, 13, 45);

  group('WaterScheduler.slots', () {
    test('sıradaki dilim aktif saatler içinde ve aralığa göre hesaplanır', () {
      final next = scheduler.next(settings, now, goalReachedToday: false);
      // 08:00, 09:30, 11:00, 12:30, 14:00 ...
      expect(next, DateTime(2026, 9, 5, 14, 0));
    });

    test('geçmiş dilimler kurulmaz, yarının dilimleri de eklenir', () {
      final slots = scheduler.slots(settings, now, goalReachedToday: false);
      expect(slots.every((s) => s.at.isAfter(now)), isTrue);
      expect(slots.any((s) => s.at.day == 6 && s.at.hour == 8), isTrue);
      final ids = slots.map((s) => s.id).toSet();
      expect(ids.length, slots.length, reason: 'kimlikler benzersiz olmalı');
      expect(ids.every(WaterScheduler.isWaterId), isTrue);
    });

    test('hedefe ulaşıldıysa bugünkü dilimler atlanır', () {
      final slots = scheduler.slots(settings, now, goalReachedToday: true);
      expect(slots.every((s) => s.at.day == 6), isTrue);
    });

    test('aktif saat bitince sıradaki yarın sabah olur', () {
      final late = DateTime(2026, 9, 5, 23, 30);
      expect(scheduler.next(settings, late, goalReachedToday: false), DateTime(2026, 9, 6, 8, 0));
    });
  });
}
