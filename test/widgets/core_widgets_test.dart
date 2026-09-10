import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:su_hatirlatici/core/widgets/widgets.dart';
import 'package:su_hatirlatici/features/home/widgets/bar_chart.dart';
import 'package:su_hatirlatici/features/home/widgets/progress_ring.dart';

import '../helpers.dart';

void main() {
  setUpAll(initLocaleForTests);

  testWidgets('SegmentedControl seçimi bildirir', (tester) async {
    var selected = 0;
    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: SegmentedControl(
            items: const ['Günlük', 'Haftalık', 'Aylık'],
            selected: selected,
            onChanged: (i) => setState(() => selected = i),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aylık'));
    await tester.pumpAndSettle();
    expect(selected, 2);
  });

  testWidgets('AppToggle dokununca değer değişir', (tester) async {
    var value = false;
    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: Center(
            child: AppToggle(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AppToggle));
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  testWidgets('PageHeader başlık, alt yazı ve sağ düğmeyi çizer', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Scaffold(
        body: PageHeader(
          title: 'Ayarlar',
          subtitle: 'Çarşamba, 9 Eylül',
          trailing: CircleIconButton(icon: Icons.add_rounded, onTap: () {}),
        ),
      ),
    );
    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Çarşamba, 9 Eylül'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('ProgressRing taşan ilerlemeyi kırpar ve çocuğu gösterir', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: Center(child: ProgressRing(progress: 1.6, child: Text('1.4'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1.4'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('WaterBarChart gelecek güne dokunulmaz, geçmişe dokunulur', (
    tester,
  ) async {
    int? tapped;
    await pumpApp(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: WaterBarChart(
            goalMl: 2500,
            onBarTap: (i) => tapped = i,
            bars: const [
              BarData(label: 'Pzt', valueMl: 2600),
              BarData(label: 'Sal', valueMl: 0),
              BarData(label: 'Çar', valueMl: null),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çar'));
    await tester.pumpAndSettle();
    expect(tapped, isNull);
    await tester.tap(find.text('Pzt'));
    await tester.pumpAndSettle();
    expect(tapped, 0);
    expect(find.text('hedef 2.5'), findsOneWidget);
  });
}
