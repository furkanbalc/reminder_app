import 'package:flutter/material.dart';

enum AlertType {
  notification('Bildirim', 'Sessizce bildirir, kaydırınca kapanır'),
  alarm('Alarm', 'Durdurana kadar çalar'),
  escalating('Yükselen', 'Önce bildirim, yanıt yoksa alarm');

  const AlertType(this.label, this.description);
  final String label;
  final String description;

  /// Bu tipte bir alarm kurulur mu?
  bool get usesAlarm => this != AlertType.notification;

  /// Bu tipte bir bildirim gönderilir mi?
  bool get usesNotification => this != AlertType.alarm;

  static AlertType fromName(String? name) =>
      AlertType.values.firstWhere((e) => e.name == name, orElse: () => AlertType.notification);
}

enum AlarmSound {
  damla('Damla', 'assets/sounds/damla.wav'),
  klasikZil('Klasik zil', 'assets/sounds/klasik_zil.wav');

  const AlarmSound(this.label, this.assetPath);
  final String label;
  final String assetPath;

  static AlarmSound fromName(String? name) =>
      AlarmSound.values.firstWhere((e) => e.name == name, orElse: () => AlarmSound.damla);
}

enum RepeatRule {
  none('Tek sefer', 'Tek seferlik'),
  daily('Her gün', 'Her gün'),
  weekdays('Hafta içi', 'Hafta içi'),
  weekly('Her hafta', 'Her hafta'),
  monthly('Her ay', 'Her ay');

  const RepeatRule(this.label, this.metaLabel);
  final String label;
  final String metaLabel;

  static RepeatRule fromName(String? name) =>
      RepeatRule.values.firstWhere((e) => e.name == name, orElse: () => RepeatRule.none);
}

enum AppThemeMode {
  system('Sistem', ThemeMode.system),
  light('Açık', ThemeMode.light),
  dark('Koyu', ThemeMode.dark);

  const AppThemeMode(this.label, this.mode);
  final String label;
  final ThemeMode mode;

  static AppThemeMode fromName(String? name) =>
      AppThemeMode.values.firstWhere((e) => e.name == name, orElse: () => AppThemeMode.system);
}
