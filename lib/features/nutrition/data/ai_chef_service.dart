import 'dart:convert';

import '../../../core/ai/luna_ai_error_mapper.dart';
import '../../ai_agent/data/gemini_ai_data_source.dart';
import '../../ai_agent/domain/luna_message.dart';
import '../domain/ai_chef_models.dart';

class AiChefException implements Exception {
  const AiChefException(this.message);
  final String message;
}

class AiChefService {
  const AiChefService({LunaAiDataSource? dataSource})
    : _dataSource = dataSource;

  final LunaAiDataSource? _dataSource;

  Future<List<AiChefMeal>> generate(AiChefPreferences preferences) async {
    try {
      final raw =
          await (_dataSource ??
                  const SecureAiDataSource(
                    systemInstruction: _chefSafetyPrompt,
                  ))
              .generateReply(
                userMessage: buildPrompt(preferences),
                history: const [],
              );
      final decoded = jsonDecode(_jsonOnly(raw));
      if (decoded is! Map || decoded['meals'] is! List) {
        throw const AiChefException(
          'AI Chef did not return meal ideas. Please try again.',
        );
      }
      final meals = (decoded['meals'] as List)
          .whereType<Map>()
          .map((item) => AiChefMeal.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (meals.length < 3) {
        throw const AiChefException(
          'AI Chef did not return three meal ideas. Please try again.',
        );
      }
      return meals.take(3).toList();
    } on AiChefException {
      rethrow;
    } catch (error) {
      throw AiChefException(_chefErrorMessage(error));
    }
  }

  Future<String> reply({
    required String userMessage,
    required List<LunaMessage> history,
    required AiChefPreferences context,
  }) async {
    try {
      return await (_dataSource ??
              SecureAiDataSource(systemInstruction: _chefChatPrompt(context)))
          .generateReply(userMessage: userMessage, history: history);
    } on AiChefException {
      rethrow;
    } catch (error) {
      throw AiChefException(_chefErrorMessage(error));
    }
  }

  String buildPrompt(AiChefPreferences p) =>
      '''
Create exactly three distinct ${p.mealType.toLowerCase()} ideas.
Stage: ${p.stage.label}${p.pregnancyWeek == null ? '' : ', pregnancy week ${p.pregnancyWeek}'}.
Diet style: ${p.dietStyle}.
Requirements: ${_values(p.requirements)}.
Foods to avoid and allergies: ${p.avoid.trim().isEmpty ? 'none given' : p.avoid.trim()}.
Today's needs: ${_values(p.needs)}.
Cooking: ${p.time}, ${p.budget}, ${p.servings} serving(s), ${p.skill} skill.
Equipment: ${_values(p.equipment)}.
Cuisine: ${_values({...p.cuisines, if (p.customCuisine.trim().isNotEmpty) p.customCuisine.trim()})}.
Ingredients available: ${p.availableIngredients.trim().isEmpty ? 'none given' : p.availableIngredients.trim()}.

Never include any food or ingredient in Foods to avoid and allergies. Return JSON only, with this exact shape:
{"meals":[{"name":"","reason":"","time":"","servings":"","ingredients":[""],"steps":[""],"nutrition":"","warnings":[""]}]}
Use plain, general meal inspiration; nutrition is approximate. Include a brief pregnancy food-safety precaution in warnings whenever Stage is Pregnant.
''';

  String _values(Set<String> values) =>
      values.isEmpty ? 'none' : values.join(', ');
  String _jsonOnly(String raw) => raw
      .replaceFirst(RegExp(r'^```json\\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^```\\s*'), '')
      .replaceFirst(RegExp(r'\\s*```$'), '')
      .trim();

  String _chefErrorMessage(Object error) =>
      LunaAiErrorMapper.map(error).message.replaceFirst('Luna', 'AI Chef');
}

String _chefChatPrompt(AiChefPreferences preferences) =>
    '''
You are AI Chef, a warm, skilled, conversational food companion. Sound like an attentive personal chef chatting naturally at the kitchen counter: kind, encouraging, practical, and never clinical or robotic. You are AI, not a human; never claim personal experiences, credentials, or a physical kitchen. Do not lead with that limitation or a disclaimer. Say it plainly only if the person asks who you are.

Answer the person's actual food request first. When they ask what to eat, give a real meal idea rather than only general advice. For a meal or recipe request, normally include:
1. A warm, appetising meal name and why it suits what they asked for.
2. A realistic total time and a short ingredient list, with easy substitutions.
3. Three to five simple cooking steps.
4. One optional question that helps you personalise the next meal.

If the person mentions period discomfort, PMS, tiredness, nausea, bloating, or cramps, respond with empathy and then offer a comforting, nourishing meal or drink they can actually make. You may say food cannot promise to treat or cure pain, but make that one short sentence after the meal suggestion—not the opening or the whole response. Do not withhold meal inspiration just because a health-related word appears. If symptoms sound severe, sudden, or worrying, add one brief suggestion to contact a qualified healthcare professional.

Ask about ingredients, time, budget, dietary requirements, and what sounds comforting when useful. If those details are missing, make a reasonable, flexible suggestion instead of making the person do more work. Offer practical substitutions and cooking tips. Keep answers concise, warm, and easy to follow; use plain text without Markdown symbols.

Give general food inspiration only, not medical nutrition treatment. Do not claim food diagnoses, prevents, or cures symptoms. Do not recommend restrictive weight-loss diets during pregnancy. For allergies, eating disorders, serious symptoms, or medical dietary needs, advise speaking with a qualified healthcare professional.

Current stage provided by the user: ${preferences.stage.label}${preferences.pregnancyWeek == null ? '' : ', pregnancy week ${preferences.pregnancyWeek}'}. Do not infer or expose any other health data. If pregnant, avoid alcohol, raw or undercooked animal foods, unpasteurized dairy, and other known high-risk foods; briefly explain the relevant food-safety precaution. Respect every food to avoid that the user explicitly mentions.
''';

const _chefSafetyPrompt = '''
You are AI Chef, a warm, practical meal-inspiration assistant in a women's-health app. Give three complete, appetising meal ideas with ingredients and simple steps. Answer the person's food request first, including comfort-food requests connected to periods or PMS. Food cannot promise to cure symptoms, but do not lead with a refusal or with medical language. Respect every listed allergy and food to avoid; if uncertain, state the uncertainty in warnings and suggest a qualified healthcare professional. Do not recommend restrictive weight-loss diets during pregnancy. During pregnancy avoid alcohol, raw or undercooked animal foods, unpasteurized dairy, and high-risk foods; explain the relevant precaution briefly. Never call yourself a doctor or a human chef.
''';
