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

  Future<void> update(int id, {required int amountMl, required DateTime at}) =>
      _db.update(
        'water_entries',
        {'amount_ml': amountMl, 'timestamp': at.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<WaterEntry?> byId(int id) async {
    final rows = await _db.query(
      'water_entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : WaterEntry.fromMap(rows.first);
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

  Future<List<WaterEntry>> all() async {
    final rows = await _db.query('water_entries', orderBy: 'timestamp ASC');
    return rows.map(WaterEntry.fromMap).toList();
  }

  Future<bool> exists(int amountMl, DateTime at) async {
    final rows = await _db.query(
      'water_entries',
      where: 'amount_ml = ? AND timestamp = ?',
      whereArgs: [amountMl, at.millisecondsSinceEpoch],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> totalBetween(DateTime start, DateTime end) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(amount_ml), 0) AS total FROM water_entries WHERE timestamp >= ? AND timestamp < ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return (rows.first['total'] as num).toInt();
  }
}
