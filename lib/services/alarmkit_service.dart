import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';

/// iOS 26+ sistem alarmı (AlarmKit). Uygulama kapalıyken de çalar.
class AlarmKitService {
  final FlutterAlarmkit _kit = FlutterAlarmkit();
  bool? _supported;

  /// Cihaz iOS 26 ve üzeri mi?
  Future<bool> isSupported() async {
    if (!Platform.isIOS) return false;
    if (_supported != null) return _supported!;
    try {
      await _kit.getAuthorizationState();
      _supported = true;
    } on PlatformException catch (e) {
      _supported = e.code != 'UNSUPPORTED_VERSION';
    } catch (_) {
      _supported = false;
    }
    return _supported!;
  }

  Future<bool> isAuthorized() async {
    if (!await isSupported()) return false;
    try {
      return await _kit.getAuthorizationState() ==
          AlarmAuthorizationState.authorized;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestAuthorization() async {
    if (!await isSupported()) return false;
    try {
      return await _kit.requestAuthorization();
    } catch (e) {
      debugPrint('AlarmKit izni alınamadı: $e');
      return false;
    }
  }

  /// Sistem alarmı kurar; AlarmKit'in verdiği kimliği döndürür.
  Future<String?> schedule({
    required DateTime at,
    required String label,
    required String soundAsset,
    required int snoozeMin,
  }) async {
    try {
      return await _kit.scheduleOneShotAlarm(
        timestamp: at.millisecondsSinceEpoch.toDouble(),
        label: label,
        tintColor: '#1F87B4',
        soundPath: soundAsset,
        uiConfig: AlarmUIConfig(
          stopButton: const AlarmButtonConfig(text: 'Tamam', icon: 'checkmark'),
          repeatButton: AlarmButtonConfig(
            text: '$snoozeMin dk ertele',
            icon: 'zzz',
          ),
        ),
      );
    } catch (e) {
      debugPrint('AlarmKit alarmı kurulamadı: $e');
      return null;
    }
  }

  Future<void> cancel(String alarmId) async {
    try {
      await _kit.cancelAlarm(alarmId: alarmId);
    } catch (_) {}
  }

  Future<void> stop(String alarmId) async {
    try {
      await _kit.stopAlarm(alarmId: alarmId);
    } catch (_) {}
  }

  Stream<AlarmUpdateEvent> get updates => _kit.alarmUpdates();
}
