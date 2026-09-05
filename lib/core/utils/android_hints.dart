import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/notification_service.dart';

const _fullScreenHintKey = 'fullscreen_hint_shown';

/// Android'de alarm tiplerinde kilit ekranında alarm ekranının açılabilmesi için
/// "tam ekran bildirim" izni gerekir (Android 14+). Bir kez hatırlatır.
Future<void> showFullScreenAlarmHint(
  BuildContext context, {
  required SharedPreferences prefs,
  required NotificationService notifications,
  bool force = false,
}) async {
  if (!Platform.isAndroid) return;
  if (!force && (prefs.getBool(_fullScreenHintKey) ?? false)) return;
  await prefs.setBool(_fullScreenHintKey, true);
  if (!context.mounted) return;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Kilit ekranında alarm'),
      content: const Text(
        'Telefon kilitliyken alarmın ekranı açıp "Su zamanı" ekranını göstermesi için '
        'tam ekran bildirim izni gerekiyor. Ayrıca pil optimizasyonunu bu uygulama için kapatman önerilir.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Sonra'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('İzni aç'),
        ),
      ],
    ),
  );
  if (go == true) await notifications.requestFullScreenIntentPermission();
}
