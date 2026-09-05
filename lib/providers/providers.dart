import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../core/utils/format.dart';
import '../data/models/enums.dart';
import '../data/models/reminder.dart';
import '../data/models/water_entry.dart';
import '../data/models/water_settings.dart';
import '../data/repositories/reminder_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/water_repository.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_scheduler.dart';
import '../services/water_scheduler.dart';

// ---- main() içinde override edilen altyapı sağlayıcıları ----
final sharedPreferencesProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError('main içinde override edilir'));
final databaseProvider = Provider<Database>((_) => throw UnimplementedError('main içinde override edilir'));
final notificationServiceProvider =
    Provider<NotificationService>((_) => throw UnimplementedError('main içinde override edilir'));

final alarmServiceProvider = Provider<AlarmService>((_) => AlarmService());

final waterRepositoryProvider = Provider((ref) => WaterRepository(ref.watch(databaseProvider)));
final reminderRepositoryProvider = Provider((ref) => ReminderRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)));

final waterSchedulerProvider = Provider(
  (ref) => WaterScheduler(ref.watch(notificationServiceProvider), ref.watch(alarmServiceProvider)),
);
final reminderSchedulerProvider = Provider(
  (ref) => ReminderScheduler(ref.watch(notificationServiceProvider), ref.watch(alarmServiceProvider)),
);

// ---- Sekme ----
final tabIndexProvider = NotifierProvider<TabIndexNotifier, int>(TabIndexNotifier.new);

class TabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

// ---- Ayarlar ----
final settingsProvider = NotifierProvider<SettingsNotifier, WaterSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<WaterSettings> {
  @override
  WaterSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> save(WaterSettings s) async {
    state = s;
    await ref.read(settingsRepositoryProvider).save(s);
    final total = ref.read(waterProvider).value?.todayTotalMl ?? 0;
    await ref.read(waterSchedulerProvider).reschedule(s: s, todayTotalMl: total);
  }
}

// ---- Su ----
class WaterState {
  const WaterState({
    required this.todayTotalMl,
    required this.todayEntries,
    required this.week,
    required this.month,
    required this.nextReminder,
  });

  final int todayTotalMl;
  final List<WaterEntry> todayEntries;
  /// Pazartesiden pazara 7 gün. Gelecek günler için totalMl = -1.
  final List<DayTotal> week;
  /// Ayın her günü. Gelecek günler için totalMl = -1.
  final List<DayTotal> month;
  final DateTime? nextReminder;

  int get weekTotalMl => week.where((d) => d.totalMl >= 0).fold(0, (a, d) => a + d.totalMl);
  int get monthTotalMl => month.where((d) => d.totalMl >= 0).fold(0, (a, d) => a + d.totalMl);
  int get weekDaysElapsed => week.where((d) => d.totalMl >= 0).length;
  int get monthDaysElapsed => month.where((d) => d.totalMl >= 0).length;
}

final waterProvider = AsyncNotifierProvider<WaterNotifier, WaterState>(WaterNotifier.new);

class WaterNotifier extends AsyncNotifier<WaterState> {
  @override
  Future<WaterState> build() async {
    final settings = ref.watch(settingsProvider);
    return _load(settings);
  }

  Future<WaterState> _load(WaterSettings s) async {
    final repo = ref.read(waterRepositoryProvider);
    final now = DateTime.now();
    final today = startOfDay(now);
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final rangeStart = weekStart.isBefore(monthStart) ? weekStart : monthStart;

    final entries = await repo.entriesBetween(rangeStart, tomorrow);
    final totals = <DateTime, int>{};
    for (final e in entries) {
      final d = startOfDay(e.timestamp);
      totals[d] = (totals[d] ?? 0) + e.amountMl;
    }

    int totalFor(DateTime d) => d.isAfter(today) ? -1 : (totals[d] ?? 0);

    final week = [
      for (var i = 0; i < 7; i++)
        DayTotal(day: weekStart.add(Duration(days: i)), totalMl: totalFor(weekStart.add(Duration(days: i)))),
    ];
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final month = [
      for (var i = 0; i < daysInMonth; i++)
        DayTotal(day: monthStart.add(Duration(days: i)), totalMl: totalFor(monthStart.add(Duration(days: i)))),
    ];
    final todayEntries = entries.where((e) => isSameDay(e.timestamp, now)).toList().reversed.toList();
    final todayTotal = totals[today] ?? 0;
    final next = ref.read(waterSchedulerProvider).next(s, now, goalReachedToday: todayTotal >= s.goalMl);

    return WaterState(
      todayTotalMl: todayTotal,
      todayEntries: todayEntries,
      week: week,
      month: month,
      nextReminder: next,
    );
  }

  Future<WaterEntry> addEntry(int amountMl, {DateTime? at}) async {
    final entry = await ref.read(waterRepositoryProvider).add(amountMl, at ?? DateTime.now());
    await _refreshAndReschedule();
    return entry;
  }

  Future<void> deleteEntry(int id) async {
    await ref.read(waterRepositoryProvider).delete(id);
    await _refreshAndReschedule();
  }

  Future<void> refresh() async {
    state = AsyncData(await _load(ref.read(settingsProvider)));
  }

  Future<void> _refreshAndReschedule() async {
    final s = ref.read(settingsProvider);
    final st = await _load(s);
    state = AsyncData(st);
    await ref.read(waterSchedulerProvider).reschedule(s: s, todayTotalMl: st.todayTotalMl);
  }
}

// ---- Hatırlatıcılar ----
final remindersProvider = AsyncNotifierProvider<RemindersNotifier, List<Reminder>>(RemindersNotifier.new);

class RemindersNotifier extends AsyncNotifier<List<Reminder>> {
  ReminderRepository get _repo => ref.read(reminderRepositoryProvider);
  ReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);

  @override
  Future<List<Reminder>> build() async {
    final now = DateTime.now();
    final list = await _repo.all();
    // Zamanı geçmiş tek seferlik hatırlatıcılar kapanır.
    var changed = false;
    for (final r in list) {
      if (r.enabled && r.repeat == RepeatRule.none && !r.dateTime.isAfter(now)) {
        await _repo.update(r.copyWith(enabled: false));
        changed = true;
      }
    }
    return changed ? _repo.all() : list;
  }

  Future<void> _reload() async => state = AsyncData(await _repo.all());

  Future<Reminder> add(Reminder r) async {
    final saved = await _repo.insert(r);
    await _scheduler.sync(saved);
    await _reload();
    return saved;
  }

  Future<void> edit(Reminder r) async {
    await _repo.update(r);
    await _scheduler.sync(r);
    await _reload();
  }

  Future<void> remove(int id) async {
    await _scheduler.cancel(id);
    await _repo.delete(id);
    await _reload();
  }

  Future<void> toggle(Reminder r, bool enabled) => edit(r.copyWith(enabled: enabled));

  /// Uygulama açılışında tüm hatırlatıcıları sistemde yeniden kurar.
  Future<void> syncAll() async {
    final list = await future;
    for (final r in list) {
      await _scheduler.sync(r);
    }
  }

  /// Alarm ekranında "Tamam" denince: tek seferlikse kapanır, tekrarlıysa sıradaki kurulur.
  Future<void> complete(Reminder r) async {
    if (r.repeat == RepeatRule.none) {
      await edit(r.copyWith(enabled: false));
    } else {
      await _scheduler.sync(r);
      await _reload();
    }
  }

  Future<Reminder?> byId(int id) => _repo.byId(id);
}
