import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../providers/providers.dart';
import 'add_water_sheet.dart';

/// Grafikte bir güne dokununca: o günün toplamı ve kayıtları.
Future<void> showDayDetailSheet(BuildContext context, DateTime day) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DayDetailSheet(day: startOfDay(day)),
  );
}

class DayDetailSheet extends ConsumerWidget {
  const DayDetailSheet({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final goalMl = ref.watch(settingsProvider.select((s) => s.goalMl));
    final entries = ref.watch(dayEntriesProvider(day)).value;
    final total = entries?.fold<int>(0, (a, e) => a + e.amountMl) ?? 0;
    final pct = goalMl == 0 ? 0 : (total * 100 / goalMl).round();
    final isToday = isSameDay(day, DateTime.now());
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        10,
        24,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            SheetHeader(title: isToday ? 'Bugün' : fmtDayHeader(day)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        'Toplam',
                        style: AppText.body(
                          context,
                          size: 13,
                          weight: FontWeight.w500,
                          color: c.mute,
                        ),
                      ),
                      Text(
                        '${fmtLiters(total)} L',
                        style: AppText.display(context, size: 28),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 2,
                  children: [
                    Text(
                      'Hedef ${fmtLiters(goalMl)} L',
                      style: AppText.body(
                        context,
                        size: 13,
                        weight: FontWeight.w500,
                        color: c.mute,
                      ),
                    ),
                    Text(
                      '%$pct',
                      style: AppText.display(
                        context,
                        size: 20,
                        weight: FontWeight.w600,
                        color: total >= goalMl ? c.water : c.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (entries == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Bu günde su kaydı yok',
                    style: AppText.body(context, size: 14, color: c.mute),
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: GroupedCard(
                    children: [
                      for (var i = 0; i < entries.length; i++)
                        SettingsRow(
                          label: fmtTime(entries[i].timestamp),
                          last: i == entries.length - 1,
                          leading: Icon(
                            Icons.water_drop_outlined,
                            size: 18,
                            color: c.water,
                          ),
                          onTap: () =>
                              showAddWaterSheet(context, edit: entries[i]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Text(
                                '${entries[i].amountMl} ml',
                                style: AppText.body(
                                  context,
                                  size: 15,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                onPressed: () => ref
                                    .read(waterProvider.notifier)
                                    .deleteEntry(entries[i].id),
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: c.mute,
                                ),
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Sil',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Text(
              'Bir kayda dokunarak düzenleyebilirsin.',
              style: AppText.body(context, size: 12, color: c.mute),
            ),
          ],
        ),
      ),
    );
  }
}
