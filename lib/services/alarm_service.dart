import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/enums.dart';
import 'alarmkit_service.dart';

/// "Alarm" modu: durdurana kadar çalar.
///
/// iOS 26 ve üzerinde, ayar açıksa AlarmKit sistem alarmı kullanılır (uygulama
/// kapalıyken de çalar). Diğer durumlarda `alarm` paketi devrededir.
class AlarmService {
  AlarmService(this._prefs, this._kit);

  final SharedPreferences _prefs;
  final AlarmKitService _kit;

  static const _mapKey = 'alarmkit_ids';

  /// Ayarlardan güncellenir; AlarmKit yalnızca izin varsa devreye girer.
  bool useSystemAlarm = false;
  bool _kitReady = false;

  Future<void> configureSystemAlarm(bool enabled) async {
    useSystemAlarm = enabled;
    _kitReady = enabled && await _kit.isAuthorized();
  }

  bool get systemAlarmActive => useSystemAlarm && _kitReady;

  /// Bizim kimlik -> {kit: AlarmKit kimliği, at: kurulum zamanı (ms)}
  Map<String, Map<String, Object?>> _kitIds() {
    final raw = _prefs.getString(_mapKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry(k as String, (v as Map).cast<String, Object?>()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveKitIds(Map<String, Map<String, Object?>> m) => _prefs.setString(_mapKey, jsonEncode(m));

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

    if (systemAlarmActive) {
      await _cancelKit(id);
      final kitId = await _kit.schedule(
        at: at,
        label: title,
        soundAsset: sound.assetPath,
        snoozeMin: snooze?.inMinutes ?? 10,
      );
      if (kitId != null) {
        final m = _kitIds()..['$id'] = {'kit': kitId, 'at': at.millisecondsSinceEpoch};
        await _saveKitIds(m);
        return;
      }
      // AlarmKit başarısız olursa alarm paketine düş.
    }

    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: at,
        assetAudioPath: sound.assetPath,
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: Platform.isIOS && !systemAlarmActive,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fade(
          volume: 0.8,
          fadeDuration: const Duration(seconds: 3),
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

  Future<void> _cancelKit(int id) async {
    final m = _kitIds();
    final entry = m.remove('$id');
    if (entry != null) {
      // Önce eşlemeyi sil: iptal olayı geldiğinde "kullanıcı durdurdu" sanılmasın.
      await _saveKitIds(m);
      await _kit.cancel(entry['kit'] as String);
    }
  }

  Future<bool> stop(int id) async {
    await _cancelKit(id);
    return Alarm.stop(id);
  }

  /// Çalmakta olan alarmlar korunur; yalnızca bekleyenler iptal edilir.
  Future<void> stopWhere(bool Function(int id) test) async {
    final ringing = Alarm.ringing.valueOrNull?.alarms.map((a) => a.id).toSet() ?? const <int>{};
    for (final a in await Alarm.getAlarms()) {
      if (test(a.id) && !ringing.contains(a.id)) await Alarm.stop(a.id);
    }
    final m = _kitIds();
    final toRemove = m.keys.where((k) => test(int.tryParse(k) ?? -1)).toList();
    if (toRemove.isEmpty) return;
    final kitIds = [for (final k in toRemove) m.remove(k)!['kit'] as String];
    await _saveKitIds(m);
    for (final kitId in kitIds) {
      await _kit.cancel(kitId);
    }
  }

  Future<List<AlarmSettings>> scheduled() => Alarm.getAlarms();

  Future<bool> isRinging([int? id]) => Alarm.isRinging(id);

  Stream<AlarmSet> get ringing => Alarm.ringing;

  AlarmSet? get ringingNow => Alarm.ringing.valueOrNull;

  /// AlarmKit kimliğinden bizim kimliğe ve kurulum zamanına. Eşleme yoksa null.
  ({int id, DateTime at})? kitInfo(String kitId) {
    for (final e in _kitIds().entries) {
      if (e.value['kit'] == kitId) {
        final id = int.tryParse(e.key);
        final at = (e.value['at'] as num?)?.toInt();
        if (id == null || at == null) return null;
        return (id: id, at: DateTime.fromMillisecondsSinceEpoch(at));
      }
    }
    return null;
  }

  /// Kullanıcı sistem arayüzünden durdurunca eşlemeyi temizle.
  Future<void> forgetKit(String kitId) async {
    final m = _kitIds();
    m.removeWhere((_, v) => v['kit'] == kitId);
    await _saveKitIds(m);
  }
}
