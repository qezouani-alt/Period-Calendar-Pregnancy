import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period/features/nutrition/data/ai_chef_service.dart';
import 'package:period/features/nutrition/data/ai_chef_store.dart';
import 'package:period/features/nutrition/domain/ai_chef_models.dart';
import 'package:period/features/nutrition/presentation/ai_chef_page.dart';
import 'package:period/features/ai_agent/data/gemini_ai_data_source.dart';
import 'package:period/features/ai_agent/domain/luna_message.dart';
import 'package:period/features/shared/domain/health_mode_service.dart';
import 'package:period/features/shared/domain/health_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('AI Chef request includes pregnancy week and allergy exclusion', () {
    final preferences = AiChefPreferences.defaults(
      AiChefStage.pregnant,
      pregnancyWeek: 22,
    ).copyWith(avoid: 'peanuts, shellfish');

    final prompt = const AiChefService().buildPrompt(preferences);

    expect(prompt, contains('pregnancy week 22'));
    expect(prompt, contains('peanuts, shellfish'));
    expect(prompt, contains('Never include any food or ingredient'));
  });

  test('AI Chef stores preferences separately', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = AiChefPreferences.defaults(
      AiChefStage.period,
    ).copyWith(dietStyle: 'Vegetarian', needs: {'Iron-rich'});

    await AiChefStore().savePreferences(preferences);
    final saved = await AiChefStore().loadPreferences();

    expect(saved?['dietStyle'], 'Vegetarian');
    expect(saved?['needs'], ['Iron-rich']);
  });

  test(
    'AI Chef reports an unconfigured AI service before generating',
    () async {
      final service = AiChefService(
        dataSource: _ThrowingChefDataSource(
          const AiBackendException('AI_BACKEND_URL is not configured.'),
        ),
      );

      await expectLater(
        service.generate(AiChefPreferences.defaults(AiChefStage.wellness)),
        throwsA(
          isA<AiChefException>().having(
            (error) => error.message,
            'message',
            'AI service is not configured. Please contact support.',
          ),
        ),
      );
    },
  );

  test(
    'AI Chef chat reports an unconfigured AI service before replying',
    () async {
      final service = AiChefService(
        dataSource: _ThrowingChefDataSource(
          const AiBackendException('AI_BACKEND_URL is not configured.'),
        ),
      );

      await expectLater(
        service.reply(
          userMessage: 'What can I make with chickpeas?',
          history: const [],
          context: AiChefPreferences.defaults(AiChefStage.wellness),
        ),
        throwsA(
          isA<AiChefException>().having(
            (error) => error.message,
            'message',
            'AI service is not configured. Please contact support.',
          ),
        ),
      );
    },
  );

  test(
    'AI Chef reports a quota response with the shared Luna wording',
    () async {
      final service = AiChefService(
        dataSource: _ThrowingChefDataSource(
          const AiBackendException('Request rejected.', statusCode: 429),
        ),
      );

      await expectLater(
        service.reply(
          userMessage: 'How can I use chickpeas?',
          history: const [],
          context: AiChefPreferences.defaults(AiChefStage.wellness),
        ),
        throwsA(
          isA<AiChefException>().having(
            (error) => error.message,
            'message',
            'AI limit reached for now. Please try later.',
          ),
        ),
      );
    },
  );

  testWidgets('AI Chef opens as a food conversation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: AiChefPage(
          profile: const UserProfile(name: 'Maya', goals: {TrackingGoal.cycle}),
          healthContext: ActiveHealthContext(
            mode: ActiveHealthMode.cycleTracking,
            today: DateTime(2026, 9, 8),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Chef'), findsWidgets);
    expect(
      find.textContaining('Tell me what you feel like eating'),
      findsOneWidget,
    );
    expect(find.text('How can I use chickpeas?'), findsOneWidget);
  });
}

class _ThrowingChefDataSource implements LunaAiDataSource {
  const _ThrowingChefDataSource(this.error);

  final Object error;

  @override
  Future<String> generateReply({
    required String userMessage,
    required List<LunaMessage> history,
  }) async {
    throw error;
  }
}
