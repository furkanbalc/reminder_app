import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/water_entry.dart';
import '../../../data/models/water_settings.dart';
import '../../../providers/providers.dart';
import 'add_water_sheet.dart';
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
  int _weekOffset = 0;
  int _monthOffset = 0;

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
            1 => _period(context, isWeek: true),
            _ => _period(context, isWeek: false),
          },
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    String title,
    int totalMl,
    String rightLabel,
    String rightValue, {
    VoidCallback? onPrev,
    VoidCallback? onNext,
  }) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Row(
                spacing: 2,
                children: [
                  if (onPrev != null || onNext != null) ...[
                    _navButton(context, Icons.chevron_left_rounded, onPrev),
                    Text(
                      title,
                      style: AppText.body(
                        context,
                        size: 13,
                        weight: FontWeight.w500,
                        color: c.mute,
                      ),
                    ),
                    _navButton(context, Icons.chevron_right_rounded, onNext),
                  ] else
                    Text(
                      title,
                      style: AppText.body(
                        context,
                        size: 13,
                        weight: FontWeight.w500,
                        color: c.mute,
                      ),
                    ),
                ],
              ),
              Text(
                '${fmtLiters(totalMl)} L',
                style: AppText.display(context, size: 24),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 2,
          children: [
            Text(
              rightLabel,
              style: AppText.body(
                context,
                size: 13,
                weight: FontWeight.w500,
                color: c.mute,
              ),
            ),
            Text(
              rightValue,
              style: AppText.display(
                context,
                size: 17,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _navButton(BuildContext context, IconData icon, VoidCallback? onTap) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 20, color: onTap == null ? c.line : c.mute),
      ),
    );
  }

  String _avg(int totalMl, int days) =>
      days == 0 ? '0.0 L' : '${fmtLiters(totalMl ~/ days)} L';

  Widget _daily(BuildContext context) {
    final c = context.colors;
    final s = widget.state;
    final pct = widget.settings.goalMl == 0
        ? 0
        : (s.todayTotalMl * 100 / widget.settings.goalMl).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _header(context, 'Bugün', s.todayTotalMl, 'Hedefin', '%$pct'),
        if (s.streakDays > 0)
          Row(
            spacing: 6,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: c.amber,
              ),
              Text(
                s.streakDays == 1
                    ? 'Seri başladı: 1 gün'
                    : 'Seri: ${s.streakDays} gün üst üste hedef',
                style: AppText.body(
                  context,
                  size: 13,
                  weight: FontWeight.w600,
                  color: c.amberDeep,
                ),
              ),
            ],
          ),
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
            children: [for (final e in s.todayEntries) _entryRow(context, e)],
          ),
      ],
    );
  }

  Widget _entryRow(BuildContext context, WaterEntry e) {
    final c = context.colors;
    return InkWell(
      onTap: () => showAddWaterSheet(context, edit: e),
      child: Container(
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
              child: Text(
                fmtTime(e.timestamp),
                style: AppText.body(context, size: 14, weight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                '${e.amountMl} ml',
                style: AppText.body(context, size: 14, color: c.mute),
              ),
            ),
            Icon(Icons.edit_outlined, size: 16, color: c.line),
            IconButton(
              onPressed: () =>
                  ref.read(waterProvider.notifier).deleteEntry(e.id),
              icon: Icon(Icons.close_rounded, size: 18, color: c.mute),
              visualDensity: VisualDensity.compact,
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _period(BuildContext context, {required bool isWeek}) {
    final offset = isWeek ? _weekOffset : _monthOffset;
    void setOffset(int v) =>
        setState(() => isWeek ? _weekOffset = v : _monthOffset = v);

    if (offset == 0) {
      final s = widget.state;
      return _periodBody(
        context,
        isWeek: isWeek,
        days: isWeek ? s.week : s.month,
        title: isWeek ? 'Bu hafta' : _monthName(DateTime.now()),
        onPrev: () => setOffset(offset - 1),
        onNext: null,
      );
    }
    final async = ref.watch(
      periodStatsProvider(PeriodKey(isWeek: isWeek, offset: offset)),
    );
    final stats = async.value;
    if (stats == null) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return _periodBody(
      context,
      isWeek: isWeek,
      days: stats.days,
      title: isWeek ? _weekLabel(stats.start) : _monthName(stats.start),
      onPrev: () => setOffset(offset - 1),
      onNext: () => setOffset(offset + 1),
    );
  }

  String _monthName(DateTime d) {
    final name = DateFormat('MMMM', 'tr_TR').format(d);
    final label = name[0].toUpperCase() + name.substring(1);
    return d.year == DateTime.now().year ? label : '$label ${d.year}';
  }

  String _weekLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    final f = DateFormat('d MMM', 'tr_TR');
    return '${start.day}${start.month == end.month ? '' : ' ${DateFormat('MMM', 'tr_TR').format(start)}'} – ${f.format(end)}';
  }

  Widget _periodBody(
    BuildContext context, {
    required bool isWeek,
    required List<DayTotal> days,
    required String title,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
  }) {
    const labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final now = DateTime.now();
    final total = days
        .where((d) => d.totalMl >= 0)
        .fold(0, (a, d) => a + d.totalMl);
    final elapsed = days.where((d) => d.totalMl >= 0).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        _header(
          context,
          title,
          total,
          'Günlük ortalama',
          _avg(total, elapsed),
          onPrev: onPrev,
          onNext: onNext,
        ),
        WaterBarChart(
          goalMl: widget.settings.goalMl,
          dense: !isWeek,
          bars: [
            for (var i = 0; i < days.length; i++)
              BarData(
                label: isWeek ? labels[i] : '${days[i].day.day}',
                valueMl: days[i].totalMl < 0 ? null : days[i].totalMl,
                isToday: isSameDay(days[i].day, now),
                showLabel:
                    isWeek || days[i].day.day == 1 || days[i].day.day % 5 == 0,
              ),
          ],
        ),
      ],
    );
  }
}
