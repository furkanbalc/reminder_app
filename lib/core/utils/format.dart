import 'package:intl/intl.dart';

const _tr = 'tr_TR';

/// 1400 -> "1.4"
String fmtLiters(int ml) => (ml / 1000).toStringAsFixed(1);

String fmtTime(DateTime t) => DateFormat.Hm(_tr).format(t);

/// "5 Eyl, Cmt"
String fmtDateShort(DateTime d) => DateFormat('d MMM, EEE', _tr).format(d);

/// "Cumartesi, 5 Eylül"
String fmtDayHeader(DateTime d) {
  final s = DateFormat('EEEE, d MMMM', _tr).format(d);
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// 08:00 gibi gün içi dakika değeri
String fmtMinutesOfDay(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String fmtInterval(int minutes) {
  if (minutes < 120) return 'Her $minutes dk';
  if (minutes % 60 == 0) return 'Her ${minutes ~/ 60} sa';
  return 'Her ${minutes ~/ 60} sa ${minutes % 60} dk';
}

/// "45 dk sonra", "2 sa 10 dk sonra", "yarın 08:00"
String fmtRelative(DateTime target, {DateTime? from}) {
  final now = from ?? DateTime.now();
  final diff = target.difference(now);
  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(target.year, target.month, target.day);
  if (targetDay.difference(today).inDays >= 1) {
    final dayWord = targetDay.difference(today).inDays == 1
        ? 'yarın'
        : fmtDateShort(target);
    return '$dayWord ${fmtTime(target)}';
  }
  if (diff.inMinutes < 1) return 'şimdi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk sonra';
  final h = diff.inHours;
  final m = diff.inMinutes % 60;
  return m == 0 ? '$h sa sonra' : '$h sa $m dk sonra';
}

String greeting(DateTime now) {
  final h = now.hour;
  if (h < 6) return 'İyi geceler';
  if (h < 12) return 'Günaydın';
  if (h < 18) return 'İyi günler';
  return 'İyi akşamlar';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
