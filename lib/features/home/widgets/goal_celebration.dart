import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/widgets.dart';
import 'progress_ring.dart';

/// Günlük hedefe ulaşınca gösterilen kutlama.
Future<void> showGoalCelebration(
  BuildContext context, {
  required int goalMl,
  required int streakDays,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final c = ctx.colors;
      final streakText = streakDays >= 2
          ? 'Üst üste $streakDays gün. Böyle devam!'
          : 'Yarın da aynı tempoyla devam et.';
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          28,
          24,
          24 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 18,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _Drops(),
                  ProgressRing(
                    progress: 1,
                    size: 160,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (_, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: c.water,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              spacing: 6,
              children: [
                Text('Hedefe ulaştın!', style: AppText.display(ctx, size: 26)),
                Text(
                  'Bugün ${fmtLiters(goalMl)} L hedefini tamamladın. $streakText',
                  textAlign: TextAlign.center,
                  style: AppText.body(ctx, size: 15, color: c.mute),
                ),
              ],
            ),
            PrimaryButton(
              label: 'Harika',
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    },
  );
}

/// Halkanın çevresinde yükselen küçük damlalar.
class _Drops extends StatefulWidget {
  const _Drops();

  @override
  State<_Drops> createState() => _DropsState();
}

class _DropsState extends State<_Drops> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.water;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        size: const Size(200, 200),
        painter: _DropsPainter(_c.value, color),
      ),
    );
  }
}

class _DropsPainter extends CustomPainter {
  _DropsPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rnd = math.Random(7);
    for (var i = 0; i < 14; i++) {
      final angle = (i / 14) * math.pi * 2 + rnd.nextDouble() * 0.3;
      final eased = Curves.easeOut.transform(t);
      final dist = 70 + eased * (30 + rnd.nextDouble() * 40);
      final p = center + Offset(math.cos(angle), math.sin(angle)) * dist;
      final r = 3 + rnd.nextDouble() * 3;
      final paint = Paint()
        ..color = color.withValues(alpha: (1 - t).clamp(0, 1) * 0.9);
      canvas.drawCircle(p, r * (0.6 + eased * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(_DropsPainter old) => old.t != t;
}
