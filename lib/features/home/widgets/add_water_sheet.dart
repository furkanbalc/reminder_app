import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../providers/providers.dart';

Future<void> showAddWaterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const AddWaterSheet(),
  );
}

class AddWaterSheet extends ConsumerStatefulWidget {
  const AddWaterSheet({super.key});

  @override
  ConsumerState<AddWaterSheet> createState() => _AddWaterSheetState();
}

class _AddWaterSheetState extends ConsumerState<AddWaterSheet> {
  static const _presets = [200, 250, 330, 500];
  late int _amount;
  DateTime _time = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amount = ref.read(settingsProvider).defaultGlassMl;
  }

  void _step(int delta) => setState(() => _amount = (_amount + delta).clamp(50, 3000));

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time),
      helpText: 'Ne zaman içtin?',
    );
    if (picked == null) return;
    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    if (t.isAfter(now)) t = now;
    setState(() => _time = t);
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final notifier = ref.read(waterProvider.notifier);
    final entry = await notifier.addEntry(_amount, at: _time);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$_amount ml eklendi'),
        persist: false,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: 'Geri al', onPressed: () => notifier.deleteEntry(entry.id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isNow = DateTime.now().difference(_time).inMinutes < 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 20,
        children: [
          const SheetHeader(title: 'Su Ekle'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 24,
            children: [
              CircleIconButton(icon: Icons.remove_rounded, size: 56, onTap: () => _step(-50)),
              SizedBox(
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: 6,
                  children: [
                    Text('$_amount', style: AppText.display(context, size: 56, height: 1, letterSpacing: -1)),
                    Text('ml', style: AppText.display(context, size: 20, weight: FontWeight.w600, color: c.mute)),
                  ],
                ),
              ),
              CircleIconButton(
                icon: Icons.add_rounded,
                size: 56,
                color: c.waterSoft,
                iconColor: c.waterDeep,
                bordered: false,
                onTap: () => _step(50),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              for (final p in _presets)
                AppChip(
                  label: '$p ml',
                  selected: _amount == p,
                  selectedColor: c.waterDeep,
                  selectedTextColor: Colors.white,
                  onTap: () => setState(() => _amount = p),
                ),
            ],
          ),
          AppCard(
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: _pickTime,
            child: SizedBox(
              height: 50,
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 20, color: c.mute),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Zaman', style: AppText.body(context, size: 15, weight: FontWeight.w500))),
                  ValueTrailing(isNow ? 'Şimdi · ${fmtTime(_time)}' : fmtTime(_time)),
                ],
              ),
            ),
          ),
          PrimaryButton(label: '$_amount ml Ekle', onTap: _submit),
        ],
      ),
    );
  }
}
