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
import '../services/alarmkit_service.dart';
import '../services/backup_service.dart';
import '../services/health_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_scheduler.dart';
import '../services/water_scheduler.dart';
import '../services/widget_service.dart';

// ---- main() içinde override edilen altyapı sağlayıcıları ----
final sharedPreferencesProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError('main içinde override edilir'));
final databaseProvider = Provider<Database>((_) => throw UnimplementedError('main içinde override edilir'));
final notificationServiceProvider =
    Provider<NotificationService>((_) => throw UnimplementedError('main içinde override edilir'));

final alarmKitServiceProvider = Provider<AlarmKitService>((_) => AlarmKitService());
final alarmServiceProvider = Provider<AlarmService>(
  (ref) => AlarmService(ref.watch(sharedPreferencesProvider), ref.watch(alarmKitServiceProvider)),
);
final healthServiceProvider = Provider<HealthService>((_) => HealthService());
final widgetServiceProvider = Provider<WidgetService>((_) => WidgetService());

final waterRepositoryProvider = Provider((ref) => WaterRepository(ref.watch(databaseProvider)));
final reminderRepositoryProvider = Provider((ref) => ReminderRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)));
final backupServiceProvider = Provider(
  (ref) => BackupService(ref.watch(waterRepositoryProvider), ref.watch(reminderRepositoryProvider)),
);

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

  /// Kaydeder ve su hatırlatmalarını yeniden kurar.
  Future<void> save(WaterSettings s) async {
    final alarmTypeChanged = s.useSystemAlarm != state.useSystemAlarm;
    state = s;
    await ref.read(settingsRepositoryProvider).save(s);
    if (alarmTypeChanged) {
      await ref.read(alarmServiceProvider).configureSystemAlarm(s.useSystemAlarm);
    }
    await ref.read(waterProvider.notifier).rescheduleReminders();
    if (alarmTypeChanged) await ref.read(remindersProvider.notifier).syncAll();
  }

  /// Sadece kaydeder (ilk açılış gibi, henüz zamanlama istemeyen yerler için).
  Future<void> saveQuiet(WaterSettings s) async {
    state = s;
    await ref.read(settingsRepositoryProvider).save(s);
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
    required this.lastIntakeAt,
    required this.streakDays,
  });

  final int todayTotalMl;
  final List<WaterEntry> todayEntries;
  /// Pazartesiden pazara 7 gün. Gelecek günler için totalMl = -1.
  final List<DayTotal> week;
  /// Ayın her günü. Gelecek günler için totalMl = -1.
  final List<DayTotal> month;
  final DateTime? nextReminder;
  final DateTime? lastIntakeAt;
  /// Üst üste hedefe ulaşılan gün sayısı (bugün dahil veya dünle biten).
  final int streakDays;

  int get weekTotalMl => week.where((d) => d.totalMl >= 0).fold(0, (a, d) => a + d.totalMl);
  int get monthTotalMl => month.where((d) => d.totalMl >= 0).fold(0, (a, d) => a + d.totalMl);
  int get weekDaysElapsed => week.where((d) => d.totalMl >= 0).length;
  int get monthDaysElapsed => month.where((d) => d.totalMl >= 0).length;
}

class AddResult {
  const AddResult({required this.entry, required this.reachedGoalNow, required this.streakDays});
  final WaterEntry entry;
  /// Bu kayıtla günlük hedef ilk kez aşıldı mı?
  final bool reachedGoalNow;
  final int streakDays;
}

final waterProvider = AsyncNotifierProvider<WaterNotifier, WaterState>(WaterNotifier.new);

class WaterNotifier extends AsyncNotifier<WaterState> {
  WaterRepository get _repo => ref.read(waterRepositoryProvider);

  @override
  Future<WaterState> build() async {
    final settings = ref.watch(settingsProvider);
    return _load(settings);
  }

  Future<WaterState> _load(WaterSettings s) async {
    final now = DateTime.now();
    final today = startOfDay(now);
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final streakStart = today.subtract(const Duration(days: 60));
    final rangeStart = [weekStart, monthStart, streakStart].reduce((a, b) => a.isBefore(b) ? a : b);

    final entries = await _repo.entriesBetween(rangeStart, tomorrow);
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
    final lastIntake = entries.isEmpty ? null : entries.last.timestamp;
    final streak = _streak(totals, today, s.goalMl);
    final next = ref.read(waterSchedulerProvider).next(
          s, now, goalReachedToday: todayTotal >= s.goalMl, lastIntakeAt: lastIntake);

    return WaterState(
      todayTotalMl: todayTotal,
      todayEntries: todayEntries,
      week: week,
      month: month,
      nextReminder: next,
      lastIntakeAt: lastIntake,
      streakDays: streak,
    );
  }

