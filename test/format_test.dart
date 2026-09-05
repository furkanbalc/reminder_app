import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:su_hatirlatici/core/utils/format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  test('litre biçimi', () {
    expect(fmtLiters(1400), '1.4');
    expect(fmtLiters(0), '0.0');
    expect(fmtLiters(2500), '2.5');
  });

  test('gün içi dakika', () {
    expect(fmtMinutesOfDay(480), '08:00');
    expect(fmtMinutesOfDay(23 * 60), '23:00');
  });

  test('aralık etiketi', () {
    expect(fmtInterval(90), 'Her 90 dk');
    expect(fmtInterval(120), 'Her 2 sa');
  });

  test('göreli zaman', () {
    final now = DateTime(2026, 9, 5, 13, 45);
    expect(fmtRelative(DateTime(2026, 9, 5, 14, 30), from: now), '45 dk sonra');
    expect(fmtRelative(DateTime(2026, 9, 5, 16, 0), from: now), '2 sa 15 dk sonra');
    expect(fmtRelative(DateTime(2026, 9, 6, 8, 0), from: now), 'yarın 08:00');
  });

  test('türkçe tarih başlığı', () {
    expect(fmtDayHeader(DateTime(2026, 9, 5)), 'Cumartesi, 5 Eylül');
    expect(fmtDateShort(DateTime(2026, 9, 5)), '5 Eyl, Cmt');
  });
}
