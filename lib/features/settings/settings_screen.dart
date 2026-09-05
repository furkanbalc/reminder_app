import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/android_hints.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/water_settings.dart';
import '../../providers/providers.dart';
import 'pickers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    Future<void> save(WaterSettings next) => notifier.save(next);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: [
              const PageHeader(title: 'Ayarlar'),
              _Section(
                title: 'Su hedefi',
                children: [
                  SettingsRow(
                    label: 'Günlük hedef',
                    trailing: _Stepper(
                      value: '${fmtLiters(s.goalMl)} L',
                      onMinus: s.goalMl > 500
                          ? () => save(s.copyWith(goalMl: s.goalMl - 100))
                          : null,
                      onPlus: s.goalMl < 6000
                          ? () => save(s.copyWith(goalMl: s.goalMl + 100))
                          : null,
                    ),
                  ),
                  SettingsRow(
                    label: 'Varsayılan bardak',
                    last: true,
                    trailing: ValueTrailing('${s.defaultGlassMl} ml'),
                    onTap: () async {
                      final v = await showOptionSheet<int>(
                        context,
                        title: 'Varsayılan bardak',
                        selected: s.defaultGlassMl,
                        options: [
                          for (final g in WaterSettings.glassOptions)
                            PickerOption(g, '$g ml'),
                        ],
                      );
                      if (v != null) save(s.copyWith(defaultGlassMl: v));
                    },
                  ),
                ],
              ),
              _Section(
                title: 'Su hatırlatmaları',
                children: [
                  SettingsRow(
                    label: 'Aktif saatler',
                    trailing: ValueTrailing(
                      '${fmtMinutesOfDay(s.activeStartMin)} – ${fmtMinutesOfDay(s.activeEndMin)}',
                    ),
                    onTap: () => _pickHours(context, s, save, weekend: false),
                  ),
                  SettingsRow(
                    label: 'Hafta sonu farklı',
                    trailing: AppToggle(
                      value: s.weekendEnabled,
                      onChanged: (v) => save(s.copyWith(weekendEnabled: v)),
                    ),
                  ),
                  if (s.weekendEnabled)
                    SettingsRow(
                      label: 'Hafta sonu saatleri',
                      trailing: ValueTrailing(
                        '${fmtMinutesOfDay(s.weekendStartMin)} – ${fmtMinutesOfDay(s.weekendEndMin)}',
                      ),
                      onTap: () => _pickHours(context, s, save, weekend: true),
                    ),
                  SettingsRow(
                    label: 'Hatırlatma aralığı',
                    trailing: ValueTrailing(fmtInterval(s.intervalMin)),
                    onTap: () async {
                      final v = await showOptionSheet<int>(
                        context,
                        title: 'Hatırlatma aralığı',
                        selected: s.intervalMin,
                        options: [
                          for (final m in WaterSettings.intervalOptions)
                            PickerOption(
                              m,
                              m == WaterSettings.testIntervalMin
                                  ? '${fmtInterval(m)} (test)'
                                  : fmtInterval(m),
                            ),
                        ],
                      );
                      if (v != null) save(s.copyWith(intervalMin: v));
                    },
                  ),
                  SettingsRow(
                    label: 'Uyarı tipi',
                    trailing: SegmentedControl(
                      compact: true,
                      height: 28,
                      items: [for (final t in AlertType.values) t.label],
                      selected: s.alertType.index,
                      onChanged: (i) async {
                        final type = AlertType.values[i];
                        await save(s.copyWith(alertType: type));
                        if (type.usesAlarm && context.mounted) {
                          await showFullScreenAlarmHint(
                            context,
                            prefs: ref.read(sharedPreferencesProvider),
                            notifications: ref.read(
                              notificationServiceProvider,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  if (s.alertType == AlertType.escalating)
                    SettingsRow(
                      label: 'Alarma geçiş süresi',
                      trailing: ValueTrailing('${s.escalationMin} dk'),
                      onTap: () async {
                        final v = await showOptionSheet<int>(
                          context,
                          title: 'Yanıt yoksa kaç dakika sonra alarm çalsın?',
                          selected: s.escalationMin,
                          options: [
                            for (final m in WaterSettings.escalationOptions)
                              PickerOption(m, '$m dk'),
                          ],
                        );
                        if (v != null) save(s.copyWith(escalationMin: v));
                      },
                    ),
                  SettingsRow(
                    label: 'Erteleme süresi',
                    trailing: ValueTrailing('${s.snoozeMin} dk'),
                    onTap: () async {
                      final v = await showOptionSheet<int>(
                        context,
                        title: 'Erteleme süresi',
                        selected: s.snoozeMin,
                        options: [
                          for (final m in WaterSettings.snoozeOptions)
                            PickerOption(m, '$m dk'),
                        ],
                      );
                      if (v != null) save(s.copyWith(snoozeMin: v));
                    },
                  ),
                  SettingsRow(
                    label: 'Alarm sesi',
                    trailing: ValueTrailing(s.sound.label),
                    onTap: () async {
                      final v = await showSoundPicker(
                        context,
                        selected: s.sound,
                      );
                      if (v != null) save(s.copyWith(sound: v));
                    },
                  ),
                  SettingsRow(
                    label: 'Alarmı dene',
                    trailing: const ValueTrailing('10 sn sonra çalar'),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref.read(waterSchedulerProvider).testAlarm(s);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Alarm 10 saniye sonra çalacak; ekranı kilitleyip deneyebilirsin',
                          ),
                        ),
                      );
                    },
                  ),
                  SettingsRow(
                    label: 'Hedefe ulaşınca sustur',
                    trailing: AppToggle(
                      value: s.stopWhenGoalReached,
                      onChanged: (v) =>
                          save(s.copyWith(stopWhenGoalReached: v)),
                    ),
                  ),
                  SettingsRow(
                    label: 'Akşam hatırlatması',
                    trailing: AppToggle(
                      value: s.eveningNudge,
                      onChanged: (v) => save(s.copyWith(eveningNudge: v)),
                    ),
                  ),
                  SettingsRow(
                    label: 'Haftalık özet',
                    last: true,
                    trailing: AppToggle(
                      value: s.weeklySummary,
                      onChanged: (v) => save(s.copyWith(weeklySummary: v)),
                    ),
                  ),
                ],
              ),
              _Section(
                title: 'Entegrasyonlar',
                children: [
                  SettingsRow(
                    label:
                        '${ref.read(healthServiceProvider).platformLabel}’a yaz',
                    last: !Platform.isIOS,
                    trailing: AppToggle(
                      value: s.healthSync,
                      onChanged: (v) => _toggleHealth(context, ref, s, v),
                    ),
                  ),
                  if (Platform.isIOS)
                    SettingsRow(
                      label: 'Sistem alarmı (iOS 26+)',
                      last: true,
                      trailing: AppToggle(
                        value: s.useSystemAlarm,
                        onChanged: (v) =>
                            _toggleSystemAlarm(context, ref, s, v),
                      ),
                    ),
                ],
              ),
              _Section(
                title: 'Yedek',
                children: [
                  SettingsRow(
                    label: 'Dışa aktar',
                    trailing: const ValueTrailing('JSON'),
                    onTap: () => _export(context, ref),
                  ),
                  SettingsRow(
                    label: 'İçe aktar',
                    last: true,
                    trailing: const ValueTrailing('Dosya seç'),
                    onTap: () => _import(context, ref),
                  ),
                ],
              ),
              _Section(
                title: 'Genel',
                children: [
                  SettingsRow(
                    label: 'Tema',
                    trailing: ValueTrailing(s.themeMode.label),
                    onTap: () async {
                      final v = await showOptionSheet<AppThemeMode>(
                        context,
                        title: 'Tema',
                        selected: s.themeMode,
                        options: [
                          for (final m in AppThemeMode.values)
                            PickerOption(m, m.label),
                        ],
                      );
                      if (v != null) save(s.copyWith(themeMode: v));
                    },
                  ),
                  if (Platform.isAndroid) ...[
                    SettingsRow(
                      label: 'Pil optimizasyonu',
                      trailing: const _BatteryStatus(),
                      onTap: () => _batteryOptimization(context),
                    ),
                    SettingsRow(
                      label: 'Tam ekran alarm izni',
                      trailing: const ValueTrailing('Ayarları aç'),
                      onTap: () => ref
                          .read(notificationServiceProvider)
                          .requestFullScreenIntentPermission(),
                    ),
                  ],
                  SettingsRow(
                    label: 'Bildirim izinleri',
                    last: true,
                    trailing: const ValueTrailing('Kontrol et'),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await ref
                          .read(notificationServiceProvider)
                          .requestPermissions();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Bildirim izni verildi'
                                : 'Bildirim izni verilmedi. Sistem ayarlarından açabilirsin.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Tüm verilerin yalnızca bu cihazda saklanır.',
                  style: AppText.body(context, size: 12, color: c.mute),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleHealth(
    BuildContext context,
    WidgetRef ref,
    WaterSettings s,
    bool v,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(settingsProvider.notifier);
    if (!v) {
      await notifier.save(s.copyWith(healthSync: false));
      return;
    }
    final health = ref.read(healthServiceProvider);
    if (!await health.isAvailable()) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${health.platformLabel} bu cihazda kullanılamıyor'),
        ),
      );
      return;
    }
    final ok = await health.requestAccess();
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('${health.platformLabel} izni verilmedi')),
      );
      return;
    }
    await notifier.save(s.copyWith(healthSync: true));
    messenger.showSnackBar(
      SnackBar(
        content: Text('Su kayıtları ${health.platformLabel}’a yazılacak'),
      ),
    );
  }

  Future<void> _toggleSystemAlarm(
    BuildContext context,
    WidgetRef ref,
    WaterSettings s,
    bool v,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(settingsProvider.notifier);
    if (!v) {
      await ref.read(alarmServiceProvider).configureSystemAlarm(false);
      await notifier.save(s.copyWith(useSystemAlarm: false));
      return;
    }
    final kit = ref.read(alarmKitServiceProvider);
    if (!await kit.isSupported()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sistem alarmı için iOS 26 veya üzeri gerekir'),
        ),
      );
      return;
    }
    final ok = await kit.requestAuthorization();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Alarm izni verilmedi. Ayarlar > Su Hatırlatıcı’dan açabilirsin.',
          ),
        ),
      );
      return;
    }
    await ref.read(alarmServiceProvider).configureSystemAlarm(true);
    await notifier.save(s.copyWith(useSystemAlarm: true));
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ref
          .read(backupServiceProvider)
          .writeExport(ref.read(settingsProvider));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Su Hatırlatıcı yedeği',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Dışa aktarılamadı: $e')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFiles(type: FileType.any);
    if (picked.isEmpty) return;
    final path = picked.first.path;
    if (path == null) return;
    try {
      final result = await ref
          .read(backupServiceProvider)
          .importFile(File(path), current: ref.read(settingsProvider));
      if (result.settings != null) {
        await ref
            .read(settingsProvider.notifier)
            .save(result.settings!.copyWith(onboardingDone: true));
      }
      await ref.read(waterProvider.notifier).rescheduleReminders();
      ref.invalidate(remindersProvider);
      await ref.read(remindersProvider.notifier).syncAll();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${result.entriesAdded} su kaydı, ${result.remindersAdded} hatırlatıcı içe aktarıldı',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('İçe aktarılamadı: $e')));
    }
  }

  Future<void> _batteryOptimization(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pil optimizasyonunu kapat'),
        content: const Text(
          'Bazı telefonlar pil tasarrufu için arka plandaki alarmları durdurur. '
          'Bu uygulama için pil optimizasyonunu kapatırsan hatırlatmalar ekran kapalıyken ve uygulama kapalıyken de zamanında gelir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ayarları aç'),
          ),
        ],
      ),
    );
    if (go != true) return;
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (!status.isGranted) await openAppSettings();
  }

  Future<void> _pickHours(
    BuildContext context,
    WaterSettings s,
    Future<void> Function(WaterSettings) save, {
    required bool weekend,
  }) async {
    final startMin0 = weekend ? s.weekendStartMin : s.activeStartMin;
    final endMin0 = weekend ? s.weekendEndMin : s.activeEndMin;
    final start = await pickTime(
      context,
      TimeOfDay(hour: startMin0 ~/ 60, minute: startMin0 % 60),
      help: 'Başlangıç saati',
    );
    if (start == null || !context.mounted) return;
    final end = await pickTime(
      context,
      TimeOfDay(hour: endMin0 ~/ 60, minute: endMin0 % 60),
      help: 'Bitiş saati',
    );
    if (end == null) return;
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    if (endMin <= startMin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitiş saati başlangıçtan sonra olmalı'),
          ),
        );
      }
      return;
    }
    await save(
      weekend
          ? s.copyWith(weekendStartMin: startMin, weekendEndMin: endMin)
          : s.copyWith(activeStartMin: startMin, activeEndMin: endMin),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SectionLabel(title),
        GroupedCard(children: children),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        CircleIconButton(
          icon: Icons.remove_rounded,
          size: 34,
          onTap: onMinus,
          iconColor: onMinus == null ? c.mute : c.ink,
        ),
        SizedBox(
          width: 52,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: AppText.display(context, size: 18),
          ),
        ),
        CircleIconButton(
          icon: Icons.add_rounded,
          size: 34,
          color: c.waterSoft,
          iconColor: c.waterDeep,
          bordered: false,
          onTap: onPlus,
        ),
      ],
    );
  }
}

/// Pil optimizasyonu durumu: kapalıysa hatırlatmalar güvende demektir.
class _BatteryStatus extends StatelessWidget {
  const _BatteryStatus();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Permission.ignoreBatteryOptimizations.isGranted,
      builder: (context, snap) {
        final granted = snap.data;
        if (granted == null) return const ValueTrailing('…');
        return ValueTrailing(granted ? 'Kapalı, iyi' : 'Açık');
      },
    );
  }
}
