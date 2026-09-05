import 'enums.dart';

class WaterSettings {
  const WaterSettings({
    this.goalMl = 2500,
    this.defaultGlassMl = 330,
    this.activeStartMin = 8 * 60,
    this.activeEndMin = 23 * 60,
    this.intervalMin = 90,
    this.alertType = AlertType.notification,
    this.sound = AlarmSound.damla,
    this.stopWhenGoalReached = true,
    this.themeMode = AppThemeMode.system,
  });

  final int goalMl;
  final int defaultGlassMl;
  /// Gün içi dakika (08:00 -> 480)
  final int activeStartMin;
  final int activeEndMin;
  final int intervalMin;
  final AlertType alertType;
  final AlarmSound sound;
  final bool stopWhenGoalReached;
  final AppThemeMode themeMode;

  static const quickAmounts = [200, 330, 500];
  static const glassOptions = [150, 200, 250, 330, 400, 500, 750];
  static const intervalOptions = [30, 45, 60, 90, 120, 180];

  WaterSettings copyWith({
    int? goalMl,
    int? defaultGlassMl,
    int? activeStartMin,
    int? activeEndMin,
    int? intervalMin,
    AlertType? alertType,
    AlarmSound? sound,
    bool? stopWhenGoalReached,
    AppThemeMode? themeMode,
  }) {
    return WaterSettings(
      goalMl: goalMl ?? this.goalMl,
      defaultGlassMl: defaultGlassMl ?? this.defaultGlassMl,
      activeStartMin: activeStartMin ?? this.activeStartMin,
      activeEndMin: activeEndMin ?? this.activeEndMin,
      intervalMin: intervalMin ?? this.intervalMin,
      alertType: alertType ?? this.alertType,
      sound: sound ?? this.sound,
      stopWhenGoalReached: stopWhenGoalReached ?? this.stopWhenGoalReached,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
