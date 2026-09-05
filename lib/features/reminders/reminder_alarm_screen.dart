import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/reminder.dart';
import '../../providers/providers.dart';
import '../water_alarm/alarm_scaffold.dart';

class ReminderAlarmScreen extends ConsumerWidget {
  const ReminderAlarmScreen({super.key, required this.alarmId, required this.reminderId});

  final int alarmId;
  final int reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final list = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final reminder = list.where((r) => r.id == reminderId).firstOrNull;

    return AlarmScaffold(
      alarmId: alarmId,
      background: c.reminderAlarmBg,
      label: 'Hatırlatma',
      icon: Icons.notifications_none_rounded,
      title: reminder?.title ?? 'Hatırlatma',
      subtitle: reminder == null ? 'Alarm' : '${reminder.repeat.metaLabel} · ${reminder.alertType.label}',
      primaryLabel: 'Tamam, hallettim',
      onPrimary: () async {
        await ref.read(alarmServiceProvider).stop(alarmId);
        if (reminder != null) await ref.read(remindersProvider.notifier).complete(reminder);
      },
      secondaryLabel: '15 dk ertele',
      onSecondary: () async {
        await ref.read(alarmServiceProvider).stop(alarmId);
        if (reminder != null) await ref.read(reminderSchedulerProvider).snooze(reminder);
      },
      caption: 'Alarm modunda zil, Tamam’a basana kadar çalmaya devam eder',
    );
  }
}
