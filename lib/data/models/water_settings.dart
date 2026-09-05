import 'enums.dart';

class WaterSettings {
  const WaterSettings({
    this.goalMl = 2500,
    this.defaultGlassMl = 330,
    this.activeStartMin = 8 * 60,
    this.activeEndMin = 23 * 60,
    this.weekendEnabled = false,
    this.weekendStartMin = 10 * 60,
    this.weekendEndMin = 23 * 60,
    this.intervalMin = 90,
    this.alertType = AlertType.notification,
    this.escalationMin = 10,
    this.snoozeMin = 10,
    this.sound = AlarmSound.damla,
    this.stopWhenGoalReached = true,
    this.eveningNudge = true,
    this.weeklySummary = true,
    this.healthSync = false,
    this.useSystemAlarm = true,
    this.themeMode = AppThemeMode.system,
    this.onboardingDone = false,
    this.weightKg = 70,
  });

  final int goalMl;
  final int defaultGlassMl;

  /// Gün içi dakika (08:00 -> 480)
  final int activeStartMin;
  final int activeEndMin;

  /// Hafta sonu için farklı saatler
  final bool weekendEnabled;
  final int weekendStartMin;
  final int weekendEndMin;
  final int intervalMin;
  final AlertType alertType;

  /// Yükselen modda bildirimden alarma geçiş süresi (dk)
  final int escalationMin;

  /// Erteleme süresi (dk)
  final int snoozeMin;
  final AlarmSound sound;
  final bool stopWhenGoalReached;

  /// Akşam "hedefe X ml kaldı" bildirimi
  final bool eveningNudge;

  /// Pazar akşamı haftalık özet
  final bool weeklySummary;

  /// Apple Sağlık / Health Connect'e yaz
  final bool healthSync;

  /// iOS 26+ sistem alarmı (AlarmKit) kullan
  final bool useSystemAlarm;
  final AppThemeMode themeMode;
  final bool onboardingDone;
  final int weightKg;

  static const quickAmounts = [200, 330, 500];
  static const glassOptions = [150, 200, 250, 330, 400, 500, 750];
  static const intervalOptions = [5, 30, 45, 60, 90, 120, 180];
  static const testIntervalMin = 5;
  static const escalationOptions = [5, 10, 15, 20];
  static const snoozeOptions = [5, 10, 15, 20, 30];

  /// Kiloya göre önerilen günlük hedef (35 ml/kg, 100 ml'ye yuvarlı).
  static int suggestedGoal(int weightKg) {
    final raw = weightKg * 35;
    final rounded = (raw / 100).round() * 100;
    return rounded.clamp(1500, 5000);
  }

  /// Verilen günün aktif saat aralığı (dakika olarak başlangıç, bitiş).
  (int, int) activeWindowFor(DateTime day) {
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    if (weekendEnabled && weekend) return (weekendStartMin, weekendEndMin);
    return (activeStartMin, activeEndMin);
  }

  WaterSettings copyWith({
    int? goalMl,
    int? defaultGlassMl,
    int? activeStartMin,
    int? activeEndMin,
    bool? weekendEnabled,
    int? weekendStartMin,
    int? weekendEndMin,
    int? intervalMin,
    AlertType? alertType,
    int? escalationMin,
    int? snoozeMin,
    AlarmSound? sound,
    bool? stopWhenGoalReached,
    bool? eveningNudge,
    bool? weeklySummary,
    bool? healthSync,
    bool? useSystemAlarm,
    AppThemeMode? themeMode,
    bool? onboardingDone,
    int? weightKg,
  }) {
    return WaterSettings(
      goalMl: goalMl ?? this.goalMl,
      defaultGlassMl: defaultGlassMl ?? this.defaultGlassMl,
      activeStartMin: activeStartMin ?? this.activeStartMin,
      activeEndMin: activeEndMin ?? this.activeEndMin,
      weekendEnabled: weekendEnabled ?? this.weekendEnabled,
      weekendStartMin: weekendStartMin ?? this.weekendStartMin,
      weekendEndMin: weekendEndMin ?? this.weekendEndMin,
      intervalMin: intervalMin ?? this.intervalMin,
      alertType: alertType ?? this.alertType,
      escalationMin: escalationMin ?? this.escalationMin,
      snoozeMin: snoozeMin ?? this.snoozeMin,
      sound: sound ?? this.sound,
      stopWhenGoalReached: stopWhenGoalReached ?? this.stopWhenGoalReached,
      eveningNudge: eveningNudge ?? this.eveningNudge,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      healthSync: healthSync ?? this.healthSync,
      useSystemAlarm: useSystemAlarm ?? this.useSystemAlarm,
      themeMode: themeMode ?? this.themeMode,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  Map<String, Object?> toJson() => {
    'goalMl': goalMl,
    'defaultGlassMl': defaultGlassMl,
    'activeStartMin': activeStartMin,
    'activeEndMin': activeEndMin,
    'weekendEnabled': weekendEnabled,
    'weekendStartMin': weekendStartMin,
    'weekendEndMin': weekendEndMin,
    'intervalMin': intervalMin,
    'alertType': alertType.name,
    'escalationMin': escalationMin,
    'snoozeMin': snoozeMin,
    'sound': sound.name,
    'stopWhenGoalReached': stopWhenGoalReached,
    'eveningNudge': eveningNudge,
    'weeklySummary': weeklySummary,
    'healthSync': healthSync,
    'useSystemAlarm': useSystemAlarm,
    'themeMode': themeMode.name,
    'weightKg': weightKg,
  };

  factory WaterSettings.fromJson(
    Map<String, Object?> j, {
    WaterSettings base = const WaterSettings(),
  }) {
    int i(String k, int d) => (j[k] as num?)?.toInt() ?? d;
    bool b(String k, bool d) => j[k] as bool? ?? d;
    return base.copyWith(
      goalMl: i('goalMl', base.goalMl),
      defaultGlassMl: i('defaultGlassMl', base.defaultGlassMl),
      activeStartMin: i('activeStartMin', base.activeStartMin),
      activeEndMin: i('activeEndMin', base.activeEndMin),
      weekendEnabled: b('weekendEnabled', base.weekendEnabled),
      weekendStartMin: i('weekendStartMin', base.weekendStartMin),
      weekendEndMin: i('weekendEndMin', base.weekendEndMin),
      intervalMin: i('intervalMin', base.intervalMin),
      alertType: AlertType.fromName(j['alertType'] as String?),
      escalationMin: i('escalationMin', base.escalationMin),
      snoozeMin: i('snoozeMin', base.snoozeMin),
      sound: AlarmSound.fromName(j['sound'] as String?),
      stopWhenGoalReached: b('stopWhenGoalReached', base.stopWhenGoalReached),
      eveningNudge: b('eveningNudge', base.eveningNudge),
      weeklySummary: b('weeklySummary', base.weeklySummary),
      healthSync: b('healthSync', base.healthSync),
      useSystemAlarm: b('useSystemAlarm', base.useSystemAlarm),
      themeMode: AppThemeMode.fromName(j['themeMode'] as String?),
      weightKg: i('weightKg', base.weightKg),
    );
  }
}
