import 'package:flutter/material.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';
import '../../shared/domain/health_mode_service.dart';

Future<void> showFoodGuideSheet(
  BuildContext context, {
  required UserProfile profile,
  required DailyHealthLog? log,
  required ActiveHealthContext healthContext,
  required Future<void> Function({
    required DietaryPreference dietaryPreference,
    required FoodBudget foodBudget,
    required FoodCuisine foodCuisine,
  })
  onSavePreferences,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _FoodGuideSheet(
    profile: profile,
    log: log,
    healthContext: healthContext,
    onSavePreferences: onSavePreferences,
  ),
);

class _FoodGuideSheet extends StatefulWidget {
  const _FoodGuideSheet({
    required this.profile,
    required this.log,
    required this.onSavePreferences,
    required this.healthContext,
  });
  final UserProfile profile;
  final DailyHealthLog? log;
  final Future<void> Function({
    required DietaryPreference dietaryPreference,
    required FoodBudget foodBudget,
    required FoodCuisine foodCuisine,
  })
  onSavePreferences;
  final ActiveHealthContext healthContext;

  @override
  State<_FoodGuideSheet> createState() => _FoodGuideSheetState();
}

class _FoodGuideSheetState extends State<_FoodGuideSheet> {
  late DietaryPreference dietary = widget.profile.dietaryPreference;
  late FoodBudget budget = widget.profile.foodBudget;
  late FoodCuisine cuisine = widget.profile.foodCuisine;
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final suggestion = _suggestion(
      widget.healthContext.mode,
      widget.log,
      dietary,
      cuisine,
    );
    return DraggableScrollableSheet(
      initialChildSize: .72,
      minChildSize: .48,
      maxChildSize: .92,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.xxl,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              'Food for today',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Thoughtful meal ideas for your current context. Food supports everyday wellbeing but does not diagnose or treat symptoms.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpace.lg),
            SurfaceCard(
              color: AppColors.warning.withValues(alpha: .10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.restaurant_outlined,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        suggestion.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    suggestion.detail,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    suggestion.note,
                    style: const TextStyle(
                      color: AppColors.plum,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.healthContext.isPregnancy) ...[
              const SizedBox(height: AppSpace.md),
              SurfaceCard(
                color: AppColors.pregnancy.withValues(alpha: .10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pregnancy food safety',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose pasteurized dairy and thoroughly cooked animal foods; avoid alcohol and check local guidance about high-mercury fish and caffeine. If you feel unwell or are concerned about something you ate, contact a healthcare professional.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpace.xl),
            Text(
              'Your preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpace.sm),
            _ChoiceGroup<DietaryPreference>(
              label: 'Diet style',
              value: dietary,
              values: DietaryPreference.values
                  .where((item) => item != DietaryPreference.other)
                  .toList(),
              name: _dietLabel,
              onChanged: (value) => setState(() => dietary = value),
            ),
            const SizedBox(height: AppSpace.md),
            _ChoiceGroup<FoodBudget>(
              label: 'Budget',
              value: budget,
              values: FoodBudget.values,
              name: _budgetLabel,
              onChanged: (value) => setState(() => budget = value),
            ),
            const SizedBox(height: AppSpace.md),
            _ChoiceGroup<FoodCuisine>(
              label: 'Cuisine',
              value: cuisine,
              values: FoodCuisine.values
                  .where((item) => item != FoodCuisine.other)
                  .toList(),
              name: _cuisineLabel,
              onChanged: (value) => setState(() => cuisine = value),
            ),
            const SizedBox(height: AppSpace.lg),
            PrimaryButton(
              label: saving ? 'Saving...' : 'Save food preferences',
              icon: Icons.check,
              onPressed: saving
                  ? () {}
                  : () async {
                      setState(() => saving = true);
                      await widget.onSavePreferences(
                        dietaryPreference: dietary,
                        foodBudget: budget,
                        foodCuisine: cuisine,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.label,
    required this.value,
    required this.values,
    required this.name,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) name;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: values
            .map(
              (item) => ChoiceChip(
                label: Text(name(item)),
                selected: item == value,
                onSelected: (_) => onChanged(item),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class _MealSuggestion {
  const _MealSuggestion(this.title, this.detail, this.note);
  final String title;
  final String detail;
  final String note;
}

_MealSuggestion _suggestion(
  ActiveHealthMode mode,
  DailyHealthLog? log,
  DietaryPreference dietary,
  FoodCuisine cuisine,
) {
  final vegan =
      dietary == DietaryPreference.vegan ||
      dietary == DietaryPreference.vegetarian;
  final moroccan = cuisine == FoodCuisine.moroccan;
  if (mode == ActiveHealthMode.pregnancyActive &&
      log?.symptoms.contains('Nauseous') == true) {
    return const _MealSuggestion(
      'Gentle, small meal',
      'Try plain toast or rice with a small fruit portion and water, in the quantities that feel manageable to you.',
      'Small, regular meals may be easier when nausea is present. This is general education, not individual medical advice.',
    );
  }
  if (mode == ActiveHealthMode.pregnancyActive) {
    return _MealSuggestion(
      moroccan
          ? 'Vegetable couscous bowl'
          : 'Balanced grain and vegetable bowl',
      vegan
          ? 'Whole grains, chickpeas or lentils, colourful vegetables, and a fruit side make a practical balanced meal.'
          : 'Whole grains, vegetables, a thoroughly cooked protein, and fruit make a practical balanced meal.',
      'Choose foods prepared safely and follow the guidance of your maternity care team for your needs.',
    );
  }
  if (log?.painIntensity != null && log!.painIntensity! >= 5) {
    return _MealSuggestion(
      moroccan ? 'Warm lentil soup' : 'Warm lentil and vegetable soup',
      'A warm, simple meal with lentils, vegetables, and water or herbal tea can be a comforting option on a painful day.',
      'It may support comfort as part of a balanced diet; it is not a treatment for cramps.',
    );
  }
  if (mode == ActiveHealthMode.fertilityTracking) {
    return const _MealSuggestion(
      'Colourful balanced plate',
      'Pair vegetables or fruit with protein, whole grains, and a drink you enjoy for steady everyday nourishment.',
      'This supports general wellbeing and does not predict or guarantee fertility or ovulation.',
    );
  }
  return _MealSuggestion(
    moroccan ? 'Harira-inspired vegetable soup' : 'Vegetable and grain bowl',
    vegan
        ? 'Try vegetables, beans or lentils, and a whole grain with water or a warm drink.'
        : 'Try vegetables, a protein you enjoy, and a whole grain with water or a warm drink.',
    'Choose what feels nourishing and accessible today; no food needs to be perfect.',
  );
}

String _dietLabel(DietaryPreference value) => switch (value) {
  DietaryPreference.none => 'No preference',
  DietaryPreference.halal => 'Halal',
  DietaryPreference.vegetarian => 'Vegetarian',
  DietaryPreference.vegan => 'Vegan',
  DietaryPreference.pescatarian => 'Pescatarian',
  DietaryPreference.glutenFree => 'Gluten-free',
  DietaryPreference.lactoseFree => 'Lactose-free',
  DietaryPreference.other => 'Other',
};

String _budgetLabel(FoodBudget value) => switch (value) {
  FoodBudget.budgetFriendly => 'Budget-friendly',
  FoodBudget.standard => 'Standard',
  FoodBudget.premium => 'Premium',
};

String _cuisineLabel(FoodCuisine value) => switch (value) {
  FoodCuisine.any => 'Any cuisine',
  FoodCuisine.moroccan => 'Moroccan',
  FoodCuisine.mediterranean => 'Mediterranean',
  FoodCuisine.middleEastern => 'Middle Eastern',
  FoodCuisine.european => 'European',
  FoodCuisine.asian => 'Asian',
  FoodCuisine.other => 'Other',
};
