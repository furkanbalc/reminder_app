import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/water_settings.dart';
import '../../../providers/providers.dart';
import 'bar_chart.dart';

class StatsCard extends ConsumerStatefulWidget {
  const StatsCard({super.key, required this.state, required this.settings});

  final WaterState state;
  final WaterSettings settings;

  @override
  ConsumerState<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends ConsumerState<StatsCard> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          SegmentedControl(
            items: const ['Günlük', 'Haftalık', 'Aylık'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          switch (_tab) {
            0 => _daily(context),
            1 => _weekly(context),
            _ => _monthly(context),
          },
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String title, int totalMl, String rightLabel, String rightValue) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(title, style: AppText.body(context, size: 13, weight: FontWeight.w500, color: c.mute)),
              Text('${fmtLiters(totalMl)} L', style: AppText.display(context, size: 24)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 2,
          children: [
            Text(rightLabel, style: AppText.body(context, size: 13, weight: FontWeight.w500, color: c.mute)),
            Text(rightValue, style: AppText.display(context, size: 17, weight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  String _avg(int totalMl, int days) => days == 0 ? '0.0 L' : '${fmtLiters(totalMl ~/ days)} L';

  Widget _daily(BuildContext context) {
    final c = context.colors;
    final s = widget.state;
    final pct = widget.settings.goalMl == 0 ? 0 : (s.todayTotalMl * 100 / widget.settings.goalMl).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _header(context, 'Bugün', s.todayTotalMl, 'Hedefin', '%$pct'),
        if (s.todayEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Bugün henüz su kaydı yok',
                style: AppText.body(context, size: 14, color: c.mute),
              ),
            ),
          )
        else
          Column(
            children: [
              for (final e in s.todayEntries)
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      Icon(Icons.water_drop_outlined, size: 18, color: c.water),
                      SizedBox(
                        width: 48,
                        child: Text(fmtTime(e.timestamp), style: AppText.body(context, size: 14, weight: FontWeight.w600)),
                      ),
                      Expanded(child: Text('${e.amountMl} ml', style: AppText.body(context, size: 14, color: c.mute))),
                      IconButton(
                        onPressed: () => ref.read(waterProvider.notifier).deleteEntry(e.id),
                        icon: Icon(Icons.close_rounded, size: 18, color: c.mute),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Sil',
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _weekly(BuildContext context) {
    final s = widget.state;
    const labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        _header(context, 'Bu hafta', s.weekTotalMl, 'Günlük ortalama', _avg(s.weekTotalMl, s.weekDaysElapsed)),
        WaterBarChart(
          goalMl: widget.settings.goalMl,
          bars: [
            for (var i = 0; i < s.week.length; i++)
              BarData(
                label: labels[i],
                valueMl: s.week[i].totalMl < 0 ? null : s.week[i].totalMl,
                isToday: isSameDay(s.week[i].day, now),
              ),
          ],
        ),
      ],
    );
  }

  Widget _monthly(BuildContext context) {
    final s = widget.state;
    final now = DateTime.now();
    final monthName = DateFormat('MMMM', 'tr_TR').format(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        _header(context, monthName, s.monthTotalMl, 'Günlük ortalama', _avg(s.monthTotalMl, s.monthDaysElapsed)),
        WaterBarChart(
          goalMl: widget.settings.goalMl,
          dense: true,
          bars: [
            for (final d in s.month)
              BarData(
                label: '${d.day.day}',
                valueMl: d.totalMl < 0 ? null : d.totalMl,
                isToday: isSameDay(d.day, now),
                showLabel: d.day.day == 1 || d.day.day % 5 == 0,
              ),
          ],
        ),
      ],
    );
  }
}
