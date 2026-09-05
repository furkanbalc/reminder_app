import 'enums.dart';

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.repeat,
    required this.alertType,
    required this.sound,
    required this.enabled,
    required this.createdAt,
  });

  final int id;
  final String title;
  final DateTime dateTime;
  final RepeatRule repeat;
  final AlertType alertType;
  final AlarmSound sound;
  final bool enabled;
  final DateTime createdAt;

  static const newId = 0;

  Reminder copyWith({
    int? id,
    String? title,
    DateTime? dateTime,
    RepeatRule? repeat,
    AlertType? alertType,
    AlarmSound? sound,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      repeat: repeat ?? this.repeat,
      alertType: alertType ?? this.alertType,
      sound: sound ?? this.sound,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != newId) 'id': id,
        'title': title,
        'date_time': dateTime.millisecondsSinceEpoch,
        'repeat': repeat.name,
        'alert_type': alertType.name,
        'sound': sound.name,
        'enabled': enabled ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Reminder.fromMap(Map<String, Object?> m) => Reminder(
        id: m['id'] as int,
        title: m['title'] as String,
        dateTime: DateTime.fromMillisecondsSinceEpoch(m['date_time'] as int),
        repeat: RepeatRule.fromName(m['repeat'] as String?),
        alertType: AlertType.fromName(m['alert_type'] as String?),
        sound: AlarmSound.fromName(m['sound'] as String?),
        enabled: (m['enabled'] as int? ?? 1) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  /// [from] anından sonraki ilk çalma zamanı. Yoksa null (geçmiş tek seferlik).
  DateTime? nextOccurrence(DateTime from) {
    DateTime at(DateTime day) =>
        DateTime(day.year, day.month, day.day, dateTime.hour, dateTime.minute);

    switch (repeat) {
      case RepeatRule.none:
        return dateTime.isAfter(from) ? dateTime : null;
      case RepeatRule.daily:
        var t = at(from);
        if (!t.isAfter(from)) t = at(from.add(const Duration(days: 1)));
        return t;
      case RepeatRule.weekdays:
        var day = from;
        for (var i = 0; i < 8; i++) {
          final t = at(day);
          if (day.weekday <= DateTime.friday && t.isAfter(from)) return t;
          day = day.add(const Duration(days: 1));
        }
        return null;
      case RepeatRule.weekly:
        var day = from;
        for (var i = 0; i < 8; i++) {
          final t = at(day);
          if (day.weekday == dateTime.weekday && t.isAfter(from)) return t;
          day = day.add(const Duration(days: 1));
        }
        return null;
      case RepeatRule.monthly:
        for (var i = 0; i < 13; i++) {
          final month = DateTime(from.year, from.month + i, 1);
          final lastDay = DateTime(month.year, month.month + 1, 0).day;
          final day = dateTime.day > lastDay ? lastDay : dateTime.day;
          final t = DateTime(month.year, month.month, day, dateTime.hour, dateTime.minute);
          if (t.isAfter(from)) return t;
        }
        return null;
    }
  }
}
