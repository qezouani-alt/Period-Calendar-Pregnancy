import 'health_models.dart';

enum ActiveHealthMode {
  cycleTracking,
  periodActive,
  fertilityTracking,
  pregnancyActive,
}

class ActiveHealthContext {
  const ActiveHealthContext({
    required this.mode,
    required this.today,
    this.periodDay,
  });
  final ActiveHealthMode mode;
  final DateTime today;
  final int? periodDay;

  bool get isPregnancy => mode == ActiveHealthMode.pregnancyActive;
  bool get isPeriod => mode == ActiveHealthMode.periodActive;
  bool get isFertility => mode == ActiveHealthMode.fertilityTracking;
}

class HealthModeService {
  const HealthModeService();

  ActiveHealthContext resolve({
    required UserProfile? profile,
    required List<PeriodEntry> periods,
    DateTime? date,
  }) {
    final today = _day(date ?? DateTime.now());
    // Pregnancy is intentionally resolved first. Historical period entries are
    // retained but never become the active experience during pregnancy.
    if (profile?.pregnancyActive ?? false) {
      return ActiveHealthContext(
        mode: ActiveHealthMode.pregnancyActive,
        today: today,
      );
    }
    final period = periods
        .where(
          (entry) =>
              !today.isBefore(_day(entry.start)) &&
              !today.isAfter(_day(entry.end)),
        )
        .firstOrNull;
    if (period != null) {
      return ActiveHealthContext(
        mode: ActiveHealthMode.periodActive,
        today: today,
        periodDay: today.difference(_day(period.start)).inDays + 1,
      );
    }
    if (profile?.goals.contains(TrackingGoal.conceive) ?? false) {
      return ActiveHealthContext(
        mode: ActiveHealthMode.fertilityTracking,
        today: today,
      );
    }
    return ActiveHealthContext(
      mode: ActiveHealthMode.cycleTracking,
      today: today,
    );
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
}
