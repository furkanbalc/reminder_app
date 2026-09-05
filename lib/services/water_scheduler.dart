import '../core/utils/format.dart';
import '../data/models/enums.dart';
import '../data/models/water_settings.dart';
import 'alarm_service.dart';
import 'notification_service.dart';

class WaterSlot {
  const WaterSlot({required this.id, required this.at});
  final int id;
  final DateTime at;
}

/// Su hatırlatmalarını sabit dilimler halinde kurar:
/// aktif başlangıçtan bitişe kadar her [intervalMin] dakikada bir.
/// Bugün ve yarın için kurulur; her su kaydında yeniden hesaplanır.
class WaterScheduler {
  WaterScheduler(this._notifications, this._alarms);

  final NotificationService _notifications;
  final AlarmService _alarms;

  static const baseId = 1000;
  static const perDay = 50;
  static const snoozeId = 1999;
  static const payload = 'water';

  static bool isWaterId(int id) => id >= baseId && id <= snoozeId;

  List<WaterSlot> slots(WaterSettings s, DateTime now, {required bool goalReachedToday}) {
    final result = <WaterSlot>[];
    final threshold = now.add(const Duration(seconds: 30));
    for (var dayOffset = 0; dayOffset < 2; dayOffset++) {
      if (dayOffset == 0 && s.stopWhenGoalReached && goalReachedToday) continue;
      final day = DateTime(now.year, now.month, now.day + dayOffset);
      final end = day.add(Duration(minutes: s.activeEndMin));
      var t = day.add(Duration(minutes: s.activeStartMin));
      var i = 0;
      while (!t.isAfter(end) && i < perDay) {
        if (t.isAfter(threshold)) {
          result.add(WaterSlot(id: baseId + dayOffset * perDay + i, at: t));
        }
        t = t.add(Duration(minutes: s.intervalMin));
        i++;
      }
    }
    return result;
  }

  DateTime? next(WaterSettings s, DateTime now, {required bool goalReachedToday}) {
    final list = slots(s, now, goalReachedToday: goalReachedToday);
    return list.isEmpty ? null : list.first.at;
  }

  Future<void> reschedule({required WaterSettings s, required int todayTotalMl}) async {
    await cancelAll();
    final now = DateTime.now();
    final list = slots(s, now, goalReachedToday: todayTotalMl >= s.goalMl);
    for (final slot in list) {
      await _schedule(slot.id, slot.at, s, todayTotalMl);
    }
  }

  Future<void> snooze({required WaterSettings s, required int todayTotalMl, Duration duration = const Duration(minutes: 10)}) async {
    await _notifications.cancel(snoozeId);
    await _alarms.stop(snoozeId);
    await _schedule(snoozeId, DateTime.now().add(duration), s, todayTotalMl);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelMany([
      for (var i = 0; i < perDay * 2; i++) baseId + i,
      snoozeId,
    ]);
    await _alarms.stopWhere(isWaterId);
  }

  Future<void> _schedule(int id, DateTime at, WaterSettings s, int todayTotalMl) async {
    const title = 'Su içme vakti';
    final body = 'Bir bardak su iç. Bugün ${fmtLiters(todayTotalMl)} / ${fmtLiters(s.goalMl)} L';
    if (s.alertType == AlertType.alarm) {
      await _alarms.schedule(
        id: id,
        at: at,
        title: title,
        body: body,
        sound: s.sound,
        payload: payload,
        snooze: const Duration(minutes: 10),
        snoozeLabel: '10 dk ertele',
      );
    } else {
      await _notifications.schedule(
        id: id,
        title: title,
        body: body,
        at: at,
        payload: payload,
        details: _notifications.waterDetails(glassMl: s.defaultGlassMl),
      );
    }
  }
}
