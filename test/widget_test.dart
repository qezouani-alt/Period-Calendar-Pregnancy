import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period/app/app.dart';
import 'package:period/features/cycle/domain/cycle_prediction.dart';
import 'package:period/features/shared/domain/health_mode_service.dart';
import 'package:period/features/shared/domain/health_models.dart';
import 'package:period/features/pregnancy/domain/weekly_pregnancy_information.dart';
import 'package:period/features/pregnancy/presentation/pregnancy_hub.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('pregnancy mode overrides a recorded period day', () {
    final today = DateTime(2026, 9, 6);
    final context = const HealthModeService().resolve(
      profile: UserProfile(
        name: 'Maya',
        goals: {TrackingGoal.pregnancy},
        estimatedDueDate: DateTime(2027, 3, 25),
      ),
      periods: [
        PeriodEntry(start: today, end: today.add(const Duration(days: 4))),
      ],
      date: today,
    );
    expect(context.mode, ActiveHealthMode.pregnancyActive);
    expect(context.periodDay, isNull);
  });

  test('one period with cycle details creates future cycle forecasts', () {
    final prediction = const CyclePredictionEngine().estimate(
      periods: [
        PeriodEntry(start: DateTime(2026, 9, 7), end: DateTime(2026, 9, 11)),
      ],
      typicalPeriodLength: 5,
    );
    expect(prediction.futureCycles, isNotEmpty);
    expect(prediction.futureCycles.first.periodStart, DateTime(2026, 10, 5));
    expect(prediction.futureCycles.length, greaterThanOrEqualTo(24));
    expect(prediction.futureCycles[1].periodStart, DateTime(2026, 11, 2));
  });

  test('weekly pregnancy information is stage-aware', () {
    final weekEleven = PregnancyWeeklyInformation.forWeek(11);
    final weekThirty = PregnancyWeeklyInformation.forWeek(30);

    expect(weekEleven.baby, contains('Eyelids remain closed'));
    expect(weekThirty.baby, contains('brain and lungs'));
    expect(weekEleven.careFocus, isNot(weekThirty.careFocus));
  });

  testWidgets('first launch requires a profile name', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LunaApp(launchDuration: Duration.zero));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Continue').last);
    await tester.pump();

    expect(find.text('Enter your name to continue.'), findsOneWidget);
    expect(find.textContaining('What should we'), findsOneWidget);
  });

  testWidgets('first launch completes without requiring cycle details', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LunaApp(launchDuration: Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('What should we'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Maya');
    for (var step = 0; step < 6; step++) {
      await tester.tap(find.text('Continue').last);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.tap(find.text('Start my journey'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Good morning'), findsOneWidget);
    expect(find.text('Tap to allow'), findsNothing);
    expect(
      find.text('A few permissions\nfor your private space.'),
      findsNothing,
    );
  });

  testWidgets('delete all data closes settings and returns to onboarding', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('period-delete-test');
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pathChannel,
      (_) async => directory.path,
    );
    addTearDown(() async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, null);
      directory.deleteSync(recursive: true);
    });
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LunaApp(launchDuration: Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField), 'Maya');
    for (var step = 0; step < 6; step++) {
      await tester.tap(find.text('Continue').last);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.tap(find.text('Start my journey'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete all data'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Delete all data'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Delete'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('What should we'), findsOneWidget);
    expect(find.text('Delete all locally saved data?'), findsNothing);
    expect(find.text('Your profile'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    final saved = jsonDecode(preferences.getString('luna_state_v1')!) as Map;
    expect(saved['profile'], isNull);
  });

  testWidgets('pregnancy setup accepts every week without an exception', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LunaApp(launchDuration: Duration.zero));
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), 'Maya');
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Track pregnancy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, I am pregnant'));
    await tester.pumpAndSettle();

    for (var week = 0; week <= 42; week++) {
      final weekPicker = tester.widget<Slider>(find.byType(Slider).first);
      weekPicker.onChanged!(week.toDouble());
      await tester.pump();
      expect(
        tester.widget<Slider>(find.byType(Slider).first).value,
        week.toDouble(),
      );
    }
  });

  testWidgets('week 37 pregnancy hub builds the birth action safely', (
    tester,
  ) async {
    final profile = UserProfile(
      name: 'Maya',
      goals: {TrackingGoal.pregnancy},
      estimatedDueDate: DateTime.now().add(const Duration(days: 21)),
    );
    final context = const HealthModeService().resolve(
      profile: profile,
      periods: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PregnancyHub(
            profile: profile,
            appointments: const [],
            maternalWeights: const [],
            onSetup: () {},
            onTrack: () {},
            onSymptoms: () {},
            onWriteNote: () {},
            onRecords: () {},
            healthContext: context,
            onQuickCheckIn: (_) {},
            onReminders: () {},
            onAddMaternalWeight: (_, _) async {},
            onUpdateMaternalWeight:
                ({
                  required id,
                  required kilograms,
                  required date,
                  required unit,
                }) async {},
            onRemoveMaternalWeight: (_) async {},
            onRecordBirth: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('When you are ready'), findsOneWidget);
    expect(find.text('I gave birth'), findsOneWidget);
  });

  testWidgets('saving weight keeps its controller alive during sheet dismissal', (
    tester,
  ) async {
    final profile = UserProfile(
      name: 'Maya',
      goals: {TrackingGoal.pregnancy},
      estimatedDueDate: DateTime.now().add(const Duration(days: 21)),
    );
    final context = const HealthModeService().resolve(
      profile: profile,
      periods: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PregnancyHub(
            profile: profile,
            appointments: const [],
            maternalWeights: const [],
            onSetup: () {},
            onTrack: () {},
            onSymptoms: () {},
            onWriteNote: () {},
            onRecords: () {},
            healthContext: context,
            onQuickCheckIn: (_) {},
            onReminders: () {},
            onAddMaternalWeight: (_, _) async {},
            onUpdateMaternalWeight:
                ({
                  required id,
                  required kilograms,
                  required date,
                  required unit,
                }) async {},
            onRemoveMaternalWeight: (_) async {},
            onRecordBirth: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Weight insights'), 250);
    await tester.tap(find.text('Weight insights'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add today’s weight'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '65');
    await tester.ensureVisible(find.text('Add today’s weight'));
    await tester.tap(find.text('Add today’s weight'));
    // Rebuild while the closing route still contains the text field.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pregnancy setup keeps its text fields alive while week changes',
    (tester) async {
      final dueDate = DateTime.now().add(const Duration(days: 196));
      SharedPreferences.setMockInitialValues({
        'luna_state_v1': jsonEncode({
          'dark': false,
          'maternalHeightCm': null,
          'maternalWeights': [],
          'profile': {
            'name': 'Maya',
            'goals': ['pregnancy'],
            'cycle': null,
            'period': null,
            'last': null,
            'due': dueDate.toIso8601String(),
            'dietaryPreference': 'none',
            'foodBudget': 'standard',
            'foodCuisine': 'any',
          },
          'periods': [],
          'logs': [],
        }),
      });
      await tester.pumpWidget(const LunaApp(launchDuration: Duration.zero));
      await tester.pumpAndSettle();

      await tester.tap(find.text("I'm pregnant"));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('PREGNANCY AGE'));
      await tester.pumpAndSettle();

      tester.widget<Slider>(find.byType(Slider).first).onChanged!(37.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TextField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
