import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Su kayıtlarını Apple Sağlık (iOS) veya Health Connect (Android) ile paylaşır.
class HealthService {
  final Health _health = Health();
  bool _configured = false;

  String get platformLabel => Platform.isIOS ? 'Apple Sağlık' : 'Health Connect';

  Future<void> _ensure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> isAvailable() async {
    try {
      await _ensure();
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        return status == HealthConnectSdkStatus.sdkAvailable;
      }
      return Platform.isIOS;
    } catch (e) {
      debugPrint('Sağlık servisi kullanılamıyor: $e');
      return false;
    }
  }

  Future<bool> requestAccess() async {
    try {
      await _ensure();
      return await _health.requestAuthorization(
        [HealthDataType.WATER],
        permissions: [HealthDataAccess.WRITE],
      );
    } catch (e) {
      debugPrint('Sağlık izni alınamadı: $e');
      return false;
    }
  }

  Future<void> writeWater(int amountMl, DateTime at) async {
    try {
      await _ensure();
      await _health.writeHealthData(
        value: amountMl / 1000,
        unit: HealthDataUnit.LITER,
        type: HealthDataType.WATER,
        startTime: at,
        endTime: at,
      );
    } catch (e) {
      debugPrint('Sağlık verisi yazılamadı: $e');
    }
  }

  Future<void> deleteWater(DateTime at) async {
    try {
      await _ensure();
      await _health.delete(type: HealthDataType.WATER, startTime: at, endTime: at);
    } catch (e) {
      debugPrint('Sağlık verisi silinemedi: $e');
    }
  }
}
