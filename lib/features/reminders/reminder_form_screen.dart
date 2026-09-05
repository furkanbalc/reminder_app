import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/reminder.dart';
import '../../providers/providers.dart';
import '../settings/pickers.dart';

class ReminderFormScreen extends ConsumerStatefulWidget {
  const ReminderFormScreen({super.key, this.initial});

  final Reminder? initial;

  @override
  ConsumerState<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  late final TextEditingController _title;
  late DateTime _dateTime;
  late RepeatRule _repeat;
  late AlertType _alertType;
  late AlarmSound _sound;
  late int _preAlertMin;
  bool _saving = false;

  bool get _isNew => widget.initial == null;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _title = TextEditingController(text: r?.title ?? '');
    final now = DateTime.now();
    _dateTime = r?.dateTime ?? DateTime(now.year, now.month, now.day, now.hour + 1);
    _repeat = r?.repeat ?? RepeatRule.none;
    _alertType = r?.alertType ?? ref.read(settingsProvider).alertType;
    _sound = r?.sound ?? ref.read(settingsProvider).sound;
    _preAlertMin = r?.preAlertMin ?? 0;
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dateTime.isBefore(now) ? now : _dateTime,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      helpText: 'Tarih seç',
    );
    if (d == null) return;
    setState(() => _dateTime = DateTime(d.year, d.month, d.day, _dateTime.hour, _dateTime.minute));
  }

  Future<void> _pickTime() async {
    final t = await pickTime(context, TimeOfDay.fromDateTime(_dateTime), help: 'Saat seç');
    if (t == null) return;
    setState(() => _dateTime = DateTime(_dateTime.year, _dateTime.month, _dateTime.day, t.hour, t.minute));
  }

  static String _preAlertLabel(int m) => switch (m) {
        0 => 'Yok',
        60 => '1 sa önce',
        _ => '$m dk önce',
      };

  Future<void> _pickPreAlert() async {
    final v = await showOptionSheet<int>(
      context,
      title: 'Önceden haber ver',
      selected: _preAlertMin,
      accent: context.colors.amber,
      options: [for (final m in Reminder.preAlertOptions) PickerOption(m, _preAlertLabel(m))],
    );
    if (v != null) setState(() => _preAlertMin = v);
  }

  Future<void> _pickSound() async {
    final v = await showSoundPicker(context, selected: _sound, accent: context.colors.amber);
    if (v != null) setState(() => _sound = v);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    if (_repeat == RepeatRule.none && !_dateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçmiş bir zaman seçtin, ileri bir zaman seç')),
      );
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final notifier = ref.read(remindersProvider.notifier);
    final base = widget.initial ??
        Reminder(
          id: Reminder.newId,
          title: title,
          dateTime: _dateTime,
          repeat: _repeat,
          alertType: _alertType,
          sound: _sound,
          enabled: true,
          createdAt: DateTime.now(),
          preAlertMin: _preAlertMin,
        );
    final r = base.copyWith(
      title: title,
      dateTime: _dateTime,
      repeat: _repeat,
      alertType: _alertType,
      sound: _sound,
      enabled: true,
      preAlertMin: _preAlertMin,
    );
    if (_isNew) {
      await notifier.add(r);
    } else {
      await notifier.edit(r);
    }
    navigator.pop();
  }

  Future<void> _delete() async {
    final r = widget.initial;
    if (r == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hatırlatıcı silinsin mi?'),
        content: Text(r.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sil', style: TextStyle(color: ctx.colors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final navigator = Navigator.of(context);
    await ref.read(remindersProvider.notifier).remove(r.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canSave = _title.text.trim().isNotEmpty && !_saving;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Yeni Hatırlatıcı' : 'Hatırlatıcıyı Düzenle'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (!_isNew)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: c.danger),
              tooltip: 'Sil',
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 18,
                  children: [
                    _Field(
                      label: 'Not',
                      child: TextField(
                        controller: _title,
                        autofocus: _isNew,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppText.body(context, size: 17, weight: FontWeight.w500),
                        decoration: const InputDecoration(hintText: 'Ne hatırlatayım?'),
                      ),
                    ),
                    _Field(
                      label: 'Ne zaman',
                      child: Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: _ValueTile(
                              icon: Icons.calendar_today_outlined,
                              text: fmtDateShort(_dateTime),
                              onTap: _repeat == RepeatRule.none ? _pickDate : null,
                              dimmed: _repeat != RepeatRule.none,
                            ),
                          ),
                          Expanded(
                            child: _ValueTile(icon: Icons.schedule_rounded, text: fmtTime(_dateTime), onTap: _pickTime),
                          ),
                        ],
                      ),
                    ),
                    _Field(
                      label: 'Tekrar',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final r in RepeatRule.values)
                            AppChip(
                              label: r.label,
                              selected: _repeat == r,
                              onTap: () => setState(() => _repeat = r),
                            ),
                        ],
                      ),
                    ),
                    _Field(
                      label: 'Uyarı tipi',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          Row(
                            spacing: 8,
                            children: [
                              for (final t in AlertType.values)
                                Expanded(
                                  child: _TypeCard(
                                    icon: switch (t) {
                                      AlertType.notification => Icons.notifications_none_rounded,
                                      AlertType.alarm => Icons.alarm_rounded,
                                      AlertType.escalating => Icons.notifications_active_outlined,
                                    },
                                    title: t.label,
                                    selected: _alertType == t,
                                    onTap: () => setState(() => _alertType = t),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(_alertType.description, style: AppText.body(context, size: 12, color: c.mute)),
                          ),
                        ],
                      ),
                    ),
                    AppCard(
                      radius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onTap: _pickPreAlert,
                      child: SizedBox(
                        height: 50,
                        child: Row(
                          spacing: 10,
                          children: [
                            Icon(Icons.notifications_paused_outlined, size: 20, color: c.mute),
                            Expanded(child: Text('Önceden haber ver', style: AppText.body(context, size: 15, weight: FontWeight.w500))),
                            ValueTrailing(_preAlertLabel(_preAlertMin)),
                          ],
                        ),
                      ),
                    ),
                    if (_alertType.usesAlarm)
                      AppCard(
                        radius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onTap: _pickSound,
                        child: SizedBox(
                          height: 50,
                          child: Row(
                            spacing: 10,
                            children: [
                              Icon(Icons.volume_up_outlined, size: 20, color: c.mute),
                              Expanded(child: Text('Alarm sesi', style: AppText.body(context, size: 15, weight: FontWeight.w500))),
                              ValueTrailing(_sound.label),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: 'Kaydet',
                color: canSave ? c.amber : c.toggleOff,
                onTap: canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [SectionLabel(label), child],
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.icon, required this.text, required this.onTap, this.dimmed = false});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: onTap,
      child: SizedBox(
        height: 50,
        child: Row(
          spacing: 10,
          children: [
            Icon(icon, size: 20, color: c.mute),
            Expanded(
              child: Text(
                text,
                style: AppText.body(context, size: 15, weight: FontWeight.w600, color: dimmed ? c.mute : c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      color: selected ? c.amberSoft : c.card,
      borderColor: selected ? c.amber : c.line,
      borderWidth: selected ? 2 : 1,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Icon(icon, size: 24, color: selected ? c.amberDeep : c.mute),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(context, size: 14, weight: FontWeight.w600, color: selected ? c.amberDeep : c.ink),
              ),
            ],
          ),
          if (selected)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: c.amber, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
