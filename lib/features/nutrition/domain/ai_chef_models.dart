import 'dart:convert';

enum AiChefStage { period, tryingToConceive, pregnant, postpartum, wellness }

extension AiChefStageLabel on AiChefStage {
  String get label => switch (this) {
    AiChefStage.period => 'Period',
    AiChefStage.tryingToConceive => 'Trying to conceive',
    AiChefStage.pregnant => 'Pregnant',
    AiChefStage.postpartum => 'Postpartum',
    AiChefStage.wellness => 'General wellness',
  };
}

class AiChefPreferences {
  const AiChefPreferences({
    required this.stage,
    required this.dietStyle,
    required this.requirements,
    required this.avoid,
    required this.needs,
    required this.mealType,
    required this.time,
    required this.budget,
    required this.servings,
    required this.skill,
    required this.equipment,
    required this.cuisines,
    required this.customCuisine,
    required this.availableIngredients,
    this.pregnancyWeek,
  });

  factory AiChefPreferences.defaults(AiChefStage stage, {int? pregnancyWeek}) =>
      AiChefPreferences(
        stage: stage,
        pregnancyWeek: pregnancyWeek,
        dietStyle: 'No preference',
        requirements: const {},
        avoid: '',
        needs: const {'Balanced meal'},
        mealType: 'Dinner',
        time: '20 minutes',
        budget: 'Standard',
        servings: '2',
        skill: 'Easy',
        equipment: const {'Stove'},
        cuisines: const {'Any cuisine'},
        customCuisine: '',
        availableIngredients: '',
      );

  factory AiChefPreferences.fromJson(
    Map<String, dynamic> json, {
    required AiChefStage fallbackStage,
    int? pregnancyWeek,
  }) => AiChefPreferences(
    stage: fallbackStage,
    pregnancyWeek: pregnancyWeek,
    dietStyle: json['dietStyle'] as String? ?? 'No preference',
    requirements: _stringSet(json['requirements']),
    avoid: json['avoid'] as String? ?? '',
    needs: _stringSet(json['needs']).isEmpty
        ? const {'Balanced meal'}
        : _stringSet(json['needs']),
    mealType: json['mealType'] as String? ?? 'Dinner',
    time: json['time'] as String? ?? '20 minutes',
    budget: json['budget'] as String? ?? 'Standard',
    servings: json['servings'] as String? ?? '2',
    skill: json['skill'] as String? ?? 'Easy',
    equipment: _stringSet(json['equipment']).isEmpty
        ? const {'Stove'}
        : _stringSet(json['equipment']),
    cuisines: _stringSet(json['cuisines']).isEmpty
        ? const {'Any cuisine'}
        : _stringSet(json['cuisines']),
    customCuisine: json['customCuisine'] as String? ?? '',
    availableIngredients: json['availableIngredients'] as String? ?? '',
  );

  final AiChefStage stage;
  final int? pregnancyWeek;
  final String dietStyle, avoid, mealType, time, budget, servings, skill;
  final Set<String> requirements, needs, equipment, cuisines;
  final String customCuisine, availableIngredients;

  Map<String, dynamic> toJson() => {
    'dietStyle': dietStyle,
    'requirements': requirements.toList(),
    'avoid': avoid,
    'needs': needs.toList(),
    'mealType': mealType,
    'time': time,
    'budget': budget,
    'servings': servings,
    'skill': skill,
    'equipment': equipment.toList(),
    'cuisines': cuisines.toList(),
    'customCuisine': customCuisine,
    'availableIngredients': availableIngredients,
  };

  AiChefPreferences copyWith({
    AiChefStage? stage,
    int? pregnancyWeek,
    String? dietStyle,
    Set<String>? requirements,
    String? avoid,
    Set<String>? needs,
    String? mealType,
    String? time,
    String? budget,
    String? servings,
    String? skill,
    Set<String>? equipment,
    Set<String>? cuisines,
    String? customCuisine,
    String? availableIngredients,
  }) => AiChefPreferences(
    stage: stage ?? this.stage,
    pregnancyWeek: pregnancyWeek ?? this.pregnancyWeek,
    dietStyle: dietStyle ?? this.dietStyle,
    requirements: requirements ?? this.requirements,
    avoid: avoid ?? this.avoid,
    needs: needs ?? this.needs,
    mealType: mealType ?? this.mealType,
    time: time ?? this.time,
    budget: budget ?? this.budget,
    servings: servings ?? this.servings,
    skill: skill ?? this.skill,
    equipment: equipment ?? this.equipment,
    cuisines: cuisines ?? this.cuisines,
    customCuisine: customCuisine ?? this.customCuisine,
    availableIngredients: availableIngredients ?? this.availableIngredients,
  );
}

class AiChefMeal {
  const AiChefMeal({
    required this.name,
    required this.reason,
    required this.time,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    required this.warnings,
  });

  factory AiChefMeal.fromJson(Map<String, dynamic> json) => AiChefMeal(
    name: json['name'] as String? ?? 'Meal idea',
    reason:
        json['reason'] as String? ?? 'A meal idea based on your selections.',
    time: json['time'] as String? ?? 'Time not provided',
    servings: json['servings'] as String? ?? 'Servings not provided',
    ingredients: _stringList(json['ingredients']),
    steps: _stringList(json['steps']),
    nutrition:
        json['nutrition'] as String? ?? 'Approximate nutrition not provided',
    warnings: _stringList(json['warnings']),
  );

  final String name, reason, time, servings, nutrition;
  final List<String> ingredients, steps, warnings;
  Map<String, dynamic> toJson() => {
    'name': name,
    'reason': reason,
    'time': time,
    'servings': servings,
    'ingredients': ingredients,
    'steps': steps,
    'nutrition': nutrition,
    'warnings': warnings,
  };
}

Set<String> _stringSet(Object? value) => _stringList(value).toSet();
List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().where((item) => item.trim().isNotEmpty).toList()
    : const [];

String chefMealsJson(List<AiChefMeal> meals) =>
    jsonEncode(meals.map((meal) => meal.toJson()).toList());
