import 'package:flutter/foundation.dart';

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
/// Birkaç gün ileriye kurulur; her su kaydında yeniden hesaplanır.
///
/// Kimlik aralıkları (bildirim ve alarm için ayrı ayrı geçerli):
///  1000–1349 dilim bildirimi/alarmı, 1400–1749 yükselen mod alarmı,
///  1990–1991 erteleme, 1997 haftalık özet, 1998 akşam hatırlatması.
class WaterScheduler {
  WaterScheduler(this._notifications, this._alarms);

  final NotificationService _notifications;
  final AlarmService _alarms;

  static const baseId = 1000;
  static const perDay = 50;
  static const daysAhead = 7;
  static const escalationOffset = 400;
  static const snoozeId = 1990;
  static const testId = 1989;
  static const weeklyId = 1997;
  static const eveningId = 1998;
  static const payload = 'water';

  /// iOS'ta bekleyen bildirim sınırı 64. Alarm kurmak bildirimden çok daha pahalı
  /// (her biri ayrı sistem alarmı), o yüzden alarm modlarında daha az dilim kurulur.
  static int maxSlotsFor(AlertType type) => switch (type) {
    AlertType.notification => 48,
    AlertType.alarm => 24,
    AlertType.escalating => 16,
  };

  static bool isWaterId(int id) => id >= baseId && id < 2000;

  List<WaterSlot> slots(
    WaterSettings s,
    DateTime now, {
    required bool goalReachedToday,
    DateTime? lastIntakeAt,
  }) {
    final result = <WaterSlot>[];
    final max = maxSlotsFor(s.alertType);
    final threshold = now.add(const Duration(seconds: 30));
    // Az önce içildiyse hemen ardından gelen dilim atlanır.
    final skipBefore = lastIntakeAt?.add(Duration(minutes: s.intervalMin ~/ 2));

    for (var dayOffset = 0; dayOffset < daysAhead; dayOffset++) {
      if (dayOffset == 0 && s.stopWhenGoalReached && goalReachedToday) continue;
      final day = DateTime(now.year, now.month, now.day + dayOffset);
      final (startMin, endMin) = s.activeWindowFor(day);
      final end = day.add(Duration(minutes: endMin));
      var t = day.add(Duration(minutes: startMin));
      var added = 0;
      while (!t.isAfter(end) && added < perDay) {
        if (result.length >= max) return result;
        final tooSoon = skipBefore != null && t.isBefore(skipBefore);
        if (t.isAfter(threshold) && !tooSoon) {
          result.add(WaterSlot(id: baseId + dayOffset * perDay + added, at: t));
          added++;
        }
        t = t.add(Duration(minutes: s.intervalMin));
      }
    }
    return result;
  }

  DateTime? next(
    WaterSettings s,
    DateTime now, {
    required bool goalReachedToday,
    DateTime? lastIntakeAt,
  }) {
    final list = slots(
      s,
      now,
      goalReachedToday: goalReachedToday,
      lastIntakeAt: lastIntakeAt,
    );
    return list.isEmpty ? null : list.first.at;
  }

  _RescheduleRequest? _pending;
  bool _running = false;

