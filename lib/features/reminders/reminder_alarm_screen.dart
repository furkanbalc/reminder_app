import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/reminder.dart';
import '../../providers/providers.dart';
import '../water_alarm/alarm_scaffold.dart';

/// Hatırlatıcı çaldığında (alarm) veya bildirimine dokunulduğunda açılan ekran.
class ReminderAlarmScreen extends ConsumerWidget {
  const ReminderAlarmScreen({super.key, required this.reminderId, this.alarmId});

  final int reminderId;
  /// Çalan alarmın kimliği; bildirimden gelindiyse null.
  final int? alarmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final list = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final reminder = list.where((r) => r.id == reminderId).firstOrNull;
    final settings = ref.watch(settingsProvider);

    Future<void> stopIfRinging() async {
      if (alarmId != null) await ref.read(alarmServiceProvider).stop(alarmId!);
    }

    return AlarmScaffold(
      alarmId: alarmId,
      background: c.reminderAlarmBg,
      label: 'Hatırlatma',
      icon: Icons.notifications_none_rounded,
      title: reminder?.title ?? 'Hatırlatma',
      subtitle: reminder == null ? '' : '${reminder.repeat.metaLabel} · ${reminder.alertType.label}',
      primaryLabel: 'Tamam, hallettim',
      onPrimary: () async {
        await stopIfRinging();
        if (reminder != null) {
          await ref.read(reminderSchedulerProvider).acknowledge(reminder);
          await ref.read(remindersProvider.notifier).complete(reminder);
        }
      },
      secondaryLabel: '${settings.snoozeMin} dk ertele',
      onSecondary: () async {
        await stopIfRinging();
        if (reminder != null) {
          await ref.read(reminderSchedulerProvider).acknowledge(reminder);
          await ref.read(remindersProvider.notifier).snooze(reminder);
        }
      },
      caption: alarmId == null
          ? 'Tamam dersen bu hatırlatma kapanır, ertelersen tekrar haber veririm'
          : 'Alarm, Tamam’a basana kadar çalmaya devam eder',
    );
  }
}
