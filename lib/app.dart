import 'dart:async';
import 'dart:io';

import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/android_hints.dart';
import 'features/home/widgets/add_water_sheet.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reminders/reminder_alarm_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/water_alarm/water_alarm_screen.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';
import 'services/reminder_scheduler.dart';
import 'services/water_scheduler.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SuApp extends ConsumerWidget {
  const SuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsProvider.select((s) => s.themeMode.mode),
    );
    final onboardingDone = ref.watch(
      settingsProvider.select((s) => s.onboardingDone),
    );
    return MaterialApp(
      title: 'Su Hatırlatıcı',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: onboardingDone
          ? const AppBootstrap(child: AppShell())
          : const OnboardingScreen(),
    );
  }
}

/// Açılışta izinleri ister, alarm ve bildirimleri yeniden kurar,
/// çalan alarmları ve bildirim dokunuşlarını ilgili ekrana yönlendirir.
class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap>
    with WidgetsBindingObserver {
  StreamSubscription<AlarmSet>? _ringSub;
  StreamSubscription<NotificationResponse>? _notifSub;
  StreamSubscription<AlarmUpdateEvent>? _kitSub;
  StreamSubscription<Uri?>? _widgetSub;
  final Set<int> _presented = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ringSub?.cancel();
    _notifSub?.cancel();
    _kitSub?.cancel();
    _widgetSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Arka planda uzun kalınca gün değişmiş, widget'tan kayıt eklenmiş veya
    // süresi dolan hatırlatıcılar olabilir.
    ref.read(waterProvider.notifier).rescheduleReminders();
    ref.invalidate(remindersProvider);
  }

  Future<void> _start() async {
    final notifications = ref.read(notificationServiceProvider);
    final settings = ref.read(settingsProvider);
    _ringSub = ref.read(alarmServiceProvider).ringing.listen(_onRinging);
    _notifSub = notifications.responses.listen(_onNotification);

    await notifications.requestPermissions();
    final widgets = ref.read(widgetServiceProvider);
    await widgets.init();
    _widgetSub = widgets.clicks.listen(_onWidgetClick);
    if (Platform.isIOS) {
      await ref
          .read(alarmServiceProvider)
          .configureSystemAlarm(settings.useSystemAlarm);
      if (await ref.read(alarmKitServiceProvider).isSupported()) {
        _kitSub = ref
            .read(alarmKitServiceProvider)
            .updates
            .listen(_onKitUpdate);
      }
    }

    await ref.read(remindersProvider.notifier).syncAll();
    await ref.read(waterProvider.notifier).rescheduleReminders();

    final launch = notifications.launchResponse;
    if (launch != null) {
      notifications.launchResponse = null;
      await _onNotification(launch);
    }
    try {
      _onWidgetClick(await widgets.initialLaunchUri());
    } catch (_) {}

    if (settings.alertType.usesAlarm) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await showFullScreenAlarmHint(
          ctx,
          prefs: ref.read(sharedPreferencesProvider),
          notifications: notifications,
        );
      }
    }
  }

  void _onWidgetClick(Uri? uri) {
    if (uri?.host != 'add') return;
    ref.read(tabIndexProvider.notifier).set(0);
    final ctx = navigatorKey.currentContext;
    if (ctx != null && mounted) showAddWaterSheet(ctx);
  }

  void _onRinging(AlarmSet set) {
    final ids = set.alarms.map((a) => a.id).toSet();
    _presented.removeWhere((id) => !ids.contains(id));
    for (final alarm in set.alarms) {
      if (!_presented.add(alarm.id)) continue;
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      if (WaterScheduler.isWaterId(alarm.id)) {
        nav.push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => WaterAlarmScreen(alarmId: alarm.id),
          ),
        );
      } else if (ReminderScheduler.isReminderAlarmId(alarm.id)) {
        nav.push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => ReminderAlarmScreen(
              alarmId: alarm.id,
              reminderId: ReminderScheduler.reminderIdFromAlarmId(alarm.id),
            ),
          ),
        );
      }
    }
  }

  bool _kitSheetOpen = false;

  /// AlarmKit sistem alarmı kullanıcı tarafından durdurulunca: su alarmıysa ekleme sayfasını aç.
  /// Bizim iptal ettiğimiz (zamanı gelmemiş) alarmların olayları yok sayılır.
  Future<void> _onKitUpdate(AlarmUpdateEvent event) async {
    if (event.kind != AlarmUpdateKind.removed) return;
    final alarms = ref.read(alarmServiceProvider);
    final info = alarms.kitInfo(event.alarmId);
    if (info == null) return;
    if (DateTime.now().isBefore(info.at.subtract(const Duration(seconds: 5))))
      return;
    await alarms.forgetKit(event.alarmId);
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted || _kitSheetOpen) return;
    final localId = info.id;
    if (WaterScheduler.isWaterId(localId)) {
      _kitSheetOpen = true;
      try {
        await showAddWaterSheet(ctx);
      } finally {
        _kitSheetOpen = false;
      }
    } else if (ReminderScheduler.isReminderAlarmId(localId)) {
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ReminderAlarmScreen(
            reminderId: ReminderScheduler.reminderIdFromAlarmId(localId),
          ),
        ),
      );
    }
  }

  Future<void> _onNotification(NotificationResponse response) async {
    final payload = response.payload ?? '';
    if (payload == WaterScheduler.payload) {
      if (response.actionId == NotificationService.drankActionId) {
        final glass = ref.read(settingsProvider).defaultGlassMl;
        await ref.read(waterProvider.notifier).addEntry(glass);
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('$glass ml eklendi')),
        );
      } else {
        ref.read(tabIndexProvider.notifier).set(0);
        final ctx = navigatorKey.currentContext;
        if (ctx != null && mounted) showAddWaterSheet(ctx);
      }
      return;
    }
    final reminderId = ReminderScheduler.reminderIdFromPayload(payload);
    if (reminderId != null) {
      ref.read(tabIndexProvider.notifier).set(1);
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ReminderAlarmScreen(reminderId: reminderId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
