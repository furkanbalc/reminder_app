import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:su_hatirlatici/features/onboarding/onboarding_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(initLocaleForTests);

  testWidgets('ilk açılış adımları ilerler ve hedef seçilebilir', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester, const OnboardingScreen());
    await tester.pumpAndSettle();

    expect(find.text('Su içmeyi unutma'), findsOneWidget);
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();

    expect(find.text('Günlük hedefin'), findsOneWidget);
    expect(find.text('2.5 L'), findsWidgets); // varsayılan hedef
    await tester.tap(find.text('3.0 L'));
    await tester.pumpAndSettle();
    expect(find.text('3.0 L'), findsWidgets);

    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
    expect(find.text('Saatler ve bardak'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('23:00'), findsOneWidget);

    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
    expect(find.text('Nasıl hatırlatalım?'), findsOneWidget);
    expect(find.text('Bildirim'), findsOneWidget);
    expect(find.text('Alarm'), findsOneWidget);
    expect(find.text('Yükselen'), findsOneWidget);

    await tester.tap(find.text('Yükselen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
    expect(find.text('Birkaç izin'), findsOneWidget);
    expect(find.text('İzin ver ve başla'), findsOneWidget);
  });

  testWidgets('geri düğmesi bir önceki adıma döner', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester, const OnboardingScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Su içmeyi unutma'), findsOneWidget);
  });
}