  /// Hatırlatmaları baştan kurar. Üst üste çağrılırsa yalnızca en son istek uygulanır;
  /// böylece eski ayarlarla başlamış bir kurulum yenisinin üstüne yazamaz.
  Future<void> reschedule({
    required WaterSettings s,
    required int todayTotalMl,
    DateTime? lastIntakeAt,
    String? weekSummary,
  }) async {
    _pending = _RescheduleRequest(s, todayTotalMl, lastIntakeAt, weekSummary);
    if (_running) return;
    _running = true;
    try {
      while (_pending != null) {
        final r = _pending!;
        _pending = null;
        await _apply(r);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _apply(_RescheduleRequest r) async {
    final s = r.settings;
    // Çalan bir alarm varken dokunma: "Su İçtim" veya ertele sonrası zaten yeniden kurulur.
    if (await _alarms.isRinging()) {
      debugPrint('Su hatırlatmaları: alarm çalıyor, yeniden kurulum ertelendi');
      return;
    }
    final sw = Stopwatch()..start();
    await cancelAll();
    final now = DateTime.now();
    final list = slots(
      s,
      now,
      goalReachedToday: r.todayTotalMl >= s.goalMl,
      lastIntakeAt: r.lastIntakeAt,
    );
    for (final slot in list) {
      await _schedule(slot, s, isSameDay(slot.at, now) ? r.todayTotalMl : null);
    }
    await _scheduleEveningNudge(s, now, r.todayTotalMl);
    await _scheduleWeeklySummary(s, now, r.weekSummary);
    debugPrint(
      'Su hatırlatmaları kuruldu: ${list.length} dilim, ${s.alertType.name}, ${s.sound.name}, ${sw.elapsedMilliseconds} ms',
    );
  }

  /// Ayarlardaki sesi ve alarm ekranını denemek için 10 saniye sonraya alarm kurar.
  Future<void> testAlarm(WaterSettings s) async {
    await _alarms.stop(testId);
    await _alarms.schedule(
      id: testId,
      at: DateTime.now().add(const Duration(seconds: 10)),
      title: 'Alarm denemesi',
      body: 'Ses: ${s.sound.label}',
      sound: s.sound,
      payload: payload,
      snooze: Duration(minutes: s.snoozeMin),
      snoozeLabel: '${s.snoozeMin} dk ertele',
    );
  }

  Future<void> snooze({
    required WaterSettings s,
    required int todayTotalMl,
  }) async {
    await _notifications.cancel(snoozeId);
    await _alarms.stop(snoozeId);
    await _alarms.stop(snoozeId + 1);
    await _schedule(
      WaterSlot(
        id: snoozeId,
        at: DateTime.now().add(Duration(minutes: s.snoozeMin)),
      ),
      s,
      todayTotalMl,
      escalationId: snoozeId + 1,
    );
  }

  Future<void> cancelAll() async {
    final pending = await _notifications.pendingIds();
    await _notifications.cancelMany(pending.where(isWaterId));
    await _alarms.stopWhere(isWaterId);
  }

  Future<void> _schedule(
    WaterSlot slot,
    WaterSettings s,
    int? todayTotalMl, {
    int? escalationId,
  }) async {
    const title = 'Su içme vakti';
    final progress = todayTotalMl == null
        ? 'Günlük hedef ${fmtLiters(s.goalMl)} L'
        : 'Bugün ${fmtLiters(todayTotalMl)} / ${fmtLiters(s.goalMl)} L';

    switch (s.alertType) {
      case AlertType.notification:
        await _notifications.schedule(
          id: slot.id,
          title: title,
          body: 'Bir bardak su iç. $progress',
          at: slot.at,
          payload: payload,
          details: _notifications.waterDetails(glassMl: s.defaultGlassMl),
        );
      case AlertType.alarm:
        await _alarms.schedule(
          id: slot.id,
          at: slot.at,
          title: title,
          body: progress,
          sound: s.sound,
          payload: payload,
          snooze: Duration(minutes: s.snoozeMin),
          snoozeLabel: '${s.snoozeMin} dk ertele',
        );
      case AlertType.escalating:
        await _notifications.schedule(
          id: slot.id,
          title: title,
          body:
              'Bir bardak su iç. $progress · ${s.escalationMin} dk içinde yanıt yoksa alarm çalar',
          at: slot.at,
          payload: payload,
          details: _notifications.waterDetails(glassMl: s.defaultGlassMl),
        );
        await _alarms.schedule(
          id: escalationId ?? slot.id + escalationOffset,
          at: slot.at.add(Duration(minutes: s.escalationMin)),
          title: 'Su içmeyi unuttun',
          body: progress,
          sound: s.sound,
          payload: payload,
          snooze: Duration(minutes: s.snoozeMin),
          snoozeLabel: '${s.snoozeMin} dk ertele',
        );
    }
  }

  Future<void> _scheduleEveningNudge(
    WaterSettings s,
    DateTime now,
    int todayTotalMl,
  ) async {
    if (!s.eveningNudge || todayTotalMl >= s.goalMl) return;
    final (_, endMin) = s.activeWindowFor(now);
    final at = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(minutes: endMin - 120));
    if (!at.isAfter(now)) return;
    final remaining = s.goalMl - todayTotalMl;
    await _notifications.schedule(
      id: eveningId,
      title: 'Hedefe az kaldı',
      body:
          'Bugün ${fmtLiters(todayTotalMl)} L içtin, hedefe $remaining ml kaldı.',
      at: at,
      payload: payload,
      details: _notifications.infoDetails(),
    );
  }

  Future<void> _scheduleWeeklySummary(
    WaterSettings s,
    DateTime now,
    String? summary,
  ) async {
    if (!s.weeklySummary || summary == null) return;
    var sunday = DateTime(
      now.year,
      now.month,
      now.day + (DateTime.sunday - now.weekday) % 7,
      20,
      0,
    );
    if (!sunday.isAfter(now)) sunday = sunday.add(const Duration(days: 7));
    await _notifications.schedule(
      id: weeklyId,
      title: 'Haftalık özet',
      body: summary,
      at: sunday,
      payload: payload,
      details: _notifications.infoDetails(),
    );
  }
}

class _RescheduleRequest {
  const _RescheduleRequest(
    this.settings,
    this.todayTotalMl,
    this.lastIntakeAt,
    this.weekSummary,
  );
  final WaterSettings settings;
  final int todayTotalMl;
  final DateTime? lastIntakeAt;
  final String? weekSummary;
}
