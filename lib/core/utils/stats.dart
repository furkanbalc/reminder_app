/// Üst üste hedefe ulaşılan gün sayısı.
///
/// Bugün hedefe ulaşıldıysa bugünden, ulaşılmadıysa dünden geriye sayar;
/// böylece gün içinde seri "kopmuş" görünmez.
int computeStreak(Map<DateTime, int> totalsByDay, DateTime today, int goalMl) {
  var day = (totalsByDay[today] ?? 0) >= goalMl
      ? today
      : today.subtract(const Duration(days: 1));
  var count = 0;
  while ((totalsByDay[day] ?? 0) >= goalMl && count < 365) {
    count++;
    day = day.subtract(const Duration(days: 1));
  }
  return count;
}
