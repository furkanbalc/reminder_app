import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:su_hatirlatici/data/models/water_entry.dart';
import 'package:su_hatirlatici/data/models/water_settings.dart';
import 'package:su_hatirlatici/features/home/widgets/stats_card.dart';
import 'package:su_hatirlatici/providers/providers.dart';

import '../helpers.dart';

void main() {
  setUpAll(initLocaleForTests);

  final weekStart = DateTime(2026, 9, 7);

  WaterState makeState() => WaterState(
    todayTotalMl: 1400,
    todayEntries: [
      WaterEntry(id: 1, amountMl: 500, timestamp: DateTime(2026, 9, 9, 12, 10)),
      WaterEntry(id: 2, amountMl: 900, timestamp: DateTime(2026, 9, 9, 9, 0)),
    ],
    week: [
      for (var i = 0; i < 7; i++)
        DayTotal(
          day: weekStart.add(Duration(days: i)),
          totalMl: i == 0 ? 2600 : (i == 1 ? 1200 : (i == 2 ? 1400 : -1)),
        ),
    ],
    month: [
      for (var i = 1; i <= 30; i++)
        DayTotal(day: DateTime(2026, 9, i), totalMl: i <= 9 ? 2000 : -1),
    ],
    nextReminder: null,
    lastIntakeAt: DateTime(2026, 9, 9, 12, 10),
    streakDays: 0,
  );

  testWidgets('haftalık sekme toplamı ve ortalamayı gösterir', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: StatsCard(state: makeState(), settings: const WaterSettings()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bu hafta'), findsOneWidget);
    expect(find.text('5.2 L'), findsOneWidget); // 2.6 + 1.2 + 1.4
    expect(find.text('1.7 L'), findsOneWidget); // 5.2 / 3 gün
    expect(find.text('Pzt'), findsOneWidget);
    expect(find.text('Paz'), findsOneWidget);
  });

  testWidgets(
    'günlük sekme kayıtları listeler, aylık sekme ay toplamını gösterir',
    (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: StatsCard(
              state: makeState(),
              settings: const WaterSettings(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Günlük'));
      await tester.pumpAndSettle();
      expect(find.text('Bugün'), findsOneWidget);
      expect(find.text('1.4 L'), findsOneWidget);
      expect(find.text('%56'), findsOneWidget);
      expect(find.text('500 ml'), findsOneWidget);
      expect(find.text('900 ml'), findsOneWidget);
      expect(find.text('12:10'), findsOneWidget);

      await tester.tap(find.text('Aylık'));
      await tester.pumpAndSettle();
      expect(find.text('Eylül'), findsOneWidget);
      expect(find.text('18.0 L'), findsOneWidget); // 9 gün × 2.0
      expect(find.text('2.0 L'), findsOneWidget);
    },
  );

  testWidgets('seri metni yalnızca seri varken görünür', (tester) async {
    final withStreak = WaterState(
      todayTotalMl: 2600,
      todayEntries: const [],
      week: makeState().week,
      month: makeState().month,
      nextReminder: null,
      lastIntakeAt: null,
      streakDays: 4,
    );
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: StatsCard(state: withStreak, settings: const WaterSettings()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Günlük'));
    await tester.pumpAndSettle();
    expect(find.text('Seri: 4 gün üst üste hedef'), findsOneWidget);
    expect(find.text('Bugün henüz su kaydı yok'), findsOneWidget);
  });
}
