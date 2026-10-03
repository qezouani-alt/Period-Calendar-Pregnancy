import 'package:flutter/foundation.dart';

enum TrackingGoal { cycle, understandPeriod, conceive, pregnancy, pain }

enum CycleMode { cycle, fertility, pregnancy }

enum PainLocation { lowerAbdomen, pelvicArea, lowerBack, legs }

enum FlowLevel { none, spotting, light, medium, heavy }

enum WeightUnit {
  kilograms('kg', 1),
  pounds('lb', 2.2046226218),
  stones('st', .1574730444);

  const WeightUnit(this.label, this.perKilogram);

  final String label;
  final double perKilogram;

  double toKilograms(double value) => value / perKilogram;
  double fromKilograms(double kilograms) => kilograms * perKilogram;

  static WeightUnit fromStorage(String? value) =>
      WeightUnit.values.where((unit) => unit.name == value).firstOrNull ??
      WeightUnit.kilograms;
}

enum DietaryPreference {
  none,
  halal,
  vegetarian,
  vegan,
  pescatarian,
  glutenFree,
  lactoseFree,
  other,
}

enum FoodBudget { budgetFriendly, standard, premium }

enum FoodCuisine {
  any,
  moroccan,
  mediterranean,
  middleEastern,
  european,
  asian,
  other,
}

enum FertilityEstimate { low, moderate, higher, ovulationWindow }

enum AppointmentType {
  prenatal,
  gynecologist,
  ultrasound,
  bloodTest,
  labTest,
  midwife,
  hospital,
  other,
}

enum AppointmentStatus { upcoming, completed, cancelled }

@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.goals,
    this.typicalCycleLength,
    this.periodLength,
    this.lastPeriodStart,
    this.estimatedDueDate,
    this.privateNotifications = true,
    this.dietaryPreference = DietaryPreference.none,
    this.foodBudget = FoodBudget.standard,
    this.foodCuisine = FoodCuisine.any,
  });
  final String name;
  final Set<TrackingGoal> goals;
  final int? typicalCycleLength, periodLength;
  final DateTime? lastPeriodStart;
  final DateTime? estimatedDueDate;
  final bool privateNotifications;
  final DietaryPreference dietaryPreference;
  final FoodBudget foodBudget;
  final FoodCuisine foodCuisine;
  bool get pregnancyActive =>
      goals.contains(TrackingGoal.pregnancy) || estimatedDueDate != null;
  CycleMode get mode => pregnancyActive
      ? CycleMode.pregnancy
      : goals.contains(TrackingGoal.conceive)
      ? CycleMode.fertility
      : CycleMode.cycle;
}

@immutable
class PeriodEntry {
  const PeriodEntry({required this.start, required this.end});
  final DateTime start, end;
  int get duration => end.difference(start).inDays + 1;
}

@immutable
class DailyHealthLog {
  const DailyHealthLog({
    required this.date,
    this.painIntensity,
    this.flow,
    this.symptoms = const {},
    this.mood,
    this.energy,
    this.notes,
    this.locations = const {},
    this.customFlow,
    this.customBody,
    this.customPainLocation,
    this.customMood,
  });
  final DateTime date;
  final int? painIntensity;
  final FlowLevel? flow;
  final Set<String> symptoms;
  final String? mood, energy, notes;
  final Set<PainLocation> locations;
  final String? customFlow, customBody, customPainLocation, customMood;
}

@immutable
class CyclePrediction {
  const CyclePrediction({
    this.averageLength,
    this.averagePeriodLength,
    this.nextPeriod,
    this.ovulationStart,
    this.ovulationEnd,
    this.fertileStart,
    this.fertileEnd,
    this.futureCycles = const [],
    required this.confidence,
  });
  final double? averageLength, averagePeriodLength;
  final DateTime? nextPeriod,
      ovulationStart,
      ovulationEnd,
      fertileStart,
      fertileEnd;
  final List<CycleForecast> futureCycles;
  final PredictionConfidence confidence;
}

@immutable
class CycleForecast {
  const CycleForecast({
    required this.periodStart,
    required this.periodEnd,
    required this.ovulationStart,
    required this.ovulationEnd,
    required this.fertileStart,
    required this.fertileEnd,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime ovulationStart;
  final DateTime ovulationEnd;
  final DateTime fertileStart;
  final DateTime fertileEnd;
}

enum PredictionConfidence { limited, developing, personalized }

@immutable
class HealthArticle {
  const HealthArticle({
    required this.title,
    required this.summary,
    required this.category,
    required this.sourceOrganization,
    required this.sourceUrl,
    required this.body,
  });
  final String title, summary, category, sourceOrganization, sourceUrl, body;
}

@immutable
class PregnancyAppointment {
  const PregnancyAppointment({
    required this.id,
    required this.type,
    required this.dateTime,
    required this.status,
    this.doctorName,
    this.clinicName,
    this.notes,
    this.reminderAt,
    this.reminderMessage,
  });
  final String id;
  final AppointmentType type;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String? doctorName, clinicName, notes;
  final DateTime? reminderAt;
  final String? reminderMessage;
  String get title => switch (type) {
    AppointmentType.prenatal => 'Prenatal visit',
    AppointmentType.gynecologist => 'Gynecologist visit',
    AppointmentType.ultrasound => 'Ultrasound',
    AppointmentType.bloodTest => 'Blood test',
    AppointmentType.labTest => 'Lab test',
    AppointmentType.midwife => 'Midwife appointment',
    AppointmentType.hospital => 'Hospital appointment',
    AppointmentType.other => 'Health appointment',
  };
}

@immutable
class MaternalWeightEntry {
  const MaternalWeightEntry({
    required this.id,
    required this.date,
    required this.kilograms,
    this.unit = WeightUnit.kilograms,
  });

  final String id;
  final DateTime date;
  final double kilograms;
  final WeightUnit unit;
  double get weightInSelectedUnit => unit.fromKilograms(kilograms);
}

@immutable
class DoctorQuestion {
  const DoctorQuestion({
    required this.id,
    required this.text,
    required this.createdAt,
    this.discussed = false,
    this.appointmentId,
  });
  final String id;
  final String text;
  final DateTime createdAt;
  final bool discussed;
  final String? appointmentId;
}

@immutable
class PregnancyRecord {
  const PregnancyRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.createdAt,
    this.doctorName,
    this.clinicName,
    this.note,
    this.attachmentPaths = const [],
  });
  final String id;
  final String title;
  final DateTime date;
  final DateTime createdAt;
  final String? doctorName;
  final String? clinicName;
  final String? note;
  final List<String> attachmentPaths;
}

@immutable
class PeriodNote {
  const PeriodNote({
    required this.id,
    required this.date,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final String text;
  final DateTime createdAt;
}

@immutable
class PregnancyNote {
  const PregnancyNote({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String text;
  final DateTime createdAt;
}

@immutable
class SymptomEntry {
  const SymptomEntry({
    required this.id,
    required this.createdAt,
    required this.summary,
  });

  final String id;
  final DateTime createdAt;
  final String summary;
}
