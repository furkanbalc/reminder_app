import 'package:flutter_test/flutter_test.dart';
import 'package:su_hatirlatici/data/models/enums.dart';
import 'package:su_hatirlatici/data/models/reminder.dart';

Reminder make({required DateTime dateTime, RepeatRule repeat = RepeatRule.none}) => Reminder(
      id: 1,
      title: 'Test',
      dateTime: dateTime,
      repeat: repeat,
      alertType: AlertType.notification,
      sound: AlarmSound.damla,
      enabled: true,
      createdAt: DateTime(2026, 9, 1),
    );

void main() {
  // 5 Eylül 2026 Cumartesi, 13:45
  final now = DateTime(2026, 9, 5, 13, 45);

  group('Reminder.nextOccurrence', () {
    test('tek seferlik: ileri tarih aynen döner, geçmiş null', () {
      expect(make(dateTime: DateTime(2026, 9, 5, 16, 0)).nextOccurrence(now), DateTime(2026, 9, 5, 16, 0));
      expect(make(dateTime: DateTime(2026, 9, 5, 9, 0)).nextOccurrence(now), isNull);
    });

    test('her gün: saat geçtiyse yarına kayar', () {
      final r = make(dateTime: DateTime(2026, 9, 1, 9, 0), repeat: RepeatRule.daily);
      expect(r.nextOccurrence(now), DateTime(2026, 9, 6, 9, 0));
      final later = make(dateTime: DateTime(2026, 9, 1, 21, 0), repeat: RepeatRule.daily);
      expect(later.nextOccurrence(now), DateTime(2026, 9, 5, 21, 0));
    });

    test('hafta içi: cumartesiden pazartesiye atlar', () {
      final r = make(dateTime: DateTime(2026, 9, 1, 8, 30), repeat: RepeatRule.weekdays);
      final next = r.nextOccurrence(now)!;
      expect(next.weekday, DateTime.monday);
      expect(next, DateTime(2026, 9, 7, 8, 30));
    });

    test('her hafta: aynı gün ve saat, bir sonraki hafta', () {
      final r = make(dateTime: DateTime(2026, 9, 5, 12, 0), repeat: RepeatRule.weekly); // cumartesi 12:00 geçti
      expect(r.nextOccurrence(now), DateTime(2026, 9, 12, 12, 0));
    });

    test('her ay: 31 olmayan aylarda son güne kırpılır', () {
      final r = make(dateTime: DateTime(2026, 8, 31, 10, 0), repeat: RepeatRule.monthly);
      expect(r.nextOccurrence(now), DateTime(2026, 9, 30, 10, 0));
    });
  });
}
