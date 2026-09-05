import 'package:sqflite/sqflite.dart';

import '../models/reminder.dart';

class ReminderRepository {
  ReminderRepository(this._db);

  final Database _db;

  Future<List<Reminder>> all() async {
    final rows = await _db.query('reminders', orderBy: 'date_time ASC');
    return rows.map(Reminder.fromMap).toList();
  }

  Future<Reminder?> byId(int id) async {
    final rows = await _db.query('reminders', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Reminder.fromMap(rows.first);
  }

  Future<Reminder> insert(Reminder r) async {
    final id = await _db.insert('reminders', r.toMap());
    return r.copyWith(id: id);
  }

  Future<void> update(Reminder r) =>
      _db.update('reminders', r.toMap(), where: 'id = ?', whereArgs: [r.id]);

  Future<void> delete(int id) =>
      _db.delete('reminders', where: 'id = ?', whereArgs: [id]);
}
