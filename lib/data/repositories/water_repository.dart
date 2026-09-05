import 'package:sqflite/sqflite.dart';

import '../models/water_entry.dart';

class WaterRepository {
  WaterRepository(this._db);

  final Database _db;

  Future<WaterEntry> add(int amountMl, DateTime at) async {
    final id = await _db.insert('water_entries', {
      'amount_ml': amountMl,
      'timestamp': at.millisecondsSinceEpoch,
    });
    return WaterEntry(id: id, amountMl: amountMl, timestamp: at);
  }

  Future<void> delete(int id) =>
      _db.delete('water_entries', where: 'id = ?', whereArgs: [id]);

  /// [start] dahil, [end] hariç.
  Future<List<WaterEntry>> entriesBetween(DateTime start, DateTime end) async {
    final rows = await _db.query(
      'water_entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
    );
    return rows.map(WaterEntry.fromMap).toList();
  }

  Future<int> totalBetween(DateTime start, DateTime end) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(amount_ml), 0) AS total FROM water_entries WHERE timestamp >= ? AND timestamp < ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return (rows.first['total'] as num).toInt();
  }
}