  static int _streak(Map<DateTime, int> totals, DateTime today, int goalMl) {
    var day = (totals[today] ?? 0) >= goalMl ? today : today.subtract(const Duration(days: 1));
    var count = 0;
    while ((totals[day] ?? 0) >= goalMl && count < 365) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  Future<AddResult> addEntry(int amountMl, {DateTime? at}) async {
    final s = ref.read(settingsProvider);
    final before = state.value?.todayTotalMl ?? 0;
    final when = at ?? DateTime.now();
    final entry = await _repo.add(amountMl, when);
    if (s.healthSync) await ref.read(healthServiceProvider).writeWater(amountMl, when);
    final st = await _refreshAndReschedule();
    final reached = isSameDay(when, DateTime.now()) && before < s.goalMl && st.todayTotalMl >= s.goalMl;
    return AddResult(entry: entry, reachedGoalNow: reached, streakDays: st.streakDays);
  }

  Future<void> updateEntry(int id, {required int amountMl, required DateTime at}) async {
    final s = ref.read(settingsProvider);
    final old = await _repo.byId(id);
    await _repo.update(id, amountMl: amountMl, at: at);
    if (s.healthSync) {
      final health = ref.read(healthServiceProvider);
      if (old != null) await health.deleteWater(old.timestamp);
      await health.writeWater(amountMl, at);
    }
    await _refreshAndReschedule();
  }

  Future<void> deleteEntry(int id) async {
    final s = ref.read(settingsProvider);
    final old = await _repo.byId(id);
    await _repo.delete(id);
    if (s.healthSync && old != null) await ref.read(healthServiceProvider).deleteWater(old.timestamp);
    await _refreshAndReschedule();
  }

  Future<void> refresh() async {
    final s = ref.read(settingsProvider);
    final st = await _load(s);
    state = AsyncData(st);
    await _pushWidget(st, s);
  }

  Future<void> _pushWidget(WaterState st, WaterSettings s) => ref.read(widgetServiceProvider).push(
        totalMl: st.todayTotalMl,
        goalMl: s.goalMl,
        glassMl: s.defaultGlassMl,
        next: st.nextReminder,
      );

  /// Ayar değişikliğinde: yeniden yükle ve hatırlatmaları kur.
  Future<void> rescheduleReminders() => _refreshAndReschedule();

  Future<WaterState> _refreshAndReschedule() async {
    final s = ref.read(settingsProvider);
    final st = await _load(s);
    state = AsyncData(st);
    await _pushWidget(st, s);
    await ref.read(waterSchedulerProvider).reschedule(
          s: s,
          todayTotalMl: st.todayTotalMl,
          lastIntakeAt: st.lastIntakeAt,
          weekSummary: _weekSummary(st, s),
        );
    return st;
  }

  static String _weekSummary(WaterState st, WaterSettings s) {
    final goalDays = st.week.where((d) => d.totalMl >= s.goalMl).length;
    return 'Bu hafta ${fmtLiters(st.weekTotalMl)} L içtin, $goalDays gün hedefi tutturdun.';
  }
}

/// Geçmiş hafta/ay istatistikleri. offset 0 = bu dönem, -1 = önceki dönem.
class PeriodKey {
  const PeriodKey({required this.isWeek, required this.offset});
  final bool isWeek;
  final int offset;

  @override
  bool operator ==(Object other) => other is PeriodKey && other.isWeek == isWeek && other.offset == offset;

  @override
  int get hashCode => Object.hash(isWeek, offset);
}

class PeriodStats {
  const PeriodStats({required this.start, required this.end, required this.days});
  final DateTime start;
  /// hariç
  final DateTime end;
  final List<DayTotal> days;
  int get totalMl => days.where((d) => d.totalMl >= 0).fold(0, (a, d) => a + d.totalMl);
  int get daysElapsed => days.where((d) => d.totalMl >= 0).length;
}

final periodStatsProvider = FutureProvider.autoDispose.family<PeriodStats, PeriodKey>((ref, key) async {
  ref.watch(waterProvider); // kayıt değişince yenile
  final repo = ref.read(waterRepositoryProvider);
  final now = DateTime.now();
  final today = startOfDay(now);
  late DateTime start;
  late DateTime end;
  if (key.isWeek) {
    final thisWeek = today.subtract(Duration(days: today.weekday - 1));
    start = thisWeek.add(Duration(days: 7 * key.offset));
    end = start.add(const Duration(days: 7));
  } else {
    start = DateTime(now.year, now.month + key.offset, 1);
    end = DateTime(start.year, start.month + 1, 1);
  }
  final entries = await repo.entriesBetween(start, end);
  final totals = <DateTime, int>{};
  for (final e in entries) {
    final d = startOfDay(e.timestamp);
    totals[d] = (totals[d] ?? 0) + e.amountMl;
  }
  final days = <DayTotal>[];
  for (var d = start; d.isBefore(end); d = d.add(const Duration(days: 1))) {
    days.add(DayTotal(day: d, totalMl: d.isAfter(today) ? -1 : (totals[d] ?? 0)));
  }
  return PeriodStats(start: start, end: end, days: days);
});

// ---- Hatırlatıcılar ----
final remindersProvider = AsyncNotifierProvider<RemindersNotifier, List<Reminder>>(RemindersNotifier.new);

class RemindersNotifier extends AsyncNotifier<List<Reminder>> {
  ReminderRepository get _repo => ref.read(reminderRepositoryProvider);
  ReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);
  WaterSettings get _settings => ref.read(settingsProvider);

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
    await _scheduler.sync(saved, _settings);
    await _reload();
    return saved;
  }

  Future<void> edit(Reminder r) async {
    await _repo.update(r);
    await _scheduler.sync(r, _settings);
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
      await _scheduler.sync(r, _settings);
    }
  }

  /// "Tamam" denince: tek seferlikse kapanır, tekrarlıysa sıradaki kurulur.
  Future<void> complete(Reminder r) async {
    if (r.repeat == RepeatRule.none) {
      await edit(r.copyWith(enabled: false));
    } else {
      await _scheduler.sync(r, _settings);
      await _reload();
    }
  }

  Future<void> snooze(Reminder r) => _scheduler.snooze(r, _settings);

  Future<Reminder?> byId(int id) => _repo.byId(id);
}
