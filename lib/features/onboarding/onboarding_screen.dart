import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/water_settings.dart';
import '../../providers/providers.dart';
import '../home/widgets/progress_ring.dart';
import '../settings/pickers.dart';

/// İlk açılış: hedef, saatler, bardak, uyarı tipi ve izinler.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  late WaterSettings _s;
  bool _goalEdited = false;
  bool _busy = false;

  static const _pageCount = 5;

  @override
  void initState() {
    super.initState();
    _s = ref.read(settingsProvider).copyWith(goalMl: WaterSettings.suggestedGoal(70), weightKg: 70);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  void _back() {
    if (_page > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    final notifications = ref.read(notificationServiceProvider);
    await notifications.requestPermissions();
    if (_s.alertType.usesAlarm && Platform.isIOS && _s.useSystemAlarm) {
      final kit = ref.read(alarmKitServiceProvider);
      if (await kit.isSupported()) {
        final ok = await kit.requestAuthorization();
        await ref.read(alarmServiceProvider).configureSystemAlarm(ok);
      }
    }
    // onboardingDone ile ana ekrana geçilir; hatırlatmalar orada kurulur.
    await ref.read(settingsProvider.notifier).saveQuiet(_s.copyWith(onboardingDone: true));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: _page > 0
                        ? IconButton(onPressed: _back, icon: const Icon(Icons.chevron_left_rounded, size: 28))
                        : null,
                  ),
                  const Spacer(),
                  Row(
                    spacing: 6,
                    children: [
                      for (var i = 0; i < _pageCount; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? c.water : c.line,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _welcome(context),
                  _goal(context),
                  _hours(context),
                  _alert(context),
                  _permissions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frame(BuildContext context, {required String title, required String text, required Widget body, required Widget action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: [
                  const SizedBox(height: 8),
                  Text(title, style: AppText.display(context, size: 30)),
                  Text(text, style: AppText.body(context, size: 15, color: context.colors.mute)),
                  body,
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          action,
        ],
      ),
    );
  }

  Widget _welcome(BuildContext context) {
    final c = context.colors;
    return _frame(
      context,
      title: 'Su içmeyi unutma',
      text: 'Gün boyu düzenli hatırlatır, ne kadar içtiğini takip eder. İstersen unutmaman gereken notlarını da zamanında haber verir.',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: ProgressRing(
            progress: 0.62,
            child: Icon(Icons.water_drop_rounded, size: 64, color: c.water),
          ),
        ),
      ),
      action: PrimaryButton(label: 'Başla', onTap: _next),
    );
  }

  Widget _goal(BuildContext context) {
    final c = context.colors;
    final suggested = WaterSettings.suggestedGoal(_s.weightKg);
    return _frame(
      context,
      title: 'Günlük hedefin',
      text: 'Kilona göre bir öneri hazırladık. İstersen hedefi elle değiştirebilirsin.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Kilo', style: AppText.body(context, size: 15, weight: FontWeight.w500))),
                    Text('${_s.weightKg} kg', style: AppText.display(context, size: 18)),
                  ],
                ),
                Slider(
                  value: _s.weightKg.toDouble(),
                  min: 40,
                  max: 150,
                  divisions: 110,
                  onChanged: (v) => setState(() {
                    _s = _s.copyWith(weightKg: v.round());
                    if (!_goalEdited) _s = _s.copyWith(goalMl: WaterSettings.suggestedGoal(v.round()));
                  }),
                ),
              ],
            ),
          ),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text('Günlük hedef', style: AppText.body(context, size: 15, weight: FontWeight.w500)),
                      Text(
                        _goalEdited ? 'Öneri: ${fmtLiters(suggested)} L' : 'Kilona göre öneri',
                        style: AppText.body(context, size: 12, color: c.mute),
                      ),
                    ],
                  ),
                ),
                Row(
                  spacing: 10,
                  children: [
                    CircleIconButton(
                      icon: Icons.remove_rounded,
                      size: 36,
                      onTap: _s.goalMl > 1000 ? () => setState(() { _goalEdited = true; _s = _s.copyWith(goalMl: _s.goalMl - 100); }) : null,
                    ),
                    SizedBox(width: 60, child: Text('${fmtLiters(_s.goalMl)} L', textAlign: TextAlign.center, style: AppText.display(context, size: 20))),
                    CircleIconButton(
                      icon: Icons.add_rounded,
                      size: 36,
                      color: c.waterSoft,
                      iconColor: c.waterDeep,
                      bordered: false,
                      onTap: _s.goalMl < 6000 ? () => setState(() { _goalEdited = true; _s = _s.copyWith(goalMl: _s.goalMl + 100); }) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      action: PrimaryButton(label: 'Devam', onTap: _next),
    );
  }

  Widget _hours(BuildContext context) {
    final c = context.colors;
    Future<void> pick(bool start) async {
      final current = start ? _s.activeStartMin : _s.activeEndMin;
      final t = await pickTime(context, TimeOfDay(hour: current ~/ 60, minute: current % 60),
          help: start ? 'Uyanma saati' : 'Yatma saati');
      if (t == null) return;
      final m = t.hour * 60 + t.minute;
      setState(() => _s = start ? _s.copyWith(activeStartMin: m) : _s.copyWith(activeEndMin: m));
    }

    return _frame(
      context,
      title: 'Saatler ve bardak',
      text: 'Hatırlatmalar yalnızca uyanık olduğun saatlerde gelir. Hızlı eklemede varsayılan bardağını seç.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          Row(
            spacing: 10,
            children: [
              Expanded(child: _tile(context, Icons.wb_sunny_outlined, 'Uyanma', fmtMinutesOfDay(_s.activeStartMin), () => pick(true))),
              Expanded(child: _tile(context, Icons.bedtime_outlined, 'Yatma', fmtMinutesOfDay(_s.activeEndMin), () => pick(false))),
            ],
          ),
          if (_s.activeEndMin <= _s.activeStartMin)
            Text('Yatma saati uyanma saatinden sonra olmalı', style: AppText.body(context, size: 12, color: c.danger)),
          const SectionLabel('Varsayılan bardak'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in WaterSettings.glassOptions)
                AppChip(
                  label: '$g ml',
                  selected: _s.defaultGlassMl == g,
                  selectedColor: c.waterDeep,
                  selectedTextColor: Colors.white,
                  onTap: () => setState(() => _s = _s.copyWith(defaultGlassMl: g)),
                ),
            ],
          ),
        ],
      ),
      action: PrimaryButton(label: 'Devam', onTap: _s.activeEndMin > _s.activeStartMin ? _next : null),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String value, VoidCallback onTap) {
    final c = context.colors;
    return AppCard(
      radius: 16,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Icon(icon, size: 22, color: c.mute),
          Text(label, style: AppText.body(context, size: 13, color: c.mute)),
          Text(value, style: AppText.display(context, size: 22)),
        ],
      ),
    );
  }

  Widget _alert(BuildContext context) {
    final c = context.colors;
    return _frame(
      context,
      title: 'Nasıl hatırlatalım?',
      text: 'Sonradan Ayarlar’dan değiştirebilirsin.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          for (final t in AlertType.values)
            AppCard(
              radius: 16,
              color: _s.alertType == t ? c.waterSoft : c.card,
              borderColor: _s.alertType == t ? c.water : c.line,
              borderWidth: _s.alertType == t ? 2 : 1,
              onTap: () => setState(() => _s = _s.copyWith(alertType: t)),
              child: Row(
                spacing: 14,
                children: [
                  Icon(
                    switch (t) {
                      AlertType.notification => Icons.notifications_none_rounded,
                      AlertType.alarm => Icons.alarm_rounded,
                      AlertType.escalating => Icons.notifications_active_outlined,
                    },
                    color: _s.alertType == t ? c.waterDeep : c.mute,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(t.label, style: AppText.body(context, size: 15, weight: FontWeight.w600, color: _s.alertType == t ? c.waterDeep : c.ink)),
                        Text(t.description, style: AppText.body(context, size: 12, color: c.mute)),
                      ],
                    ),
                  ),
                  if (_s.alertType == t) Icon(Icons.check_circle_rounded, color: c.water),
                ],
              ),
            ),
          if (_s.alertType.usesAlarm && Platform.isIOS)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                'iPhone’da alarmın uygulama kapalıyken de çalması için bir sonraki adımda alarm izni istenir.',
                style: AppText.body(context, size: 12, color: c.mute),
              ),
            ),
        ],
      ),
      action: PrimaryButton(label: 'Devam', onTap: _next),
    );
  }

  Widget _permissions(BuildContext context) {
    final c = context.colors;
    Widget item(IconData icon, String title, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.waterSoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: c.waterDeep),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: AppText.body(context, size: 15, weight: FontWeight.w600)),
                  Text(text, style: AppText.body(context, size: 13, color: c.mute)),
                ],
              ),
            ),
          ],
        );
    return _frame(
      context,
      title: 'Birkaç izin',
      text: 'Hatırlatmaların zamanında gelmesi için şunlara ihtiyacımız var:',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          item(Icons.notifications_none_rounded, 'Bildirimler', 'Su ve not hatırlatmaları bildirim olarak gelir.'),
          if (Platform.isAndroid)
            item(Icons.schedule_rounded, 'Tam zamanlı alarm', 'Hatırlatmaların dakikası dakikasına gelmesi için.'),
          if (Platform.isIOS && _s.alertType.usesAlarm)
            item(Icons.alarm_rounded, 'Sistem alarmı', 'Alarm, uygulama kapalıyken ve sessiz moddayken de çalar.'),
          item(Icons.lock_outline_rounded, 'Verilerin sende kalır', 'Tüm kayıtlar yalnızca bu cihazda saklanır.'),
        ],
      ),
      action: PrimaryButton(label: _busy ? 'Hazırlanıyor…' : 'İzin ver ve başla', onTap: _busy ? null : _finish),
    );
  }
}
