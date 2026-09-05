import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/water_settings.dart';
import '../../providers/providers.dart';
import 'widgets/add_water_sheet.dart';
import 'widgets/goal_celebration.dart';
import 'widgets/progress_ring.dart';
import 'widgets/stats_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settings = ref.watch(settingsProvider);
    final water = ref.watch(waterProvider).value;
    final now = DateTime.now();
    final total = water?.todayTotalMl ?? 0;
    final progress = settings.goalMl == 0 ? 0.0 : total / settings.goalMl;
    final pct = (progress * 100).round();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(fmtDayHeader(now), style: AppText.body(context, size: 13, weight: FontWeight.w500, color: c.mute)),
                          Text(greeting(now), style: AppText.display(context, size: 26)),
                        ],
                      ),
                    ),
                    CircleIconButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: () => _showReminderStatus(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: ProgressRing(
                  progress: progress,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        spacing: 4,
                        children: [
                          Text(fmtLiters(total), style: AppText.display(context, size: 52, height: 1, letterSpacing: -1)),
                          Text('L', style: AppText.display(context, size: 22, weight: FontWeight.w600)),
                        ],
                      ),
                      Text(
                        'hedef ${fmtLiters(settings.goalMl)} L · %$pct',
                        style: AppText.body(context, size: 14, weight: FontWeight.w500, color: c.mute),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: _NextReminderChip(settings: settings, todayTotalMl: total, lastIntakeAt: water?.lastIntakeAt)),
              const SizedBox(height: 16),
              _QuickAddRow(settings: settings),
              const SizedBox(height: 16),
              if (water != null) StatsCard(state: water, settings: settings),
            ],
          ),
        ),
      ),
    );
  }

  void _showReminderStatus(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        final s = ref.read(settingsProvider);
        final next = ref.read(waterProvider).value?.nextReminder;
        Widget row(IconData icon, String label, String value) => Row(
              spacing: 12,
              children: [
                Icon(icon, size: 20, color: c.mute),
                Expanded(child: Text(label, style: AppText.body(ctx, size: 15, weight: FontWeight.w500))),
                Text(value, style: AppText.body(ctx, size: 15, weight: FontWeight.w600, color: c.mute)),
              ],
            );
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 10, 24, 24 + MediaQuery.paddingOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 18,
            children: [
              const SheetHeader(title: 'Su Hatırlatmaları'),
              row(Icons.alarm_rounded, 'Sonraki', next == null ? 'Bugün için yok' : '${fmtTime(next)} · ${fmtRelative(next)}'),
              row(Icons.wb_sunny_outlined, 'Aktif saatler', '${fmtMinutesOfDay(s.activeStartMin)} – ${fmtMinutesOfDay(s.activeEndMin)}'),
              row(Icons.timer_outlined, 'Aralık', fmtInterval(s.intervalMin)),
              row(s.alertType.name == 'alarm' ? Icons.alarm_on_rounded : Icons.notifications_none_rounded, 'Uyarı tipi', s.alertType.label),
              PrimaryButton(
                label: 'Ayarları düzenle',
                outlined: true,
                textColor: c.ink,
                height: 52,
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(tabIndexProvider.notifier).set(2);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Sıradaki hatırlatmayı ve kalan süreyi gösterir; yarım dakikada bir yeniden hesaplar.
class _NextReminderChip extends ConsumerStatefulWidget {
  const _NextReminderChip({required this.settings, required this.todayTotalMl, this.lastIntakeAt});

  final WaterSettings settings;
  final int todayTotalMl;
  final DateTime? lastIntakeAt;

  @override
  ConsumerState<_NextReminderChip> createState() => _NextReminderChipState();
}

class _NextReminderChipState extends ConsumerState<_NextReminderChip> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final now = DateTime.now();
      final dayChanged = !isSameDay(now, _now);
      setState(() => _now = now);
      // Gün değişince istatistikler ve dilimler baştan yüklensin.
      if (dayChanged) ref.read(waterProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final goalReached = widget.todayTotalMl >= widget.settings.goalMl;
    final next = ref.read(waterSchedulerProvider).next(widget.settings, _now, goalReachedToday: goalReached, lastIntakeAt: widget.lastIntakeAt);
    final String text;
    final IconData icon;
    if (next == null) {
      text = goalReached ? 'Hedefe ulaştın, bugün hatırlatma yok' : 'Bugün için hatırlatma kalmadı';
      icon = goalReached ? Icons.check_circle_outline_rounded : Icons.bedtime_outlined;
    } else {
      text = 'Sonraki hatırlatma ${fmtTime(next)} · ${fmtRelative(next, from: _now)}';
      icon = Icons.alarm_rounded;
    }
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: c.waterSoft, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Icon(icon, size: 18, color: c.waterDeep),
          Text(text, style: AppText.body(context, size: 13, weight: FontWeight.w600, color: c.waterDeep)),
        ],
      ),
    );
  }
}

class _QuickAddRow extends ConsumerWidget {
  const _QuickAddRow({required this.settings});

  final WaterSettings settings;

  static const _icons = [Icons.local_drink_outlined, Icons.water_drop_outlined, Icons.local_cafe_outlined];

  Future<void> _add(BuildContext context, WidgetRef ref, int ml) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(waterProvider.notifier);
    final result = await notifier.addEntry(ml);
    if (result.reachedGoalNow) {
      if (!context.mounted) return;
      await showGoalCelebration(context, goalMl: settings.goalMl, streakDays: result.streakDays);
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$ml ml eklendi'),
        persist: false, // aksiyonlu SnackBar varsayılan olarak kalıcı; 3 sn sonra kapansın
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: 'Geri al', onPressed: () => notifier.deleteEntry(result.entry.id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Row(
      spacing: 10,
      children: [
        for (var i = 0; i < WaterSettings.quickAmounts.length; i++)
          Expanded(
            child: _Tile(
              icon: _icons[i],
              label: '${WaterSettings.quickAmounts[i]} ml',
              onTap: () => _add(context, ref, WaterSettings.quickAmounts[i]),
            ),
          ),
        Expanded(
          child: _Tile(
            icon: Icons.add_rounded,
            label: 'Özel',
            dashed: true,
            labelColor: c.waterDeep,
            onTap: () => showAddWaterSheet(context),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dashed = false,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dashed;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: dashed ? Colors.transparent : c.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dashed ? c.waterDash : c.line, width: dashed ? 1.5 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Icon(icon, size: 24, color: c.water),
              Text(label, style: AppText.body(context, size: 13, weight: FontWeight.w600, color: labelColor)),
            ],
          ),
        ),
      ),
    );
  }
}
