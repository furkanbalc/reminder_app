import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 196,
    this.strokeWidth = 16,
  });

  /// 0..1 (üstü kırpılır)
  final double progress;
  final Widget child;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(
            progress: value,
            track: c.ringTrack,
            color: c.water,
            strokeWidth: strokeWidth,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color track;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(strokeWidth / 2);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(r, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
