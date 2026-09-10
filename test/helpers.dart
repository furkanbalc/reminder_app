import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:su_hatirlatici/core/theme/app_theme.dart';
import 'package:su_hatirlatici/data/db/app_database.dart';
import 'package:su_hatirlatici/providers/providers.dart';
import 'package:su_hatirlatici/services/notification_service.dart';

/// Testlerde sqflite masaüstünde (ffi) çalışır.
void initSqfliteForTests() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Geçici dosyada yeni bir veritabanı açar.
Future<Database> openTempDb([String name = 'test.db']) async {
  final dir = await Directory.systemTemp.createTemp('su_test_');
  return AppDatabase.open(path: '${dir.path}/$name');
}

Future<void> initLocaleForTests() async {
  await initializeDateFormatting('tr_TR');
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Uygulama temasıyla ve Türkçe yerelle sarılmış widget; ProviderScope içinde.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  SharedPreferences? prefs,
  Database? db,
}) async {
  if (prefs == null) {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (db != null) databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(NotificationService()),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
}
