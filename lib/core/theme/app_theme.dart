import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Outfit: başlıklar ve sayılar. DM Sans: gövde metni.
class AppText {
  static TextStyle display(
    BuildContext context, {
    required double size,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.1,
    double? letterSpacing,
  }) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: weight,
      color: color ?? context.colors.ink,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle body(
    BuildContext context, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.35,
    double? letterSpacing,
  }) {
    return GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? context.colors.ink,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle label(BuildContext context, {Color? color}) {
    return GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color ?? context.colors.mute,
      letterSpacing: 0.8,
    );
  }
}

ThemeData buildAppTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? AppColors.light : AppColors.dark;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.water,
    onPrimary: Colors.white,
    secondary: c.amber,
    onSecondary: Colors.white,
    error: c.danger,
    onError: Colors.white,
    surface: c.card,
    onSurface: c.ink,
    surfaceContainerHighest: c.seg,
    onSurfaceVariant: c.mute,
    outline: c.line,
    outlineVariant: c.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    splashFactory: InkSparkle.splashFactory,
  );

  final textTheme = GoogleFonts.dmSansTextTheme(
    base.textTheme,
  ).apply(bodyColor: c.ink, displayColor: c.ink);

  return base.copyWith(
    textTheme: textTheme.copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 52,
        fontWeight: FontWeight.w700,
        color: c.ink,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: c.ink,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: c.ink,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: c.ink,
      ),
    ),
    extensions: [c],
    dividerColor: c.line,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: c.ink,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.dmSans(fontSize: 17, color: c.mute),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.water, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      // Zemin koyu temada açık renge döndüğü için aksiyon rengi her iki temada da koyu mavi kalır.
      actionTextColor: brightness == Brightness.light
          ? c.water
          : AppColors.light.water,
      contentTextStyle: GoogleFonts.dmSans(
        fontSize: 14,
        color: c.bg,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
