import 'package:flutter/material.dart';

/// Renk tokenları. Açık tema "Sakin Su", koyu tema "Derin Deniz".
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.card,
    required this.line,
    required this.seg,
    required this.ink,
    required this.mute,
    required this.water,
    required this.waterSoft,
    required this.waterDeep,
    required this.waterLight,
    required this.waterDash,
    required this.ringTrack,
    required this.amber,
    required this.amberSoft,
    required this.amberDeep,
    required this.toggleOff,
    required this.chipSelected,
    required this.onChipSelected,
    required this.waterAlarmBg,
    required this.reminderAlarmBg,
    required this.danger,
  });

  final Color bg;
  final Color card;
  final Color line;
  final Color seg;
  final Color ink;
  final Color mute;
  final Color water;
  final Color waterSoft;
  final Color waterDeep;
  final Color waterLight;
  final Color waterDash;
  final Color ringTrack;
  final Color amber;
  final Color amberSoft;
  final Color amberDeep;
  final Color toggleOff;
  final Color chipSelected;
  final Color onChipSelected;
  final Color waterAlarmBg;
  final Color reminderAlarmBg;
  final Color danger;

  static const light = AppColors(
    bg: Color(0xFFF3F6F8),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE3EAF0),
    seg: Color(0xFFE9EFF3),
    ink: Color(0xFF0F1F2E),
    mute: Color(0xFF5B6B7A),
    water: Color(0xFF1F87B4),
    waterSoft: Color(0xFFDCEEF6),
    waterDeep: Color(0xFF0F5A7A),
    waterLight: Color(0xFFA9D3E6),
    waterDash: Color(0xFF9CC9DE),
    ringTrack: Color(0xFFDCEEF6),
    amber: Color(0xFFC67A32),
    amberSoft: Color(0xFFF7E9D8),
    amberDeep: Color(0xFF7A4A1B),
    toggleOff: Color(0xFFD5DEE5),
    chipSelected: Color(0xFF0F1F2E),
    onChipSelected: Color(0xFFFFFFFF),
    waterAlarmBg: Color(0xFF0F5A7A),
    reminderAlarmBg: Color(0xFF7A4A1B),
    danger: Color(0xFFC2453B),
  );

  static const dark = AppColors(
    bg: Color(0xFF0B1622),
    card: Color(0xFF132230),
    line: Color(0xFF1E2E3B),
    seg: Color(0xFF0B1622),
    ink: Color(0xFFEAF2F7),
    mute: Color(0xFF8AA0B0),
    water: Color(0xFF38C6E8),
    waterSoft: Color(0xFF173A48),
    waterDeep: Color(0xFF7ADCF2),
    waterLight: Color(0xFF25566A),
    waterDash: Color(0xFF2F6478),
    ringTrack: Color(0xFF1B2D3B),
    amber: Color(0xFFE09A55),
    amberSoft: Color(0xFF3A2A1A),
    amberDeep: Color(0xFFF1B87E),
    toggleOff: Color(0xFF2A3945),
    chipSelected: Color(0xFFEAF2F7),
    onChipSelected: Color(0xFF0B1622),
    waterAlarmBg: Color(0xFF0C4560),
    reminderAlarmBg: Color(0xFF5E3814),
    danger: Color(0xFFE5716A),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? card,
    Color? line,
    Color? seg,
    Color? ink,
    Color? mute,
    Color? water,
    Color? waterSoft,
    Color? waterDeep,
    Color? waterLight,
    Color? waterDash,
    Color? ringTrack,
    Color? amber,
    Color? amberSoft,
    Color? amberDeep,
    Color? toggleOff,
    Color? chipSelected,
    Color? onChipSelected,
    Color? waterAlarmBg,
    Color? reminderAlarmBg,
    Color? danger,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      line: line ?? this.line,
      seg: seg ?? this.seg,
      ink: ink ?? this.ink,
      mute: mute ?? this.mute,
      water: water ?? this.water,
      waterSoft: waterSoft ?? this.waterSoft,
      waterDeep: waterDeep ?? this.waterDeep,
      waterLight: waterLight ?? this.waterLight,
      waterDash: waterDash ?? this.waterDash,
      ringTrack: ringTrack ?? this.ringTrack,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      amberDeep: amberDeep ?? this.amberDeep,
      toggleOff: toggleOff ?? this.toggleOff,
      chipSelected: chipSelected ?? this.chipSelected,
      onChipSelected: onChipSelected ?? this.onChipSelected,
      waterAlarmBg: waterAlarmBg ?? this.waterAlarmBg,
      reminderAlarmBg: reminderAlarmBg ?? this.reminderAlarmBg,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      card: l(card, other.card),
      line: l(line, other.line),
      seg: l(seg, other.seg),
      ink: l(ink, other.ink),
      mute: l(mute, other.mute),
      water: l(water, other.water),
      waterSoft: l(waterSoft, other.waterSoft),
      waterDeep: l(waterDeep, other.waterDeep),
      waterLight: l(waterLight, other.waterLight),
      waterDash: l(waterDash, other.waterDash),
      ringTrack: l(ringTrack, other.ringTrack),
      amber: l(amber, other.amber),
      amberSoft: l(amberSoft, other.amberSoft),
      amberDeep: l(amberDeep, other.amberDeep),
      toggleOff: l(toggleOff, other.toggleOff),
      chipSelected: l(chipSelected, other.chipSelected),
      onChipSelected: l(onChipSelected, other.onChipSelected),
      waterAlarmBg: l(waterAlarmBg, other.waterAlarmBg),
      reminderAlarmBg: l(reminderAlarmBg, other.reminderAlarmBg),
      danger: l(danger, other.danger),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
