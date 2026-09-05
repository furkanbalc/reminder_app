import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/models/enums.dart';
import '../data/models/reminder.dart';
import '../data/models/water_settings.dart';
import 'alarm_service.dart';
import 'notification_service.dart';

/// Not hatırlatıcılarını kurar.
///
/// Bildirim kimlikleri: 2000 + id*20 + k (k 0–9 ana, 10–18 ön bildirim, 19 erteleme).
/// Alarm kimlikleri: 5000 + id*10 + j (j 0–1: sıradaki iki çalma; yükselen modda j=0).
class ReminderScheduler {
  ReminderScheduler(this._notifications, this._alarms);

  final NotificationService _notifications;
  final AlarmService _alarms;

  static const _notifBase = 2000;
  static const _alarmBase = 5000;
  static const payloadPrefix = 'reminder:';

  static int notifId(int reminderId, [int k = 0]) => _notifBase + reminderId * 20 + k;
  static int alarmId(int reminderId, [int j = 0]) => _alarmBase + reminderId * 10 + j;
  static bool isReminderAlarmId(int id) => id >= _alarmBase;
  static int reminderIdFromAlarmId(int id) => (id - _alarmBase) ~/ 10;
  static String payloadFor(int reminderId) => '$payloadPrefix$reminderId';
  static int? reminderIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(payloadPrefix)) return null;
    return int.tryParse(payload.substring(payloadPrefix.length));
  }

  Future<void> sync(Reminder r, WaterSettings s, {DateTime? from}) async {
    await cancel(r.id);
    if (!r.enabled) return;
    final now = from ?? DateTime.now();
    final next = r.nextOccurrence(now);
    if (next == null) return;

    final body = 'Hatırlatma · ${r.repeat.metaLabel}';

    if (r.alertType.usesNotification) {
      await _scheduleRepeating(r, now, next, offsetK: 0, title: r.title, body: body, minutesBefore: 0);
    }
    if (r.preAlertMin > 0) {
      await _scheduleRepeating(
        r, now, next,
        offsetK: 10,
        title: '${r.preAlertMin} dk sonra: ${r.title}',
        body: 'Yaklaşan hatırlatma',
        minutesBefore: r.preAlertMin,
      );
    }

    switch (r.alertType) {
      case AlertType.notification:
        break;
      case AlertType.alarm:
        final times = r.nextOccurrences(now, 2);
        for (var j = 0; j < times.length; j++) {
          await _alarm(r, s, alarmId(r.id, j), times[j], body);
        }
      case AlertType.escalating:
        await _alarm(
          r, s, alarmId(r.id), next.add(Duration(minutes: s.escalationMin)),
          'Yanıt vermedin · ${r.repeat.metaLabel}',
        );
    }
  }

  Future<void> _alarm(Reminder r, WaterSettings s, int id, DateTime at, String body) => _alarms.schedule(
        id: id,
        at: at,
        title: r.title,
        body: body,
        sound: r.sound,
        payload: payloadFor(r.id),
        snooze: Duration(minutes: s.snoozeMin),
        snoozeLabel: '${s.snoozeMin} dk ertele',
      );

  /// Tekrar kuralına göre sistem bildirimi kurar. [minutesBefore] ön bildirim için.
  Future<void> _scheduleRepeating(
    Reminder r,
    DateTime now,
    DateTime next, {
    required int offsetK,
    required String title,
    required String body,
    required int minutesBefore,
  }) async {
    final details = _notifications.reminderDetails();
    final shift = Duration(minutes: minutesBefore);
    Future<void> put(int id, DateTime at, DateTimeComponents? match) => _notifications.schedule(
          id: id,
          title: title,
          body: body,
          at: at.subtract(shift),
          payload: payloadFor(r.id),
          details: details,
          match: match,
        );

    switch (r.repeat) {
      case RepeatRule.none:
        await put(notifId(r.id, offsetK), next, null);
      case RepeatRule.daily:
        await put(notifId(r.id, offsetK), next, DateTimeComponents.time);
      case RepeatRule.weekly:
        await put(notifId(r.id, offsetK), next, DateTimeComponents.dayOfWeekAndTime);
      case RepeatRule.monthly:
        await put(notifId(r.id, offsetK), next, DateTimeComponents.dayOfMonthAndTime);
      case RepeatRule.weekdays:
        for (var wd = DateTime.monday; wd <= DateTime.friday; wd++) {
          await put(notifId(r.id, offsetK + wd), _nextWeekday(r, now, wd), DateTimeComponents.dayOfWeekAndTime);
        }
    }
  }

  DateTime _nextWeekday(Reminder r, DateTime from, int weekday) {
    var day = DateTime(from.year, from.month, from.day);
    for (var i = 0; i < 8; i++) {
      final t = DateTime(day.year, day.month, day.day, r.dateTime.hour, r.dateTime.minute);
      if (day.weekday == weekday && t.isAfter(from)) return t;
      day = day.add(const Duration(days: 1));
    }
    return from.add(const Duration(days: 7));
  }

  /// Ertele: alarm tiplerinde alarm, bildirim tipinde bildirim kurar.
  Future<void> snooze(Reminder r, WaterSettings s) async {
    final at = DateTime.now().add(Duration(minutes: s.snoozeMin));
    if (r.alertType.usesAlarm) {
      await _alarms.stop(alarmId(r.id));
      await _alarm(r, s, alarmId(r.id), at, 'Ertelenen hatırlatma');
    } else {
      await _notifications.schedule(
        id: notifId(r.id, 19),
        title: r.title,
        body: 'Ertelenen hatırlatma',
        at: at,
        payload: payloadFor(r.id),
        details: _notifications.reminderDetails(),
      );
    }
  }

  /// Bildirime yanıt verildi: bekleyen yükselen alarmı iptal et.
  Future<void> acknowledge(Reminder r) async {
    if (r.alertType == AlertType.escalating) await _alarms.stop(alarmId(r.id));
  }

  Future<void> cancel(int reminderId) async {
    await _notifications.cancelMany([for (var k = 0; k < 20; k++) notifId(reminderId, k)]);
    await _alarms.stop(alarmId(reminderId, 0));
    await _alarms.stop(alarmId(reminderId, 1));
  }
}
