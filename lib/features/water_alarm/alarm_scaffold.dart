import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

/// Su ve hatırlatıcı alarm ekranlarının ortak tam ekran düzeni.
class AlarmScaffold extends StatefulWidget {
  const AlarmScaffold({
    super.key,
    required this.alarmId,
    required this.background,
    required this.label,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.caption,
    this.extra,
  });

  /// Çalan alarm kimliği; null ise sadece aksiyon ekranıdır.
  final int? alarmId;
  final Color background;
  final String label;
  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final Future<void> Function() onPrimary;
  final String secondaryLabel;
  final Future<void> Function() onSecondary;
  final String caption;
  final Widget? extra;

  @override
  State<AlarmScaffold> createState() => _AlarmScaffoldState();
}

class _AlarmScaffoldState extends State<AlarmScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  StreamSubscription<AlarmSet>? _sub;
  bool _busy = false;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    // Alarm başka bir yerden (bildirim, süre dolması) durursa ekranı kapat.
    final id = widget.alarmId;
    if (id != null) {
      _sub = Alarm.ringing.listen((set) {
        if (!_handled && mounted && !set.containsId(id)) {
          _handled = true;
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ripple.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    _handled = true;
    try {
      await action();
    } finally {
      // PopScope geri tuşunu engellediği için maybePop çalışmaz; doğrudan kapat.
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final white75 = Colors.white.withValues(alpha: 0.75);
    return PopScope(
      canPop: widget.alarmId == null,
      child: Scaffold(
        backgroundColor: widget.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  widget.label.toUpperCase(),
                  style: AppText.label(
                    context,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  TimeOfDay.now().format(context),
                  style: AppText.display(
                    context,
                    size: 64,
                    color: white,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 22,
                    children: [
                      _RippleIcon(controller: _ripple, icon: widget.icon),
                      Column(
                        spacing: 8,
                        children: [
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: AppText.display(
                              context,
                              size: 30,
                              weight: FontWeight.w600,
                              color: white,
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: AppText.body(
                              context,
                              size: 15,
                              weight: FontWeight.w500,
                              color: white75,
                            ),
                          ),
                        ],
                      ),
                      if (widget.extra != null) widget.extra!,
                    ],
                  ),
                ),
                PrimaryButton(
                  label: widget.primaryLabel,
                  icon: Icons.check_rounded,
                  color: white,
                  textColor: widget.background,
                  height: 64,
                  onTap: _busy ? null : () => _run(widget.onPrimary),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: widget.secondaryLabel,
                  outlined: true,
                  outlineColor: Colors.white.withValues(alpha: 0.3),
                  textColor: white,
                  height: 52,
                  onTap: _busy ? null : () => _run(widget.onSecondary),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.caption,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    context,
                    size: 12,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RippleIcon extends StatelessWidget {
  const _RippleIcon({required this.controller, required this.icon});

  final AnimationController controller;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            _ring(controller.value),
            _ring((controller.value + 0.5) % 1),
            Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double t) {
    final eased = Curves.easeOut.transform(t);
    final scale = 0.62 + 0.5 * eased;
    final opacity = (1 - eased) * 0.9;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3 * opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}
