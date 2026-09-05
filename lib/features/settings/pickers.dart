import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';

class PickerOption<T> {
  const PickerOption(this.value, this.label, {this.subtitle});
  final T value;
  final String label;
  final String? subtitle;
}

/// Tek seçimli alt sayfa. Seçim yapılmazsa null döner.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<PickerOption<T>> options,
  required T selected,
  Color? accent,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final c = ctx.colors;
      final color = accent ?? c.water;
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 10, 24, 16 + MediaQuery.paddingOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            SheetHeader(title: title),
            GroupedCard(
              children: [
                for (var i = 0; i < options.length; i++)
                  SettingsRow(
                    label: options[i].label,
                    last: i == options.length - 1,
                    onTap: () => Navigator.of(ctx).pop(options[i].value),
                    trailing: options[i].value == selected
                        ? Icon(Icons.check_rounded, color: color, size: 22)
                        : const SizedBox(width: 22),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// Ön dinlemeli alarm sesi seçici.
Future<AlarmSound?> showSoundPicker(BuildContext context, {required AlarmSound selected, Color? accent}) {
  return showModalBottomSheet<AlarmSound>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SoundPickerSheet(selected: selected, accent: accent),
  );
}

class _SoundPickerSheet extends StatefulWidget {
  const _SoundPickerSheet({required this.selected, this.accent});

  final AlarmSound selected;
  final Color? accent;

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  final AudioPlayer _player = AudioPlayer();
  AlarmSound? _playing;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((st) {
      if (st.processingState == ProcessingState.completed && mounted) setState(() => _playing = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _preview(AlarmSound s) async {
    if (_playing == s) {
      await _player.stop();
      setState(() => _playing = null);
      return;
    }
    setState(() => _playing = s);
    await _player.setAsset(s.assetPath);
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = widget.accent ?? c.water;
    final sounds = AlarmSound.values;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 16 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          const SheetHeader(title: 'Alarm sesi'),
          GroupedCard(
            children: [
              for (var i = 0; i < sounds.length; i++)
                SettingsRow(
                  label: sounds[i].label,
                  last: i == sounds.length - 1,
                  onTap: () => Navigator.of(context).pop(sounds[i]),
                  leading: CircleIconButton(
                    icon: _playing == sounds[i] ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 34,
                    color: c.seg,
                    bordered: false,
                    iconColor: c.ink,
                    onTap: () => _preview(sounds[i]),
                  ),
                  trailing: sounds[i] == widget.selected
                      ? Icon(Icons.check_rounded, color: color, size: 22)
                      : const SizedBox(width: 22),
                ),
            ],
          ),
          Text('Çalmak için oynat, seçmek için satıra dokun.', style: AppText.body(context, size: 12, color: c.mute)),
        ],
      ),
    );
  }
}

Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial, {String? help}) {
  return showTimePicker(context: context, initialTime: initial, helpText: help);
}
