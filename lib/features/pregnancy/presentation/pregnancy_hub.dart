import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';
import '../../shared/domain/health_mode_service.dart';
import '../domain/daily_pregnancy_advice.dart';
import '../domain/pregnancy_timeline.dart';
import '../domain/weekly_pregnancy_information.dart';

class PregnancyHub extends StatelessWidget {
  const PregnancyHub({
    super.key,
    required this.profile,
    required this.appointments,
    required this.maternalWeights,
    required this.onSetup,
    required this.onTrack,
    required this.onSymptoms,
    required this.onWriteNote,
    required this.onRecords,
    required this.healthContext,
    required this.onQuickCheckIn,
    required this.onReminders,
    required this.onAddMaternalWeight,
    required this.onUpdateMaternalWeight,
    required this.onRemoveMaternalWeight,
    required this.onRecordBirth,
  });
  final UserProfile profile;
  final List<PregnancyAppointment> appointments;
  final List<MaternalWeightEntry> maternalWeights;
  final VoidCallback onSetup, onTrack, onSymptoms, onWriteNote, onRecords;
  final ActiveHealthContext healthContext;
  final ValueChanged<String> onQuickCheckIn;
  final VoidCallback onReminders;
  final Future<void> Function(double kilograms, WeightUnit unit)
  onAddMaternalWeight;
  final Future<void> Function({
    required String id,
    required double kilograms,
    required DateTime date,
    required WeightUnit unit,
  })
  onUpdateMaternalWeight;
  final Future<void> Function(String id) onRemoveMaternalWeight;
  final Future<void> Function() onRecordBirth;
  @override
  Widget build(BuildContext context) {
    final active = healthContext.isPregnancy;
    if (!active) return _SetupState(onStart: onSetup);
    final week = PregnancyTimeline.fromDueDate(profile.estimatedDueDate);
    final dailyAdvice = const DailyPregnancyAdvice().forDate(DateTime.now());
    final weeklyInformation = week == null
        ? null
        : PregnancyWeeklyInformation.forWeek(week.week);
    final reminderCount = appointments
        .where((item) => item.reminderAt != null)
        .length;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.lg,
            112,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Your pregnancy',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'A private space for the details you choose to keep.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.lg),
              _PregnancyHero(
                week: week,
                dueDate: profile.estimatedDueDate,
                onTap: onSetup,
              ),
              if (week != null && week.week >= 37) ...[
                const SizedBox(height: AppSpace.lg),
                _BirthActionCard(onPressed: onRecordBirth),
              ],
              const SizedBox(height: AppSpace.xl),
              SectionHeader(title: 'This week'),
              const SizedBox(height: AppSpace.sm),
              _WeeklyPregnancyCard(
                week: week,
                information: weeklyInformation,
                dailyAdvice: dailyAdvice,
              ),
              const SizedBox(height: AppSpace.xl),
              SectionHeader(title: 'Weight Tracker'),
              const SizedBox(height: AppSpace.sm),
              _MaternalWeightCard(
                week: week,
                entries: maternalWeights,
                onAdd: onAddMaternalWeight,
                onUpdate: onUpdateMaternalWeight,
                onRemove: onRemoveMaternalWeight,
              ),
              const SizedBox(height: AppSpace.xl),
              SectionHeader(title: 'Set a reminder'),
              const SizedBox(height: AppSpace.sm),
              SurfaceCard(
                onTap: onReminders,
                child: reminderCount == 0
                    ? Row(
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: AppColors.pregnancy,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No reminders saved',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Set a private reminder when you are ready.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.add_alert_outlined,
                            color: AppColors.berry,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.pregnancy,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$reminderCount saved ${reminderCount == 1 ? 'reminder' : 'reminders'}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  'Tap to review reminder details or set another.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpace.xl),
              SectionHeader(title: 'To tell the gynecologist'),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: _ClinicianAction(
                      icon: Icons.edit_note_outlined,
                      label: 'Note',
                      detail: 'View or add notes',
                      onTap: onWriteNote,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: _ClinicianAction(
                      icon: Icons.medical_information_outlined,
                      label: 'Symptoms',
                      detail: 'View or log symptoms',
                      onTap: onSymptoms,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              _DocumentsAction(onTap: onRecords),
              const SizedBox(height: AppSpace.xl),
              SectionHeader(
                title: 'How are you feeling today?',
                action: 'Log more',
                onAction: onTrack,
              ),
              const SizedBox(height: AppSpace.sm),
              SurfaceCard(
                color: AppColors.rose.withValues(alpha: .07),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpace.sm,
                  crossAxisSpacing: AppSpace.sm,
                  childAspectRatio: 2.65,
                  children:
                      [
                            'Good',
                            'Tired',
                            'Nauseous',
                            'Low energy',
                            'Calm',
                            'Uncomfortable',
                            'Headache',
                            'Dizzy',
                            'Anxious',
                            'Low mood',
                            'Bloated',
                          ]
                          .map(
                            (item) => _FeelingOption(
                              label: item,
                              onTap: () => onQuickCheckIn(item),
                            ),
                          )
                          .toList(),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _BirthActionCard extends StatelessWidget {
  const _BirthActionCard({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    color: AppColors.rose.withValues(alpha: .2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_outline, color: AppColors.berry),
            const SizedBox(width: AppSpace.sm),
            Text(
              'When you are ready',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'After birth, you can end pregnancy tracking and return to your Period page. Your private pregnancy entries will stay saved.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpace.md),
        PrimaryButton(
          label: 'I gave birth',
          icon: Icons.favorite_rounded,
          onPressed: () => onPressed(),
        ),
      ],
    ),
  );
}

class _FeelingOption extends StatelessWidget {
  const _FeelingOption({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    color: Theme.of(context).colorScheme.surface,
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.favorite_rounded, size: 15, color: AppColors.berry),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.plum),
          ),
        ),
      ],
    ),
  );
}

class _SetupState extends StatelessWidget {
  const _SetupState({required this.onStart});
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.pregnant_woman_outlined,
            size: 38,
            color: AppColors.pregnancy,
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            'Your pregnancy',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'A private place for your timeline, appointments, symptoms, journal, memories, records, and questions for a clinician.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpace.xl),
          PrimaryButton(
            label: 'Start pregnancy tracking',
            icon: Icons.arrow_forward,
            onPressed: onStart,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Not now'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AdviceLine extends StatelessWidget {
  const _AdviceLine({
    required this.icon,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 19, color: AppColors.pregnancy),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 2),
            Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    ],
  );
}

