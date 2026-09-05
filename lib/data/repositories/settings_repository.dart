import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/water_settings.dart';

/// Ayarlar tek bir JSON anahtarında saklanır; yeni alanlar eklemek kolay olsun diye.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'settings_json';
  static const _onboarding = 'onboarding_done';

  WaterSettings load() {
    final raw = _prefs.getString(_key);
    var s = const WaterSettings();
    if (raw != null) {
      try {
        s = WaterSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
      } catch (_) {
        s = const WaterSettings();
      }
    }
    return s.copyWith(onboardingDone: _prefs.getBool(_onboarding) ?? false);
  }

  Future<void> save(WaterSettings s) async {
    await _prefs.setString(_key, jsonEncode(s.toJson()));
    await _prefs.setBool(_onboarding, s.onboardingDone);
  }
}
