import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
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
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('Ayarlar', style: AppText.display(context, size: 28)),
              ),
              _Section(
                title: 'Su hedefi',
                children: [
                  SettingsRow(
                    label: 'Günlük hedef',
                    trailing: _Stepper(
                      value: '${fmtLiters(s.goalMl)} L',
                      onMinus: s.goalMl > 500 ? () => save(s.copyWith(goalMl: s.goalMl - 100)) : null,
                      onPlus: s.goalMl < 6000 ? () => save(s.copyWith(goalMl: s.goalMl + 100)) : null,
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
                        options: [for (final g in WaterSettings.glassOptions) PickerOption(g, '$g ml')],
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
                    trailing: ValueTrailing('${fmtMinutesOfDay(s.activeStartMin)} – ${fmtMinutesOfDay(s.activeEndMin)}'),
                    onTap: () => _pickActiveHours(context, s, save),
                  ),
                  SettingsRow(
                    label: 'Hatırlatma aralığı',
                    trailing: ValueTrailing(fmtInterval(s.intervalMin)),
                    onTap: () async {
                      final v = await showOptionSheet<int>(
                        context,
                        title: 'Hatırlatma aralığı',
                        selected: s.intervalMin,
                        options: [for (final m in WaterSettings.intervalOptions) PickerOption(m, fmtInterval(m))],
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
                      onChanged: (i) => save(s.copyWith(alertType: AlertType.values[i])),
                    ),
                  ),
                  SettingsRow(
                    label: 'Alarm sesi',
                    trailing: ValueTrailing(s.sound.label),
                    onTap: () async {
                      final v = await showOptionSheet<AlarmSound>(
                        context,
                        title: 'Alarm sesi',
                        selected: s.sound,
                        options: [for (final snd in AlarmSound.values) PickerOption(snd, snd.label)],
                      );
                      if (v != null) save(s.copyWith(sound: v));
                    },
                  ),
                  SettingsRow(
                    label: 'Hedefe ulaşınca sustur',
                    last: true,
                    trailing: AppToggle(
                      value: s.stopWhenGoalReached,
                      onChanged: (v) => save(s.copyWith(stopWhenGoalReached: v)),
                    ),
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
                        options: [for (final m in AppThemeMode.values) PickerOption(m, m.label)],
                      );
                      if (v != null) save(s.copyWith(themeMode: v));
                    },
                  ),
                  SettingsRow(
                    label: 'Bildirim izinleri',
                    last: true,
                    trailing: ValueTrailing('Kontrol et'),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await ref.read(notificationServiceProvider).requestPermissions();
                      messenger.showSnackBar(SnackBar(
                        content: Text(ok ? 'Bildirim izni verildi' : 'Bildirim izni verilmedi. Sistem ayarlarından açabilirsin.'),
                      ));
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

  Future<void> _pickActiveHours(
    BuildContext context,
    WaterSettings s,
    Future<void> Function(WaterSettings) save,
  ) async {
    final start = await pickTime(
      context,
      TimeOfDay(hour: s.activeStartMin ~/ 60, minute: s.activeStartMin % 60),
      help: 'Başlangıç saati',
    );
    if (start == null || !context.mounted) return;
    final end = await pickTime(
      context,
      TimeOfDay(hour: s.activeEndMin ~/ 60, minute: s.activeEndMin % 60),
      help: 'Bitiş saati',
    );
    if (end == null) return;
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    if (endMin <= startMin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitiş saati başlangıçtan sonra olmalı')),
        );
      }
      return;
    }
    await save(s.copyWith(activeStartMin: startMin, activeEndMin: endMin));
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
      children: [SectionLabel(title), GroupedCard(children: children)],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onMinus, required this.onPlus});

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
          child: Text(value, textAlign: TextAlign.center, style: AppText.display(context, size: 18)),
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
