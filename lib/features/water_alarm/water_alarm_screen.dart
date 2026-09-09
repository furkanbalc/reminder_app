import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../providers/providers.dart';
import 'alarm_scaffold.dart';

class WaterAlarmScreen extends ConsumerStatefulWidget {
  const WaterAlarmScreen({super.key, required this.alarmId});

  final int alarmId;

  @override
  ConsumerState<WaterAlarmScreen> createState() => _WaterAlarmScreenState();
}

class _WaterAlarmScreenState extends ConsumerState<WaterAlarmScreen> {
  late int _amount;

  @override
  void initState() {
    super.initState();
    _amount = ref.read(settingsProvider).defaultGlassMl;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = ref.watch(settingsProvider);
    final water = ref.watch(waterProvider).value;
    final total = water?.todayTotalMl ?? 0;
    final amounts = {200, 330, 500, settings.defaultGlassMl}.toList()..sort();
    final lastEntry = water?.todayEntries.isNotEmpty == true
        ? water!.todayEntries.first
        : null;

    return AlarmScaffold(
      alarmId: widget.alarmId,
      background: c.waterAlarmBg,
      label: 'Su zamanı',
      icon: Icons.water_drop_outlined,
      title: 'Su içme vakti',
      subtitle:
          'Bugün ${fmtLiters(total)} / ${fmtLiters(settings.goalMl)} L'
          '${lastEntry == null ? '' : ' · Son içiş ${fmtTime(lastEntry.timestamp)}'}',
      extra: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final a in amounts)
            _AmountChip(
              label: '$a ml',
              selected: _amount == a,
              onTap: () => setState(() => _amount = a),
              deep: c.waterAlarmBg,
            ),
        ],
      ),
      primaryLabel: 'Su İçtim',
      onPrimary: () async {
        await ref.read(alarmServiceProvider).stop(widget.alarmId);
        await ref.read(waterProvider.notifier).addEntry(_amount);
      },
      secondaryLabel: '10 dk ertele',
      onSecondary: () async {
        await ref.read(alarmServiceProvider).stop(widget.alarmId);
        await ref
            .read(waterSchedulerProvider)
            .snooze(s: settings, todayTotalMl: total);
        await ref.read(waterProvider.notifier).refresh();
      },
      caption: 'Alarm modunda zil, Su İçtim’e basana kadar çalmaya devam eder',
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.deep,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color deep;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppText.body(
            context,
            size: 14,
            weight: FontWeight.w600,
            color: selected ? deep : Colors.white,
          ),
        ),
      ),
    );
  }
}
