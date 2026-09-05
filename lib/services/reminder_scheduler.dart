import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/models/enums.dart';
import '../data/models/reminder.dart';
import 'alarm_service.dart';
import 'notification_service.dart';

/// Not hatırlatıcılarını kurar. Bildirim tipi tekrarları sistemde yinelenir;
/// alarm tipi her seferinde bir sonraki çalma için yeniden kurulur.
class ReminderScheduler {
  ReminderScheduler(this._notifications, this._alarms);

  final NotificationService _notifications;
  final AlarmService _alarms;

  static const _notifBase = 2000;
  static const _alarmBase = 5000;
  static const payloadPrefix = 'reminder:';

  static int notifId(int reminderId, [int k = 0]) => _notifBase + reminderId * 10 + k;
  static int alarmId(int reminderId) => _alarmBase + reminderId * 10;
  static bool isReminderAlarmId(int id) => id >= _alarmBase;
  static int reminderIdFromAlarmId(int id) => (id - _alarmBase) ~/ 10;
  static String payloadFor(int reminderId) => '$payloadPrefix$reminderId';
  static int? reminderIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(payloadPrefix)) return null;
    return int.tryParse(payload.substring(payloadPrefix.length));
  }

  Future<void> sync(Reminder r, {DateTime? from}) async {
    await cancel(r.id);
    if (!r.enabled) return;
    final now = from ?? DateTime.now();
    final next = r.nextOccurrence(now);
    if (next == null) return;

    if (r.alertType == AlertType.alarm) {
      await _alarms.schedule(
        id: alarmId(r.id),
        at: next,
        title: r.title,
        body: 'Hatırlatma · ${r.repeat.metaLabel}',
        sound: r.sound,
        payload: payloadFor(r.id),
        snooze: const Duration(minutes: 15),
        snoozeLabel: '15 dk ertele',
      );
      return;
    }

    final details = _notifications.reminderDetails();
    Future<void> put(int id, DateTime at, DateTimeComponents? match) => _notifications.schedule(
          id: id,
          title: r.title,
          body: 'Hatırlatma · ${r.repeat.metaLabel}',
          at: at,
          payload: payloadFor(r.id),
          details: details,
          match: match,
        );

    switch (r.repeat) {
      case RepeatRule.none:
        await put(notifId(r.id), next, null);
      case RepeatRule.daily:
        await put(notifId(r.id), next, DateTimeComponents.time);
      case RepeatRule.weekly:
        await put(notifId(r.id), next, DateTimeComponents.dayOfWeekAndTime);
      case RepeatRule.monthly:
        await put(notifId(r.id), next, DateTimeComponents.dayOfMonthAndTime);
      case RepeatRule.weekdays:
        for (var wd = DateTime.monday; wd <= DateTime.friday; wd++) {
          final at = _nextWeekday(r, now, wd);
          await put(notifId(r.id, wd), at, DateTimeComponents.dayOfWeekAndTime);
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

  Future<void> snooze(Reminder r, {Duration duration = const Duration(minutes: 15)}) async {
    await _alarms.stop(alarmId(r.id));
    await _alarms.schedule(
      id: alarmId(r.id),
      at: DateTime.now().add(duration),
      title: r.title,
      body: 'Ertelenen hatırlatma',
      sound: r.sound,
      payload: payloadFor(r.id),
      snooze: const Duration(minutes: 15),
      snoozeLabel: '15 dk ertele',
    );
  }

  Future<void> cancel(int reminderId) async {
    await _notifications.cancelMany([for (var k = 0; k <= 5; k++) notifId(reminderId, k)]);
    await _alarms.stop(alarmId(reminderId));
  }
}
