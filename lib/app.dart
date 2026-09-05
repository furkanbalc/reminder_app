import 'dart:async';

import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/home/widgets/add_water_sheet.dart';
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
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode.mode));
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
      home: const AppBootstrap(child: AppShell()),
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

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  StreamSubscription<AlarmSet>? _ringSub;
  StreamSubscription<NotificationResponse>? _notifSub;
  final Set<int> _presented = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _ringSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final notifications = ref.read(notificationServiceProvider);
    _ringSub = ref.read(alarmServiceProvider).ringing.listen(_onRinging);
    _notifSub = notifications.responses.listen(_onNotification);

    await notifications.requestPermissions();

    await ref.read(remindersProvider.notifier).syncAll();
    final water = await ref.read(waterProvider.future);
    await ref
        .read(waterSchedulerProvider)
        .reschedule(s: ref.read(settingsProvider), todayTotalMl: water.todayTotalMl);

    final launch = notifications.launchResponse;
    if (launch != null) {
      notifications.launchResponse = null;
      await _onNotification(launch);
    }
  }

  void _onRinging(AlarmSet set) {
    final ids = set.alarms.map((a) => a.id).toSet();
    _presented.removeWhere((id) => !ids.contains(id));
    for (final alarm in set.alarms) {
      if (!_presented.add(alarm.id)) continue;
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      if (WaterScheduler.isWaterId(alarm.id)) {
        nav.push(MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => WaterAlarmScreen(alarmId: alarm.id),
        ));
      } else if (ReminderScheduler.isReminderAlarmId(alarm.id)) {
        nav.push(MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ReminderAlarmScreen(
            alarmId: alarm.id,
            reminderId: ReminderScheduler.reminderIdFromAlarmId(alarm.id),
          ),
        ));
      }
    }
  }

  Future<void> _onNotification(NotificationResponse response) async {
    final payload = response.payload ?? '';
    if (payload == WaterScheduler.payload) {
      if (response.actionId == NotificationService.drankActionId) {
        final glass = ref.read(settingsProvider).defaultGlassMl;
        await ref.read(waterProvider.notifier).addEntry(glass);
        scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('$glass ml eklendi')));
      } else {
        ref.read(tabIndexProvider.notifier).set(0);
        final ctx = navigatorKey.currentContext;
        if (ctx != null && mounted) showAddWaterSheet(ctx);
      }
    } else if (ReminderScheduler.reminderIdFromPayload(payload) != null) {
      ref.read(tabIndexProvider.notifier).set(1);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
