class WaterEntry {
  const WaterEntry({
    required this.id,
    required this.amountMl,
    required this.timestamp,
  });

  final int id;
  final int amountMl;
  final DateTime timestamp;

  factory WaterEntry.fromMap(Map<String, Object?> m) => WaterEntry(
    id: m['id'] as int,
    amountMl: m['amount_ml'] as int,
    timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
  );

  Map<String, Object?> toJson() => {
    'amountMl': amountMl,
    'timestamp': timestamp.toIso8601String(),
  };
}

class DayTotal {
  const DayTotal({required this.day, required this.totalMl});

  final DateTime day;
  final int totalMl;
}
