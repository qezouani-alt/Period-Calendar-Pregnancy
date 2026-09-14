import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_chef_models.dart';

class AiChefStore {
  static const _preferencesKey = 'ai_chef_preferences_v1';
  static const _savedMealsKey = 'ai_chef_saved_meals_v1';

  Future<Map<String, dynamic>?> loadPreferences() async {
    final value = (await SharedPreferences.getInstance()).getString(
      _preferencesKey,
    );
    if (value == null) return null;
    final decoded = jsonDecode(value);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> savePreferences(AiChefPreferences preferences) async {
    await (await SharedPreferences.getInstance()).setString(
      _preferencesKey,
      jsonEncode(preferences.toJson()),
    );
  }

  Future<void> saveMeal(AiChefMeal meal) async {
    final preferences = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(preferences.getString(_savedMealsKey) ?? '[]') as List;
    final exists = saved.whereType<Map>().any(
      (item) => item['name'] == meal.name,
    );
    if (!exists) saved.add(meal.toJson());
    await preferences.setString(_savedMealsKey, jsonEncode(saved));
  }
}
