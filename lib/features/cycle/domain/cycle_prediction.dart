import '../../shared/domain/health_models.dart';

class CyclePredictionEngine {
  const CyclePredictionEngine();
  CyclePrediction estimate({
    required List<PeriodEntry> periods,
    int? typicalLength,
    int? typicalPeriodLength,
  }) {
    final ordered = [...periods]..sort((a, b) => a.start.compareTo(b.start));
    final lengths = <int>[];
    for (var i = 1; i < ordered.length; i++) {
      final days = _calendarDaysBetween(ordered[i - 1].start, ordered[i].start);
      if (days >= 15 && days <= 90) lengths.add(days);
    }
    final average = lengths.isNotEmpty
        ? lengths.reduce((a, b) => a + b) / lengths.length
        : typicalLength?.toDouble() ?? (ordered.isEmpty ? null : 28.0);
    final bleeding = ordered.isNotEmpty
        ? ordered.map((e) => e.duration).reduce((a, b) => a + b) /
              ordered.length
        : typicalPeriodLength?.toDouble();
    if (ordered.isEmpty || average == null) {
      return CyclePrediction(
        averageLength: average,
        averagePeriodLength: bleeding,
        confidence: PredictionConfidence.limited,
      );
    }
    final latest = ordered.last.start;
    final next = _addCalendarDays(latest, average.round());
    final variation = lengths.length < 2
        ? 0
        : lengths.map((x) => (x - average).abs()).reduce((a, b) => a + b) /
              lengths.length;
    final range = variation > 4 ? 3 : 1;
    final ovulation = _addCalendarDays(next, -14);
    final periodDays = (bleeding ?? typicalPeriodLength?.toDouble() ?? 5)
        .round()
        .clamp(1, 10);
    final forecasts = <CycleForecast>[];
    final cyclesToForecast = ((24 * 31) / average).ceil();
    for (var index = 1; index <= cyclesToForecast; index++) {
      final periodStart = _addCalendarDays(latest, average.round() * index);
      final forecastOvulation = _addCalendarDays(periodStart, -14);
      forecasts.add(
        CycleForecast(
          periodStart: periodStart,
          periodEnd: _addCalendarDays(periodStart, periodDays - 1),
          ovulationStart: _addCalendarDays(forecastOvulation, -range),
          ovulationEnd: _addCalendarDays(forecastOvulation, range),
          fertileStart: _addCalendarDays(forecastOvulation, -5 - range),
          fertileEnd: _addCalendarDays(forecastOvulation, 1 + range),
        ),
      );
    }
    return CyclePrediction(
      averageLength: average,
      averagePeriodLength: bleeding,
      nextPeriod: next,
      ovulationStart: _addCalendarDays(ovulation, -range),
      ovulationEnd: _addCalendarDays(ovulation, range),
      fertileStart: _addCalendarDays(ovulation, -5 - range),
      fertileEnd: _addCalendarDays(ovulation, 1 + range),
      futureCycles: forecasts,
      confidence: lengths.length >= 3 && variation <= 4
          ? PredictionConfidence.personalized
          : PredictionConfidence.developing,
    );
  }

  DateTime _addCalendarDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  int _calendarDaysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}
