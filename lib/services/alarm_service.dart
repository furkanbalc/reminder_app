import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';

import '../data/models/enums.dart';

/// alarm paketi sarmalayıcısı. "Alarm" modu: durdurana kadar çalar.
class AlarmService {
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required AlarmSound sound,
    required String payload,
    String stopButton = 'Sustur',
    Duration? snooze,
    String? snoozeLabel,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: at,
        assetAudioPath: sound.assetPath,
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fade(
          volume: 0.8,
          fadeDuration: Duration(seconds: 3),
        ),
        notificationSettings: NotificationSettings(
          title: title,
          body: body,
          stopButton: stopButton,
          androidSnoozeButton: snoozeLabel,
        ),
        payload: payload,
        androidSnoozeDuration: snooze,
      ),
    );
  }

  Future<bool> stop(int id) => Alarm.stop(id);

  /// Çalmakta olan alarmlar korunur; yalnızca bekleyenler iptal edilir.
  Future<void> stopWhere(bool Function(int id) test) async {
    final ringing = Alarm.ringing.valueOrNull?.alarms.map((a) => a.id).toSet() ?? const <int>{};
    for (final a in await Alarm.getAlarms()) {
      if (test(a.id) && !ringing.contains(a.id)) await Alarm.stop(a.id);
    }
  }

  Future<List<AlarmSettings>> scheduled() => Alarm.getAlarms();

  Future<bool> isRinging([int? id]) => Alarm.isRinging(id);

  Stream<AlarmSet> get ringing => Alarm.ringing;

  AlarmSet? get ringingNow => Alarm.ringing.valueOrNull;
}
