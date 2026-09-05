import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// flutter_local_notifications sarmalayıcısı. Sessiz "Bildirim" modu bunu kullanır.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final StreamController<NotificationResponse> _responses = StreamController.broadcast();

  static const waterChannelId = 'su_hatirlatma';
  static const reminderChannelId = 'not_hatirlatici';
  static const waterCategory = 'water';
  static const drankActionId = 'drank';

  Stream<NotificationResponse> get responses => _responses.stream;

  /// Uygulama bir bildirime dokunularak açıldıysa o yanıt.
  NotificationResponse? launchResponse;

  Future<void> init() async {
    await _configureTimeZone();

    const android = AndroidInitializationSettings('ic_notification');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          waterCategory,
          actions: [
            DarwinNotificationAction.plain(
              drankActionId,
              'Su İçtim',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _responses.add,
    );

    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      launchResponse = details!.notificationResponse;
    }
  }

  Future<void> _configureTimeZone() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Saat dilimi alınamadı, UTC kullanılıyor: $e');
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<bool> requestPermissions() async {
    var granted = true;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? true;
      if (await android.canScheduleExactNotifications() == false) {
        await android.requestExactAlarmsPermission();
      }
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      granted = await ios.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    }
    return granted;
  }

  /// Android 14+ için tam ekran alarm izni (sistem ayar sayfasını açar).
  Future<void> requestFullScreenIntentPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestFullScreenIntentPermission();
  }

  NotificationDetails _details({
    required String channelId,
    required String channelName,
    required String channelDescription,
    List<AndroidNotificationAction>? actions,
    String? darwinCategory,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        icon: 'ic_notification',
        color: const Color(0xFF1F87B4),
        actions: actions,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: darwinCategory,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  NotificationDetails waterDetails({required int glassMl}) => _details(
        channelId: waterChannelId,
        channelName: 'Su hatırlatmaları',
        channelDescription: 'Düzenli su içme hatırlatmaları',
        actions: [
          AndroidNotificationAction(
            drankActionId,
            'Su İçtim ($glassMl ml)',
            showsUserInterface: true,
          ),
        ],
        darwinCategory: waterCategory,
      );

  /// Aksiyon butonu olmayan bilgi bildirimi (akşam hatırlatması, haftalık özet).
  NotificationDetails infoDetails() => _details(
        channelId: waterChannelId,
        channelName: 'Su hatırlatmaları',
        channelDescription: 'Düzenli su içme hatırlatmaları',
      );

  NotificationDetails reminderDetails() => _details(
        channelId: reminderChannelId,
        channelName: 'Hatırlatıcılar',
        channelDescription: 'Not hatırlatıcıları',
      );

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
    required NotificationDetails details,
    DateTimeComponents? match,
  }) async {
    final when = tz.TZDateTime.from(at, tz.local);
    if (match == null && when.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: match,
      payload: payload,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelMany(Iterable<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }

  Future<List<int>> pendingIds() async =>
      (await _plugin.pendingNotificationRequests()).map((r) => r.id).toList();
}
