import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';

class BarData {
  const BarData({required this.label, required this.valueMl, this.isToday = false, this.showLabel = true});

  final String label;
  /// null: gelecek gün
  final int? valueMl;
  final bool isToday;
  final bool showLabel;
}

class WaterBarChart extends StatelessWidget {
  const WaterBarChart({
    super.key,
    required this.bars,
    required this.goalMl,
    this.dense = false,
    this.height = 122,
  });

  final List<BarData> bars;
  final int goalMl;
  final bool dense;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const labelHeight = 21.0;
    final barArea = height - labelHeight;
    final maxValue = bars.fold<int>(0, (m, b) => math.max(m, b.valueMl ?? 0));
    final scaleMax = math.max(goalMl * 1.2, maxValue * 1.05);
    final goalTop = barArea * (1 - goalMl / scaleMax);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: goalTop,
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, 1.5),
                    painter: _DashedLinePainter(color: c.waterDash),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'hedef ${fmtLiters(goalMl)}',
                    style: AppText.body(context, size: 10, weight: FontWeight.w600, color: c.water),
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: dense ? 3 : 8,
            children: [
              for (final b in bars)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _bar(b, barArea, scaleMax, c),
                      SizedBox(
                        height: labelHeight,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: b.showLabel
                              ? Text(
                                  b.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                  softWrap: false,
                                  style: AppText.body(
                                    context,
                                    size: dense ? 10 : 11,
                                    weight: b.isToday ? FontWeight.w700 : FontWeight.w500,
                                    color: b.isToday ? c.ink : c.mute,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(BarData b, double barArea, double scaleMax, AppColors c) {
    final v = b.valueMl;
    if (v == null) {
      return Container(
        height: 6,
        constraints: BoxConstraints(maxWidth: dense ? 12 : 26),
        decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(3)),
      );
    }
    final h = math.max(4.0, barArea * (v / scaleMax));
    final color = b.isToday ? c.waterDeep : (v >= goalMl ? c.water : c.waterLight);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: h),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => Container(
        height: value,
        constraints: BoxConstraints(maxWidth: dense ? 12 : 26),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(dense ? 4 : 7),
            bottom: Radius.circular(dense ? 2 : 3),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + dash, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
