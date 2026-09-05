import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';

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

Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial, {String? help}) {
  return showTimePicker(context: context, initialTime: initial, helpText: help);
}
