import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/notifications/appointment_reminder_service.dart';
import '../features/cycle/domain/cycle_prediction.dart';
import '../features/shared/domain/health_mode_service.dart';
import '../features/shared/domain/health_models.dart';

class AppController extends ChangeNotifier {
  AppController._();
  static const _key = 'luna_state_v1';
  UserProfile? profile;
  final List<PeriodEntry> periods = [];
  final Map<String, DailyHealthLog> logs = {};
  final List<PeriodNote> periodNotes = [];
  final Map<String, String> pregnancyJournal = {};
  final List<PregnancyNote> pregnancyNotes = [];
  final List<SymptomEntry> symptomEntries = [];
  final List<PregnancyAppointment> appointments = [];
  final List<DoctorQuestion> doctorQuestions = [];
  final List<PregnancyRecord> pregnancyRecords = [];
  final List<MaternalWeightEntry> maternalWeights = [];
  int? maternalHeightCm;
  final AppointmentReminderService _reminders = AppointmentReminderService();
  bool darkMode = false;
  bool permissionsOnboardingSeen = false;
  bool isReady = false;
  static const _healthModeService = HealthModeService();

  static Future<AppController> load() async {
    final controller = AppController._();
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_key);
    if (saved != null) {
      controller._restore(jsonDecode(saved) as Map<String, dynamic>);
    }
    controller.isReady = true;
    return controller;
  }

  CyclePrediction get prediction => const CyclePredictionEngine().estimate(
    periods: periods,
    typicalLength: profile?.typicalCycleLength,
    typicalPeriodLength: profile?.periodLength,
  );
  DailyHealthLog? logFor(DateTime date) => logs[_dateKey(date)];
  List<PeriodNote> periodNotesFor(DateTime date) =>
      periodNotes
          .where((note) => _dateKey(note.date) == _dateKey(date))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  ActiveHealthContext get healthContext =>
      _healthModeService.resolve(profile: profile, periods: periods);

  Future<void> completeOnboarding({
    required String name,
    required Set<TrackingGoal> goals,
    int? cycleLength,
    int? periodLength,
    DateTime? lastPeriod,
    DateTime? estimatedDueDate,
    int? heightCm,
    double? startingWeightKg,
  }) async {
    final profileName = name.trim();
    if (profileName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    permissionsOnboardingSeen = true;
    profile = UserProfile(
      name: profileName,
      goals: goals.isEmpty ? {TrackingGoal.cycle} : goals,
      typicalCycleLength: cycleLength,
      periodLength: periodLength,
      lastPeriodStart: lastPeriod,
      estimatedDueDate: estimatedDueDate,
    );
    maternalHeightCm = heightCm;
    if (startingWeightKg != null && startingWeightKg > 0) {
      maternalWeights.add(
        MaternalWeightEntry(
          id: '${DateTime.now().microsecondsSinceEpoch}-weight',
          date: _day(DateTime.now()),
          kilograms: startingWeightKg,
        ),
      );
    }
    if (lastPeriod != null && periods.isEmpty) {
      periods.add(
        PeriodEntry(
          start: _day(lastPeriod),
          end: _day(lastPeriod).add(Duration(days: (periodLength ?? 5) - 1)),
        ),
      );
    }
    await _save();
    notifyListeners();
  }

  Future<void> completePermissionsOnboarding() async {
    permissionsOnboardingSeen = true;
    await _save();
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() =>
      _reminders.requestNotificationPermission();

  Future<void> saveLog(DailyHealthLog log) async {
    logs[_dateKey(log.date)] = log;
    final summary = _symptomSummary(log);
    if (summary.isNotEmpty) {
      final savedAt = DateTime.now();
      symptomEntries.add(
        SymptomEntry(
          id: '${savedAt.microsecondsSinceEpoch}-symptom',
          createdAt: savedAt,
          summary: summary,
        ),
      );
    }
    await _save();
    notifyListeners();
  }

  Future<void> quickCheckIn(String value) async {
    final now = DateTime.now();
    final old = logFor(now);
    const moods = {'Good', 'Calm', 'Emotional'};
    final symptoms = {...?old?.symptoms};
    if (!moods.contains(value)) symptoms.add(value);
    await saveLog(
      DailyHealthLog(
        date: now,
        painIntensity: old?.painIntensity,
        flow: old?.flow,
        symptoms: symptoms,
        mood: moods.contains(value) ? value : old?.mood,
        energy: old?.energy,
        notes: old?.notes,
        locations: old?.locations ?? const {},
        customFlow: old?.customFlow,
        customBody: old?.customBody,
        customPainLocation: old?.customPainLocation,
        customMood: old?.customMood,
      ),
    );
  }

  Future<void> addPeriodNote(DateTime date, String note) async {
    final text = note.trim();
    if (text.isEmpty) return;
    final createdAt = DateTime.now();
    periodNotes.add(
      PeriodNote(
        id: '${createdAt.microsecondsSinceEpoch}-period-note',
        date: _day(date),
        text: text,
        createdAt: createdAt,
      ),
    );
    await _save();
    notifyListeners();
  }

  Future<void> savePregnancyNote(DateTime date, String note) async {
    final key = _dateKey(date);
    if (note.trim().isEmpty) {
      pregnancyJournal.remove(key);
    } else {
      pregnancyJournal[key] = note.trim();
    }
    await _save();
    notifyListeners();
  }

  Future<void> addPregnancyNote(String note) async {
    final text = note.trim();
    if (text.isEmpty) return;
    final createdAt = DateTime.now();
    pregnancyNotes.add(
      PregnancyNote(
        id: '${createdAt.microsecondsSinceEpoch}-note',
        text: text,
        createdAt: createdAt,
      ),
    );
    pregnancyJournal[_dateKey(createdAt)] = text;
    await _save();
    notifyListeners();
  }

  Future<void> saveAppointment(PregnancyAppointment appointment) async {
    appointments.removeWhere((item) => item.id == appointment.id);
    appointments.add(appointment);
    await _save();
    await _reminders.schedule(appointment);
    notifyListeners();
  }

  Future<void> removeAppointment(String id) async {
    appointments.removeWhere((item) => item.id == id);
    await _save();
    await _reminders.cancel(id);
    notifyListeners();
  }

  Future<void> saveDoctorQuestion(DoctorQuestion question) async {
    doctorQuestions.removeWhere((item) => item.id == question.id);
    doctorQuestions.add(question);
    await _save();
    notifyListeners();
  }

  Future<void> removeDoctorQuestion(String id) async {
    doctorQuestions.removeWhere((item) => item.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> savePregnancyRecord(PregnancyRecord record) async {
    pregnancyRecords.removeWhere((item) => item.id == record.id);
    pregnancyRecords.add(record);
    await _save();
    notifyListeners();
  }

  Future<void> removePregnancyRecord(String id) async {
    pregnancyRecords.removeWhere((item) => item.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> removeLog(DateTime date) async {
    logs.remove(_dateKey(date));
    await _save();
    notifyListeners();
  }

  Future<void> startPeriod(DateTime date) async {
    final start = _day(date);
    periods.removeWhere((p) => _sameDay(p.start, start));
    periods.add(
      PeriodEntry(
        start: start,
        end: start.add(Duration(days: (profile?.periodLength ?? 5) - 1)),
      ),
    );
    await _save();
    notifyListeners();
  }

  Future<void> removePeriod(DateTime start) async {
    periods.removeWhere((p) => _sameDay(p.start, start));
    await _save();
    notifyListeners();
  }

  Future<void> updateGoals(Set<TrackingGoal> goals) async {
    final old = profile;
    if (old == null) return;
    profile = UserProfile(
      name: old.name,
      goals: goals,
      typicalCycleLength: old.typicalCycleLength,
      periodLength: old.periodLength,
      lastPeriodStart: old.lastPeriodStart,
      estimatedDueDate: old.estimatedDueDate,
      privateNotifications: old.privateNotifications,
      dietaryPreference: old.dietaryPreference,
      foodBudget: old.foodBudget,
      foodCuisine: old.foodCuisine,
    );
    await _save();
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    final updatedName = name.trim();
    if (updatedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    final old = profile;
    if (old == null) return;
    profile = UserProfile(
      name: updatedName,
      goals: old.goals,
      typicalCycleLength: old.typicalCycleLength,
      periodLength: old.periodLength,
      lastPeriodStart: old.lastPeriodStart,
      estimatedDueDate: old.estimatedDueDate,
      privateNotifications: old.privateNotifications,
      dietaryPreference: old.dietaryPreference,
      foodBudget: old.foodBudget,
      foodCuisine: old.foodCuisine,
    );
    await _save();
    notifyListeners();
  }

  Future<void> setPrivateNotifications(bool value) async {
    final old = profile;
    if (old == null) return;
    profile = UserProfile(
      name: old.name,
      goals: old.goals,
      typicalCycleLength: old.typicalCycleLength,
      periodLength: old.periodLength,
      lastPeriodStart: old.lastPeriodStart,
      estimatedDueDate: old.estimatedDueDate,
      privateNotifications: value,
      dietaryPreference: old.dietaryPreference,
      foodBudget: old.foodBudget,
      foodCuisine: old.foodCuisine,
    );
    await _save();
    notifyListeners();
  }

  Future<void> startPregnancy({
    required DateTime dueDate,
    int? heightCm,
    double? startingWeight,
    WeightUnit weightUnit = WeightUnit.kilograms,
  }) async {
    final old = profile;
    if (old == null) return;
    final wasPregnancyActive = old.pregnancyActive;
    profile = UserProfile(
      name: old.name,
      goals: {...old.goals, TrackingGoal.pregnancy},
      typicalCycleLength: old.typicalCycleLength,
      periodLength: old.periodLength,
      lastPeriodStart: old.lastPeriodStart,
      estimatedDueDate: dueDate,
      privateNotifications: old.privateNotifications,
      dietaryPreference: old.dietaryPreference,
      foodBudget: old.foodBudget,
      foodCuisine: old.foodCuisine,
    );
    if (heightCm != null && heightCm > 0) maternalHeightCm = heightCm;
    if (!wasPregnancyActive && startingWeight != null && startingWeight > 0) {
      maternalWeights.add(
        MaternalWeightEntry(
          id: '${DateTime.now().microsecondsSinceEpoch}-starting-weight',
          date: _day(DateTime.now()),
          kilograms: weightUnit.toKilograms(startingWeight),
          unit: weightUnit,
        ),
      );
      maternalWeights.sort((a, b) => a.date.compareTo(b.date));
    }
    await _save();
    notifyListeners();
  }

  /// Ends the active pregnancy timeline while keeping prior private entries.
  /// Cycle/period tracking is available again after this update.
  Future<void> recordBirth() async {
    final old = profile;
    if (old == null || !old.pregnancyActive) return;
    final goals = {...old.goals}..remove(TrackingGoal.pregnancy);
    if (goals.isEmpty) goals.add(TrackingGoal.cycle);
    profile = UserProfile(
      name: old.name,
      goals: goals,
      typicalCycleLength: old.typicalCycleLength,
      periodLength: old.periodLength,
      lastPeriodStart: old.lastPeriodStart,
      estimatedDueDate: null,
      privateNotifications: old.privateNotifications,
      dietaryPreference: old.dietaryPreference,
      foodBudget: old.foodBudget,
      foodCuisine: old.foodCuisine,
    );
    await _save();
    notifyListeners();
  }

  Future<void> addMaternalWeight(
    double kilograms,
    WeightUnit unit, {
    DateTime? date,
  }) async {
    if (kilograms <= 0) return;
    final entryDate = _day(date ?? DateTime.now());
    maternalWeights.add(
      MaternalWeightEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}-weight',
        date: entryDate,
        kilograms: kilograms,
        unit: unit,
      ),
    );
    maternalWeights.sort((a, b) => a.date.compareTo(b.date));
    await _save();
    notifyListeners();
  }

  Future<void> updateMaternalWeight({
    required String id,
    required double kilograms,
    required DateTime date,
    required WeightUnit unit,
  }) async {
    if (kilograms <= 0) return;
    final index = maternalWeights.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    maternalWeights[index] = MaternalWeightEntry(
      id: id,
      date: _day(date),
      kilograms: kilograms,
      unit: unit,
    );
    maternalWeights.sort((a, b) => a.date.compareTo(b.date));
    await _save();
    notifyListeners();
  }

  Future<void> removeMaternalWeight(String id) async {
    maternalWeights.removeWhere((entry) => entry.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _save();
    notifyListeners();
  }

  Future<void> setFoodPreferences({
    required DietaryPreference dietaryPreference,
    required FoodBudget foodBudget,
    required FoodCuisine foodCuisine,
  }) async {
    final old = profile;
    if (old == null) return;
    profile = UserProfile(
      name: old.name,
      goals: old.goals,
      typicalCycleLength: old.typicalCycleLength,
      periodLength: old.periodLength,
      lastPeriodStart: old.lastPeriodStart,
      estimatedDueDate: old.estimatedDueDate,
      privateNotifications: old.privateNotifications,
      dietaryPreference: dietaryPreference,
      foodBudget: foodBudget,
      foodCuisine: foodCuisine,
    );
    await _save();
    notifyListeners();
  }

  Future<void> deleteAllData() async {
    profile = null;
    periods.clear();
    logs.clear();
    periodNotes.clear();
    pregnancyJournal.clear();
    pregnancyNotes.clear();
    symptomEntries.clear();
    appointments.clear();
    doctorQuestions.clear();
    pregnancyRecords.clear();
    maternalWeights.clear();
    maternalHeightCm = null;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode({
        'dark': darkMode,
        'permissionsOnboardingSeen': permissionsOnboardingSeen,
        'maternalHeightCm': maternalHeightCm,
        'maternalWeights': maternalWeights
            .map(
              (entry) => {
                'id': entry.id,
                'date': entry.date.toIso8601String(),
                'kilograms': entry.kilograms,
                'unit': entry.unit.name,
              },
            )
            .toList(),
        'profile': profile == null
            ? null
            : {
                'name': profile!.name,
                'goals': profile!.goals.map((x) => x.name).toList(),
                'cycle': profile!.typicalCycleLength,
                'period': profile!.periodLength,
                'last': profile!.lastPeriodStart?.toIso8601String(),
                'due': profile!.estimatedDueDate?.toIso8601String(),
                'privateNotifications': profile!.privateNotifications,
                'dietaryPreference': profile!.dietaryPreference.name,
                'foodBudget': profile!.foodBudget.name,
                'foodCuisine': profile!.foodCuisine.name,
              },
        'periods': periods
            .map(
              (p) => {
                'start': p.start.toIso8601String(),
                'end': p.end.toIso8601String(),
              },
            )
            .toList(),
        'logs': logs.values
            .map(
              (l) => {
                'date': l.date.toIso8601String(),
                'pain': l.painIntensity,
                'flow': l.flow?.name,
                'symptoms': l.symptoms.toList(),
                'mood': l.mood,
                'energy': l.energy,
                'notes': l.notes,
                'locations': l.locations.map((item) => item.name).toList(),
                'customFlow': l.customFlow,
                'customBody': l.customBody,
                'customPainLocation': l.customPainLocation,
                'customMood': l.customMood,
              },
            )
            .toList(),
        'periodNotes': periodNotes
            .map(
              (note) => {
                'id': note.id,
                'date': note.date.toIso8601String(),
                'text': note.text,
                'createdAt': note.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'pregnancyJournal': pregnancyJournal,
        'pregnancyNotes': pregnancyNotes
            .map(
              (item) => {
                'id': item.id,
                'text': item.text,
                'createdAt': item.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'symptomEntries': symptomEntries
            .map(
              (item) => {
                'id': item.id,
                'createdAt': item.createdAt.toIso8601String(),
                'summary': item.summary,
              },
            )
            .toList(),
        'appointments': appointments
            .map(
              (item) => {
                'id': item.id,
                'type': item.type.name,
                'dateTime': item.dateTime.toIso8601String(),
                'status': item.status.name,
                'doctor': item.doctorName,
                'clinic': item.clinicName,
                'notes': item.notes,
                'reminderAt': item.reminderAt?.toIso8601String(),
                'reminderMessage': item.reminderMessage,
              },
            )
            .toList(),
        'doctorQuestions': doctorQuestions
            .map(
              (item) => {
                'id': item.id,
                'text': item.text,
                'createdAt': item.createdAt.toIso8601String(),
                'discussed': item.discussed,
                'appointmentId': item.appointmentId,
              },
            )
            .toList(),
        'pregnancyRecords': pregnancyRecords
            .map(
              (item) => {
                'id': item.id,
                'title': item.title,
                'date': item.date.toIso8601String(),
                'createdAt': item.createdAt.toIso8601String(),
                'doctorName': item.doctorName,
                'clinicName': item.clinicName,
                'note': item.note,
                'attachmentPaths': item.attachmentPaths,
              },
            )
            .toList(),
      }),
    );
  }

  static String _symptomSummary(DailyHealthLog log) {
    final details = <String>[];
    if (log.symptoms.isNotEmpty) details.add(log.symptoms.join(', '));
    if (log.mood != null) details.add('Mood: ${log.mood}');
    if (log.painIntensity != null) {
      details.add('Discomfort: ${log.painIntensity}/10');
    }
    if (log.flow != null) details.add('Flow: ${log.flow!.name}');
    if (log.locations.isNotEmpty) {
      details.add(
        'Location: ${log.locations.map((item) => item.name).join(', ')}',
      );
    }
    if (log.customBody != null && log.customBody!.isNotEmpty) {
      details.add(log.customBody!);
    }
    if (log.customPainLocation != null && log.customPainLocation!.isNotEmpty) {
      details.add(log.customPainLocation!);
    }
    if (log.notes != null && log.notes!.isNotEmpty) details.add(log.notes!);
    return details.join('\n');
  }

  void _restore(Map<String, dynamic> state) {
    darkMode = state['dark'] as bool? ?? false;
    permissionsOnboardingSeen =
        state['permissionsOnboardingSeen'] as bool? ?? false;
    maternalHeightCm = state['maternalHeightCm'] as int?;
    final raw = state['profile'];
    if (raw is Map) {
      profile = UserProfile(
        name: raw['name'] as String? ?? 'You',
        goals: (raw['goals'] as List? ?? [])
            .map((x) => TrackingGoal.values.byName(x as String))
            .toSet(),
        typicalCycleLength: raw['cycle'] as int?,
        periodLength: raw['period'] as int?,
        lastPeriodStart: raw['last'] == null
            ? null
            : DateTime.parse(raw['last'] as String),
        estimatedDueDate: raw['due'] == null
            ? null
            : DateTime.parse(raw['due'] as String),
        privateNotifications: raw['privateNotifications'] as bool? ?? true,
        dietaryPreference: raw['dietaryPreference'] == null
            ? DietaryPreference.none
            : DietaryPreference.values.byName(
                raw['dietaryPreference'] as String,
              ),
        foodBudget: raw['foodBudget'] == null
            ? FoodBudget.standard
            : FoodBudget.values.byName(raw['foodBudget'] as String),
        foodCuisine: raw['foodCuisine'] == null
            ? FoodCuisine.any
            : FoodCuisine.values.byName(raw['foodCuisine'] as String),
      );
    }
    for (final rawPeriod in (state['periods'] as List? ?? [])) {
      final item = rawPeriod as Map;
      periods.add(
        PeriodEntry(
          start: DateTime.parse(item['start'] as String),
          end: DateTime.parse(item['end'] as String),
        ),
      );
    }
    for (final rawLog in (state['logs'] as List? ?? [])) {
      final item = rawLog as Map;
      final date = DateTime.parse(item['date'] as String);
      logs[_dateKey(date)] = DailyHealthLog(
        date: date,
        painIntensity: item['pain'] as int?,
        flow: item['flow'] == null
            ? null
            : FlowLevel.values.byName(item['flow'] as String),
        symptoms: (item['symptoms'] as List? ?? []).cast<String>().toSet(),
        mood: item['mood'] as String?,
        energy: item['energy'] as String?,
        notes: item['notes'] as String?,
        locations: (item['locations'] as List? ?? [])
            .map((value) => PainLocation.values.byName(value as String))
            .toSet(),
        customFlow: item['customFlow'] as String?,
        customBody: item['customBody'] as String?,
        customPainLocation: item['customPainLocation'] as String?,
        customMood: item['customMood'] as String?,
      );
    }
    final savedSymptoms = state['symptomEntries'];
    if (savedSymptoms is List) {
      for (final rawEntry in savedSymptoms) {
        final item = rawEntry as Map;
        symptomEntries.add(
          SymptomEntry(
            id: item['id'] as String,
            createdAt: DateTime.parse(item['createdAt'] as String),
            summary: item['summary'] as String,
          ),
        );
      }
    } else {
      for (final log in logs.values) {
        final summary = _symptomSummary(log);
        if (summary.isNotEmpty) {
          symptomEntries.add(
            SymptomEntry(
              id: '${_dateKey(log.date)}-migrated-symptom',
              createdAt: log.date,
              summary: summary,
            ),
          );
        }
      }
    }
    final savedPeriodNotes = state['periodNotes'];
    if (savedPeriodNotes is List) {
      for (final rawNote in savedPeriodNotes) {
        final item = rawNote as Map;
        periodNotes.add(
          PeriodNote(
            id: item['id'] as String,
            date: DateTime.parse(item['date'] as String),
            text: item['text'] as String,
            createdAt: DateTime.parse(item['createdAt'] as String),
          ),
        );
      }
    } else if (savedPeriodNotes is Map) {
      for (final entry in savedPeriodNotes.entries) {
        if (entry.value is String) {
          final parts = entry.key.toString().split('-');
          if (parts.length != 3) continue;
          final date = DateTime.tryParse(
            '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}',
          );
          if (date == null) continue;
          periodNotes.add(
            PeriodNote(
              id: '${entry.key}-migrated-period-note',
              date: date,
              text: entry.value as String,
              createdAt: date,
            ),
          );
        }
      }
    }
    final journal = state['pregnancyJournal'];
    if (journal is Map) {
      for (final entry in journal.entries) {
        if (entry.value is String) {
          pregnancyJournal[entry.key.toString()] = entry.value as String;
        }
      }
    }
    final savedNotes = state['pregnancyNotes'];
    if (savedNotes is List) {
      for (final rawNote in savedNotes) {
        final item = rawNote as Map;
        pregnancyNotes.add(
          PregnancyNote(
            id: item['id'] as String,
            text: item['text'] as String,
            createdAt: DateTime.parse(item['createdAt'] as String),
          ),
        );
      }
    } else {
      // Preserve notes saved by earlier app versions as dated history items.
      for (final entry in pregnancyJournal.entries) {
        final parts = entry.key.split('-');
        if (parts.length != 3) continue;
        final date = DateTime.tryParse(
          '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}',
        );
        if (date != null) {
          pregnancyNotes.add(
            PregnancyNote(
              id: '${entry.key}-migrated-note',
              text: entry.value,
              createdAt: date,
            ),
          );
        }
      }
    }
    for (final rawAppointment in (state['appointments'] as List? ?? [])) {
      final item = rawAppointment as Map;
      appointments.add(
        PregnancyAppointment(
          id: item['id'] as String,
          type: AppointmentType.values.byName(item['type'] as String),
          dateTime: DateTime.parse(item['dateTime'] as String),
          status: AppointmentStatus.values.byName(item['status'] as String),
          doctorName: item['doctor'] as String?,
          clinicName: item['clinic'] as String?,
          notes: item['notes'] as String?,
          reminderAt: item['reminderAt'] == null
              ? null
              : DateTime.parse(item['reminderAt'] as String),
          reminderMessage: item['reminderMessage'] as String?,
        ),
      );
    }
    for (final rawQuestion in (state['doctorQuestions'] as List? ?? [])) {
      final item = rawQuestion as Map;
      doctorQuestions.add(
        DoctorQuestion(
          id: item['id'] as String,
          text: item['text'] as String,
          createdAt: DateTime.parse(item['createdAt'] as String),
          discussed: item['discussed'] as bool? ?? false,
          appointmentId: item['appointmentId'] as String?,
        ),
      );
    }
    for (final rawRecord in (state['pregnancyRecords'] as List? ?? [])) {
      final item = rawRecord as Map;
      pregnancyRecords.add(
        PregnancyRecord(
          id: item['id'] as String,
          title: item['title'] as String,
          date: DateTime.parse(item['date'] as String),
          createdAt: DateTime.parse(item['createdAt'] as String),
          doctorName: item['doctorName'] as String?,
          clinicName: item['clinicName'] as String?,
          note: item['note'] as String?,
          attachmentPaths: (item['attachmentPaths'] as List? ?? [])
              .cast<String>(),
        ),
      );
    }
    for (final rawWeight in (state['maternalWeights'] as List? ?? [])) {
      final item = rawWeight as Map;
      final kilograms = (item['kilograms'] as num?)?.toDouble();
      if (kilograms == null || kilograms <= 0) continue;
      maternalWeights.add(
        MaternalWeightEntry(
          id: item['id'] as String? ?? '${item['date']}-migrated-weight',
          date: DateTime.parse(item['date'] as String),
          kilograms: kilograms,
          unit: WeightUnit.fromStorage(item['unit'] as String?),
        ),
      );
    }
    maternalWeights.sort((a, b) => a.date.compareTo(b.date));
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';
  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _sameDay(DateTime a, DateTime b) => _dateKey(a) == _dateKey(b);
}
