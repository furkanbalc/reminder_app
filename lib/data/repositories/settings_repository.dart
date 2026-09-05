import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';
import '../models/water_settings.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _goal = 'goal_ml';
  static const _glass = 'default_glass_ml';
  static const _start = 'active_start_min';
  static const _end = 'active_end_min';
  static const _interval = 'interval_min';
  static const _alert = 'alert_type';
  static const _sound = 'sound';
  static const _stop = 'stop_when_goal_reached';
  static const _theme = 'theme_mode';

  WaterSettings load() {
    const d = WaterSettings();
    return WaterSettings(
      goalMl: _prefs.getInt(_goal) ?? d.goalMl,
      defaultGlassMl: _prefs.getInt(_glass) ?? d.defaultGlassMl,
      activeStartMin: _prefs.getInt(_start) ?? d.activeStartMin,
      activeEndMin: _prefs.getInt(_end) ?? d.activeEndMin,
      intervalMin: _prefs.getInt(_interval) ?? d.intervalMin,
      alertType: AlertType.fromName(_prefs.getString(_alert)),
      sound: AlarmSound.fromName(_prefs.getString(_sound)),
      stopWhenGoalReached: _prefs.getBool(_stop) ?? d.stopWhenGoalReached,
      themeMode: AppThemeMode.fromName(_prefs.getString(_theme)),
    );
  }

  Future<void> save(WaterSettings s) async {
    await Future.wait([
      _prefs.setInt(_goal, s.goalMl),
      _prefs.setInt(_glass, s.defaultGlassMl),
      _prefs.setInt(_start, s.activeStartMin),
      _prefs.setInt(_end, s.activeEndMin),
      _prefs.setInt(_interval, s.intervalMin),
      _prefs.setString(_alert, s.alertType.name),
      _prefs.setString(_sound, s.sound.name),
      _prefs.setBool(_stop, s.stopWhenGoalReached),
      _prefs.setString(_theme, s.themeMode.name),
    ]);
  }
}
