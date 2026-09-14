class PregnancyTimeline {
  const PregnancyTimeline._();
  static PregnancyWeek? fromDueDate(DateTime? dueDate, {DateTime? onDate}) {
    if (dueDate == null) return null;
    final date = _day(onDate ?? DateTime.now());
    final due = _day(dueDate);
    final gestationalDays = 280 - due.difference(date).inDays;
    if (gestationalDays < 0) return null;
    return PregnancyWeek(week: gestationalDays ~/ 7, day: gestationalDays % 7);
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class PregnancyWeek {
  const PregnancyWeek({required this.week, required this.day});
  final int week, day;
  String get label => 'Week $week · day ${day + 1}';
  String get trimester => week < 14
      ? 'First trimester'
      : week < 28
      ? 'Second trimester'
      : 'Third trimester';
}