class _MaternalWeightCard extends StatelessWidget {
  const _MaternalWeightCard({
    required this.week,
    required this.entries,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
  });

  final PregnancyWeek? week;
  final List<MaternalWeightEntry> entries;
  final Future<void> Function(double kilograms, WeightUnit unit) onAdd;
  final Future<void> Function({
    required String id,
    required double kilograms,
    required DateTime date,
    required WeightUnit unit,
  })
  onUpdate;
  final Future<void> Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final latest = entries.isEmpty ? null : entries.last;
    return SurfaceCard(
      onTap: () => _openEditor(context),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.pregnancy.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.monitor_weight_outlined,
              color: AppColors.pregnancy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weight insights',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  latest == null
                      ? 'Add your first private entry and view your trend here.'
                      : 'Latest: ${latest.weightInSelectedUnit.toStringAsFixed(1)} ${latest.unit.label} · view your trend and history.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final weight = TextEditingController();
    var view = _WeightInsightsView.overview;
    var unit = WeightUnit.kilograms;
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void showView(_WeightInsightsView selectedView) {
            setSheet(() => view = selectedView);
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .84,
            ),
            padding: EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              MediaQuery.viewInsetsOf(context).bottom +
                  MediaQuery.paddingOf(context).bottom +
                  AppSpace.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    view == _WeightInsightsView.overview
                        ? 'Weight insights'
                        : view == _WeightInsightsView.history
                        ? 'Weight history'
                        : 'Today’s weight',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  if (view == _WeightInsightsView.overview) ...[
                    Text(
                      'Your private weight trend, based only on the entries you choose to save.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpace.md),
                    _WeightTrendChart(entries: entries),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  showView(_WeightInsightsView.history),
                              icon: const Icon(Icons.history_outlined),
                              label: const Text('Weight history'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  showView(_WeightInsightsView.add),
                              icon: const Icon(Icons.add),
                              label: const Text('Add today’s weight'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (view == _WeightInsightsView.history) ...[
                    Text(
                      'Tap a saved entry to edit its date or weight, or remove it.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpace.md),
                    if (entries.isEmpty)
                      SurfaceCard(
                        color: AppColors.lavender.withValues(alpha: .14),
                        child: const Text(
                          'No weight history yet. Add your first private entry whenever you wish.',
                        ),
                      )
                    else
                      ...entries.reversed.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SurfaceCard(
                            onTap: () => _openEntryEditor(
                              context,
                              entry,
                              onChanged: () => setSheet(() {}),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.md,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.monitor_weight_outlined,
                                  color: AppColors.pregnancy,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  '${entry.weightInSelectedUnit.toStringAsFixed(1)} ${entry.unit.label}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpace.md),
                    TextButton.icon(
                      onPressed: () =>
                          setSheet(() => view = _WeightInsightsView.overview),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to weight insights'),
                    ),
                  ] else ...[
                    Text(
                      'Optional and private. Add today’s weight whenever it feels useful to you.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weight,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [_weightInputFormatter],
                            decoration: InputDecoration(
                              labelText: 'Your weight',
                              errorText: error,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 90,
                          child: DropdownButtonFormField<WeightUnit>(
                            initialValue: unit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                            ),
                            items: WeightUnit.values
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) setSheet(() => unit = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    PrimaryButton(
                      label: 'Add today’s weight',
                      onPressed: () async {
                        final kilograms = double.tryParse(
                          weight.text.trim().replaceAll(',', '.'),
                        );
                        if (kilograms == null || kilograms <= 0) {
                          setSheet(() => error = 'Enter a valid weight.');
                          return;
                        }
                        await onAdd(unit.toKilograms(kilograms), unit);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: AppSpace.md),
                    TextButton.icon(
                      onPressed: () =>
                          setSheet(() => view = _WeightInsightsView.overview),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to weight insights'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
    weight.dispose();
  }

  void _openEntryEditor(
    BuildContext context,
    MaternalWeightEntry entry, {
    required VoidCallback onChanged,
  }) {
    final weight = TextEditingController(
      text: entry.weightInSelectedUnit.toString(),
    );
    var date = entry.date;
    var unit = entry.unit;
    String? error;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit weight entry',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpace.md),
                SurfaceCard(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2010),
                      lastDate: DateTime.now(),
                      initialDate: date,
                    );
                    if (picked != null) setSheet(() => date = picked);
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_outlined,
                        color: AppColors.pregnancy,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_weightInputFormatter],
                        decoration: InputDecoration(
                          labelText: 'Your weight',
                          errorText: error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: DropdownButtonFormField<WeightUnit>(
                        initialValue: unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: WeightUnit.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setSheet(() => unit = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                PrimaryButton(
                  label: 'Save changes',
                  onPressed: () async {
                    final kilograms = double.tryParse(
                      weight.text.trim().replaceAll(',', '.'),
                    );
                    if (kilograms == null || kilograms <= 0) {
                      setSheet(() => error = 'Enter a valid weight.');
                      return;
                    }
                    await onUpdate(
                      id: entry.id,
                      kilograms: unit.toKilograms(kilograms),
                      date: date,
                      unit: unit,
                    );
                    onChanged();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        _confirmRemoval(context, entry, onChanged: onChanged),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove this entry'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.critical,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemoval(
    BuildContext context,
    MaternalWeightEntry entry, {
    required VoidCallback onChanged,
  }) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove weight entry?'),
        content: const Text(
          'This removes this private entry from your weight history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep entry'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (shouldRemove != true) return;
    await onRemove(entry.id);
    onChanged();
    if (context.mounted) Navigator.pop(context);
  }
}

enum _WeightInsightsView { overview, history, add }

final _weightInputFormatter = TextInputFormatter.withFunction((
  oldValue,
  value,
) {
  return RegExp(r'^\d*(?:[.,]\d*)?$').hasMatch(value.text) ? value : oldValue;
});

class _WeightTrendChart extends StatelessWidget {
  const _WeightTrendChart({required this.entries});

  final List<MaternalWeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SurfaceCard(
        color: AppColors.lavender.withValues(alpha: .14),
        child: const Text('Add an entry to begin your private weight trend.'),
      );
    }

    final displayUnit = entries.last.unit;
    final weights = entries
        .map((entry) => displayUnit.fromKilograms(entry.kilograms))
        .toList();
    final lowest = weights.reduce(math.min);
    final highest = weights.reduce(math.max);
    final first = entries.first.date;
    final last = entries.last.date;
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = textTheme.bodySmall?.color;

    return Semantics(
      label: entries.length == 1
          ? 'Private weight chart with one saved entry.'
          : 'Private weight line chart with ${entries.length} saved entries.',
      child: SurfaceCard(
        color: AppColors.lavender.withValues(alpha: .1),
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weight trend', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              entries.length == 1
                  ? 'Add another entry to draw your line over time.'
                  : 'A private view of the entries you chose to save.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpace.md),
            SizedBox(
              height: 130,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightTrendPainter(
                  values: weights,
                  lineColor: AppColors.pregnancy,
                  gridColor: Theme.of(context).dividerColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${first.day}/${first.month}/${first.year}',
                  style: textTheme.labelSmall?.copyWith(color: mutedColor),
                ),
                Text(
                  'Range ${lowest.toStringAsFixed(1)}–${highest.toStringAsFixed(1)} ${displayUnit.label}',
                  style: textTheme.labelSmall?.copyWith(color: mutedColor),
                ),
                Text(
                  '${last.day}/${last.month}/${last.year}',
                  style: textTheme.labelSmall?.copyWith(color: mutedColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  const _WeightTrendPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalPadding = 8.0;
    const verticalPadding = 12.0;
    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - verticalPadding * 2;

    final guidePaint = Paint()
      ..color = gridColor.withValues(alpha: .65)
      ..strokeWidth = 1;
    for (var index = 0; index < 3; index++) {
      final y = verticalPadding + chartHeight * index / 2;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        guidePaint,
      );
    }

    if (values.isEmpty) return;
    final lowest = values.reduce(math.min);
    final highest = values.reduce(math.max);
    final spread = math.max(highest - lowest, .5);

    Offset pointAt(int index) {
      final x = values.length == 1
          ? size.width / 2
          : horizontalPadding + chartWidth * index / (values.length - 1);
      final y =
          verticalPadding + (highest - values[index]) / spread * chartHeight;
      return Offset(x, y);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var index = 1; index < values.length; index++) {
      final point = pointAt(index);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = lineColor;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var index = 0; index < values.length; index++) {
      final point = pointAt(index);
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _WeeklyPregnancyCard extends StatelessWidget {
  const _WeeklyPregnancyCard({
    required this.week,
    required this.information,
    required this.dailyAdvice,
  });

  final PregnancyWeek? week;
  final WeeklyPregnancyInformation? information;
  final PregnancyDailyAdvice dailyAdvice;

  @override
  Widget build(BuildContext context) {
    final hasTimeline = week != null && information != null;
    return SurfaceCard(
      color: AppColors.lavender.withValues(alpha: .14),
      onTap: hasTimeline ? () => _openGuide(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.pregnancy.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.child_care_outlined,
                  color: AppColors.pregnancy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasTimeline
                          ? 'Baby & you · week ${week!.week}'
                          : 'Your week-by-week guide',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasTimeline
                          ? '${week!.trimester} · tap to understand baby development, body changes and care this week.'
                          : 'Add a due date to see information tailored to your pregnancy week.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (hasTimeline)
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openGuide(BuildContext context) {
    final guide = information!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: .68,
        minChildSize: .4,
        maxChildSize: .9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.lg,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'Baby & you · week ${week!.week}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${week!.trimester} · general education for this stage of pregnancy.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.lg),
              _AdviceLine(
                icon: Icons.child_care_outlined,
                label: 'Your baby this week',
                text: guide.baby,
              ),
              const SizedBox(height: AppSpace.md),
              _AdviceLine(
                icon: Icons.favorite_outline,
                label: 'Your body this week',
                text: guide.forMother,
              ),
              const SizedBox(height: AppSpace.md),
              _AdviceLine(
                icon: Icons.medical_services_outlined,
                label: 'Care focus',
                text: guide.careFocus,
              ),
              const SizedBox(height: AppSpace.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpace.md),
              Text(
                'TODAY\'S CARE NOTE',
                style: const TextStyle(
                  color: AppColors.berry,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dailyAdvice.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                dailyAdvice.forMother,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (dailyAdvice.urgentNote != null) ...[
                const SizedBox(height: AppSpace.sm),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: .28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dailyAdvice.urgentNote!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.md),
              Text(
                'Educational information only; it does not replace your prenatal care. Contact your maternity-care team with any concern.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PregnancyHero extends StatelessWidget {
  const _PregnancyHero({
    required this.week,
    required this.dueDate,
    required this.onTap,
  });
  final PregnancyWeek? week;
  final DateTime? dueDate;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final progress = week == null ? .03 : (week!.week / 40).clamp(.03, .98);
    final timeUntilDue = _timeUntilDue();
    return SurfaceCard(
      color: AppColors.plum,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  week == null
                      ? 'PREGNANCY'
                      : 'PREGNANCY AGE · WEEK ${week!.week}',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .22),
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.child_care_rounded,
                  color: Color(0xFFFFEEF5),
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            week == null
                ? 'Set up your timeline'
                : '${week!.week} weeks + ${week!.day} days',
            style: Theme.of(
              context,
            ).textTheme.displayMedium!.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            week == null ? 'Choose a due date or add it later.' : timeUntilDue!,
            style: const TextStyle(color: Color(0xFFF7E8EF), fontSize: 13),
          ),
          if (week != null) ...[
            const SizedBox(height: 3),
            Text(
              '${week!.trimester} · timeline based on your entered date',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: .22),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            week == null
                ? 'ESTIMATED WEEKLY TIMELINE'
                : '${week!.week} / ~40 weeks · estimated',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
            ),
          ),
          if (dueDate != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              'ESTIMATED DUE DATE · ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _timeUntilDue() {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final remainingDays = due.difference(today).inDays;
    if (remainingDays == 0) return 'Your estimated due date is today';
    if (remainingDays < 0) {
      return 'Your estimated due date has passed';
    }
    final weeks = remainingDays ~/ 7;
    final days = remainingDays % 7;
    return '$weeks weeks + $days days until your estimated due date';
  }
}

class _DocumentsAction extends StatelessWidget {
  const _DocumentsAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.all(AppSpace.md),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.pregnancy.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.upload_file_rounded,
            size: 25,
            color: AppColors.pregnancy,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Documents',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Upload PDFs, images and health reports',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.xs),
              const Row(
                children: [
                  _DocumentTypeIcon(icon: Icons.picture_as_pdf_outlined),
                  SizedBox(width: AppSpace.xs),
                  _DocumentTypeIcon(icon: Icons.image_outlined),
                  SizedBox(width: AppSpace.xs),
                  _DocumentTypeIcon(icon: Icons.description_outlined),
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ],
    ),
  );
}

class _DocumentTypeIcon extends StatelessWidget {
  const _DocumentTypeIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 25,
    height: 25,
    decoration: BoxDecoration(
      color: AppColors.lavender.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: 14, color: AppColors.berry),
  );
}

class _ClinicianAction extends StatelessWidget {
  const _ClinicianAction({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.all(AppSpace.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.pregnancy.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 21, color: AppColors.pregnancy),
        ),
        const SizedBox(height: 14),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 3),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
