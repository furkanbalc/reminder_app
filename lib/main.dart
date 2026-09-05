import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR');
  Intl.defaultLocale = 'tr_TR';

  await Alarm.init();
  final notifications = NotificationService();
  await notifications.init();

  final prefs = await SharedPreferences.getInstance();
  final db = await AppDatabase.open();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const SuApp(),
    ),
  );
}
