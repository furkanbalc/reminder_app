import 'dart:convert';
import 'dart:io';

import '../data/models/reminder.dart';
import '../data/models/water_settings.dart';
import '../data/repositories/reminder_repository.dart';
import '../data/repositories/water_repository.dart';

class ImportResult {
  const ImportResult({
    required this.entriesAdded,
    required this.remindersAdded,
    required this.settings,
  });
  final int entriesAdded;
  final int remindersAdded;
  final WaterSettings? settings;
}

/// Yerel yedek: tüm veriler tek bir JSON dosyasında.
class BackupService {
  BackupService(this._water, this._reminders);

  final WaterRepository _water;
  final ReminderRepository _reminders;

  static const version = 1;

  Future<File> writeExport(WaterSettings settings) async {
    final entries = await _water.all();
    final reminders = await _reminders.all();
    final json = {
      'app': 'su_hatirlatici',
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'waterEntries': [for (final e in entries) e.toJson()],
      'reminders': [for (final r in reminders) r.toJson()],
    };
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final file = File(
      '${Directory.systemTemp.path}/su-hatirlatici-yedek-$stamp.json',
    );
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
    return file;
  }

  /// Var olan kayıtları korur; aynı zaman ve miktardaki su kayıtlarını atlar.
  Future<ImportResult> importFile(
    File file, {
    required WaterSettings current,
  }) async {
    final data = jsonDecode(await file.readAsString());
    if (data is! Map || data['app'] != 'su_hatirlatici') {
      throw const FormatException('Bu dosya bir Su Hatırlatıcı yedeği değil');
    }
    var entriesAdded = 0;
    for (final raw in (data['waterEntries'] as List? ?? const [])) {
      final m = raw as Map;
      final ml = (m['amountMl'] as num?)?.toInt();
      final at = DateTime.tryParse(m['timestamp'] as String? ?? '');
      if (ml == null || at == null) continue;
      if (await _water.exists(ml, at)) continue;
      await _water.add(ml, at);
      entriesAdded++;
    }
    var remindersAdded = 0;
    for (final raw in (data['reminders'] as List? ?? const [])) {
      final r = Reminder.fromJson((raw as Map).cast<String, Object?>());
      if (r.title.trim().isEmpty) continue;
      await _reminders.insert(r);
      remindersAdded++;
    }
    WaterSettings? settings;
    final sj = data['settings'];
    if (sj is Map) {
      settings = WaterSettings.fromJson(
        sj.cast<String, Object?>(),
        base: current,
      );
    }
    return ImportResult(
      entriesAdded: entriesAdded,
      remindersAdded: remindersAdded,
      settings: settings,
    );
  }
}
