import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/format.dart';
import '../data/db/app_database.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/water_repository.dart';
import 'alarm_service.dart';
import 'alarmkit_service.dart';
import 'notification_service.dart';
import 'water_scheduler.dart';

/// Ana ekran widget'ına veri gönderir (home_widget).
///
/// Android: `SuWidgetProvider` (RemoteViews). iOS: `SuWidget` WidgetKit hedefi,
/// App Group üzerinden UserDefaults okur.
class WidgetService {
  static const appGroupId = 'group.com.furkanbalci.suHatirlatici';
  static const androidProvider = 'SuWidgetProvider';
  static const androidQualified =
      'com.furkanbalci.su_hatirlatici.SuWidgetProvider';
  static const iosName = 'SuWidget';
  static const addUri = 'suhatirlatici://add';

  Future<void> init() async {
    try {
      if (Platform.isIOS) await HomeWidget.setAppGroupId(appGroupId);
      if (Platform.isAndroid) {
        await HomeWidget.registerInteractivityCallback(
          widgetBackgroundCallback,
        );
      }
    } catch (e) {
      debugPrint('Widget servisi başlatılamadı: $e');
    }
  }

  Future<void> push({
    required int totalMl,
    required int goalMl,
    required int glassMl,
    DateTime? next,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('total_ml', totalMl);
      await HomeWidget.saveWidgetData<int>('goal_ml', goalMl);
      await HomeWidget.saveWidgetData<int>('glass_ml', glassMl);
      await HomeWidget.saveWidgetData<String>(
        'next',
        next == null ? '' : fmtTime(next),
      );
      await HomeWidget.updateWidget(
        androidName: androidProvider,
        qualifiedAndroidName: androidQualified,
        iOSName: iosName,
      );
    } catch (e) {
      debugPrint('Widget güncellenemedi: $e');
    }
  }

  /// Widget'tan uygulamaya dokunuş (URL) akışı.
  Stream<Uri?> get clicks => HomeWidget.widgetClicked;

  Future<Uri?> initialLaunchUri() =>
      HomeWidget.initiallyLaunchedFromHomeWidget();
}

/// Android widget'ındaki "+ bardak" düğmesi: uygulama açılmadan arka planda kayıt ekler.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri?.host != 'add') return;
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsRepository(prefs).load();
  final db = await AppDatabase.open();
  try {
    final repo = WaterRepository(db);
    final now = DateTime.now();
    await repo.add(settings.defaultGlassMl, now);
    final today = startOfDay(now);
    final total = await repo.totalBetween(
      today,
      today.add(const Duration(days: 1)),
    );
    final scheduler = WaterScheduler(
      NotificationService(),
      AlarmService(prefs, AlarmKitService()),
    );
    final next = scheduler.next(
      settings,
      now,
      goalReachedToday: total >= settings.goalMl,
      lastIntakeAt: now,
    );
    await WidgetService().push(
      totalMl: total,
      goalMl: settings.goalMl,
      glassMl: settings.defaultGlassMl,
      next: next,
    );
  } finally {
    await db.close();
  }
}
