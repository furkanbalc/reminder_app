import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/reminder.dart';
import '../../providers/providers.dart';
import 'reminder_form_screen.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    final groups = _group(reminders, DateTime.now());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hatırlatıcılar',
                        style: AppText.display(context, size: 28),
                      ),
                    ),
                    CircleIconButton(
                      icon: Icons.add_rounded,
                      color: c.amber,
                      iconColor: Colors.white,
                      bordered: false,
                      onTap: () => _openForm(context),
                    ),
                  ],
                ),
              ),
              if (reminders.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    spacing: 8,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 40,
                        color: c.mute,
                      ),
                      Text(
                        'Henüz hatırlatıcı yok',
                        style: AppText.display(
                          context,
                          size: 18,
                          weight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Unutmak istemediğin bir şeyi + ile ekle,\nzamanı gelince bildirim veya alarmla haber vereyim.',
                        textAlign: TextAlign.center,
                        style: AppText.body(context, size: 14, color: c.mute),
                      ),
                    ],
                  ),
                )
              else
                for (final g in groups) ...[
                  SectionLabel(
                    g.title,
                    padding: EdgeInsets.only(
                      left: 4,
                      top: g == groups.first ? 0 : 8,
                    ),
                  ),
                  for (final item in g.items)
                    Dismissible(
                      key: ValueKey('reminder-${item.reminder.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: c.danger,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) =>
                          _confirmDelete(context, item.reminder),
                      onDismissed: (_) => ref
                          .read(remindersProvider.notifier)
                          .remove(item.reminder.id),
                      child: _ReminderTile(
                        reminder: item.reminder,
                        next: item.next,
                        onTap: () => _openForm(context, item.reminder),
                        onToggle: (v) => ref
                            .read(remindersProvider.notifier)
                            .toggle(item.reminder, v),
                      ),
                    ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Reminder r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hatırlatıcı silinsin mi?'),
        content: Text(r.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sil', style: TextStyle(color: ctx.colors.danger)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _openForm(BuildContext context, [Reminder? initial]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReminderFormScreen(initial: initial),
      ),
    );
  }

  List<_Group> _group(List<Reminder> reminders, DateTime now) {
    final today = startOfDay(now);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(
      Duration(days: 8 - now.weekday),
    ); // pazartesi 00:00

    final active = <_Item>[];
    final off = <_Item>[];
    for (final r in reminders) {
      final next = r.nextOccurrence(now);
      if (r.enabled && next != null) {
        active.add(_Item(r, next));
      } else {
        off.add(_Item(r, null));
      }
    }
    active.sort((a, b) => a.next!.compareTo(b.next!));
    off.sort((a, b) => b.reminder.dateTime.compareTo(a.reminder.dateTime));

    final groups = <_Group>[
      _Group('Bugün', active.where((i) => i.next!.isBefore(tomorrow)).toList()),
      _Group(
        'Yarın',
        active
            .where(
              (i) =>
                  !i.next!.isBefore(tomorrow) &&
                  i.next!.isBefore(tomorrow.add(const Duration(days: 1))),
            )
            .toList(),
      ),
      _Group(
        'Bu hafta',
        active
            .where(
              (i) =>
                  !i.next!.isBefore(tomorrow.add(const Duration(days: 1))) &&
                  i.next!.isBefore(weekEnd),
            )
            .toList(),
      ),
      _Group(
        'Daha sonra',
        active.where((i) => !i.next!.isBefore(weekEnd)).toList(),
      ),
      _Group('Kapalı', off),
    ];
    return groups.where((g) => g.items.isNotEmpty).toList();
  }
}

class _Item {
  const _Item(this.reminder, this.next);
  final Reminder reminder;
  final DateTime? next;
}

class _Group {
  const _Group(this.title, this.items);
  final String title;
  final List<_Item> items;
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.next,
    required this.onTap,
    required this.onToggle,
  });

  final Reminder reminder;
  final DateTime? next;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final on = reminder.enabled && next != null;
    final now = DateTime.now();
    final when = next ?? reminder.dateTime;
    final String meta;
    if (reminder.repeat == RepeatRule.none && !isSameDay(when, now)) {
      meta = '${fmtDateShort(when)} · ${reminder.alertType.label}';
    } else {
      meta = '${reminder.repeat.metaLabel} · ${reminder.alertType.label}';
    }

    return AppCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: onTap,
      child: Row(
        spacing: 14,
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? c.amberSoft : c.seg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              fmtTime(when),
              style: AppText.display(
                context,
                size: 18,
                color: on ? c.amberDeep : c.mute,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  reminder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    context,
                    size: 16,
                    weight: FontWeight.w600,
                    color: on ? c.ink : c.mute,
                  ),
                ),
                Row(
                  spacing: 6,
                  children: [
                    Icon(
                      switch (reminder.alertType) {
                        AlertType.alarm => Icons.alarm_rounded,
                        AlertType.escalating =>
                          Icons.notifications_active_outlined,
                        AlertType.notification =>
                          Icons.notifications_none_rounded,
                      },
                      size: 14,
                      color: c.mute,
                    ),
                    Expanded(
                      child: Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          context,
                          size: 13,
                          weight: FontWeight.w500,
                          color: c.mute,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppToggle(
            value: reminder.enabled,
            onChanged: onToggle,
            activeColor: c.amber,
          ),
        ],
      ),
    );
  }
}
