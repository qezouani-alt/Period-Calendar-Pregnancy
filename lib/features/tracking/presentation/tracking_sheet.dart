import 'package:flutter/material.dart';

import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';
import '../../shared/domain/health_mode_service.dart';

Future<DailyHealthLog?> showTrackingSheet(
  BuildContext context, {
  required DateTime date,
  DailyHealthLog? existing,
  required ActiveHealthContext healthContext,
}) {
  return showModalBottomSheet<DailyHealthLog>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TrackingSheet(
      date: date,
      existing: existing,
      healthContext: healthContext,
    ),
  );
}

class _TrackingSheet extends StatefulWidget {
  const _TrackingSheet({
    required this.date,
    this.existing,
    required this.healthContext,
  });
  final DateTime date;
  final DailyHealthLog? existing;
  final ActiveHealthContext healthContext;
  @override
  State<_TrackingSheet> createState() => _TrackingSheetState();
}

class _TrackingSheetState extends State<_TrackingSheet> {
  final symptoms = <String>{};
  final locations = <PainLocation>{};
  final notes = TextEditingController();
  final customFlow = TextEditingController();
  final customBody = TextEditingController();
  final customPainLocation = TextEditingController();
  final customMood = TextEditingController();
  int? pain;
  String? mood;
  FlowLevel? flow;

  @override
  void initState() {
    super.initState();
    final old = widget.existing;
    if (old == null) return;
    symptoms.addAll(old.symptoms);
    pain = old.painIntensity;
    mood = old.mood;
    flow = old.flow;
    locations.addAll(old.locations);
    notes.text = old.notes ?? '';
    customFlow.text = old.customFlow ?? '';
    customBody.text = old.customBody ?? '';
    customPainLocation.text = old.customPainLocation ?? '';
    customMood.text = old.customMood ?? '';
  }

  @override
  void dispose() {
    notes.dispose();
    customFlow.dispose();
    customBody.dispose();
    customPainLocation.dispose();
    customMood.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pregnancy = widget.healthContext.isPregnancy;
    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .55,
      maxChildSize: .94,
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
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              widget.date.day == DateTime.now().day &&
                      widget.date.month == DateTime.now().month
                  ? pregnancy
                        ? 'Today\'s pregnancy check-in'
                        : 'Today\'s health'
                  : 'Health log · ${widget.date.day}/${widget.date.month}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'A few notes are enough. You can edit them later.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpace.lg),
            if (!pregnancy) ...[
              _title(context, 'PERIOD'),
              Wrap(
                spacing: 8,
                children: FlowLevel.values
                    .map(
                      (item) => ChoiceChip(
                        label: Text(
                          item.name == 'none'
                              ? 'No flow'
                              : '${item.name[0].toUpperCase()}${item.name.substring(1)}',
                        ),
                        selected: flow == item,
                        onSelected: (_) => setState(() => flow = item),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              _customField(
                controller: customFlow,
                label: 'Add your own flow description',
                hint: 'For example, irregular or changing',
              ),
              const SizedBox(height: AppSpace.lg),
            ],
            _title(context, pregnancy ? 'PREGNANCY SYMPTOMS' : 'BODY'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  (pregnancy
                          ? [
                              'Tired',
                              'Nauseous',
                              'Headache',
                              'Fatigue',
                              'Back discomfort',
                              'Spotting / bleeding note',
                            ]
                          : [
                              'Cramps',
                              'Headache',
                              'Bloating',
                              'Back pain',
                              'Fatigue',
                              'Acne',
                            ])
                      .map(
                        (item) => FilterChip(
                          label: Text(item),
                          selected: symptoms.contains(item),
                          onSelected: (value) => setState(() {
                            if (value) {
                              symptoms.add(item);
                            } else {
                              symptoms.remove(item);
                            }
                          }),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 10),
            _customField(
              controller: customBody,
              label: 'Add your own body symptom',
              hint: 'For example, dizziness or breast tenderness',
            ),
            const SizedBox(height: AppSpace.lg),
            _title(context, pregnancy ? 'DISCOMFORT' : 'PAIN INTENSITY'),
            Row(
              children: List.generate(
                11,
                (index) => Expanded(child: _painButton(context, index)),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            _title(
              context,
              pregnancy ? 'DISCOMFORT LOCATION' : 'PAIN LOCATION',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PainLocation.values
                  .map(
                    (item) => FilterChip(
                      label: Text(_locationLabel(item)),
                      selected: locations.contains(item),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          locations.add(item);
                        } else {
                          locations.remove(item);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            _customField(
              controller: customPainLocation,
              label: pregnancy
                  ? 'Add another discomfort location'
                  : 'Add another pain location',
              hint: 'For example, hip or shoulder',
            ),
            const SizedBox(height: AppSpace.lg),
            _title(context, 'MOOD'),
            Wrap(
              spacing: 8,
              children: ['Calm', 'Happy', 'Sensitive', 'Low']
                  .map(
                    (item) => ChoiceChip(
                      label: Text(item),
                      selected: mood == item,
                      onSelected: (_) => setState(() => mood = item),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            _customField(
              controller: customMood,
              label: 'Describe your mood in your own words',
              hint: 'For example, overwhelmed or hopeful',
            ),
            const SizedBox(height: AppSpace.lg),
            TextField(
              controller: notes,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: pregnancy
                    ? 'A private pregnancy note (optional)'
                    : 'A private note (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            PrimaryButton(
              label: 'Save today\'s log',
              icon: Icons.check,
              onPressed: () => Navigator.pop(
                context,
                DailyHealthLog(
                  date: widget.date,
                  painIntensity: pain,
                  flow: flow,
                  symptoms: {
                    ...symptoms,
                    if (customBody.text.trim().isNotEmpty)
                      customBody.text.trim(),
                  },
                  mood: customMood.text.trim().isNotEmpty
                      ? customMood.text.trim()
                      : mood,
                  notes: notes.text.isEmpty ? null : notes.text,
                  locations: locations,
                  customFlow: _valueOrNull(customFlow),
                  customBody: _valueOrNull(customBody),
                  customPainLocation: _valueOrNull(customPainLocation),
                  customMood: _valueOrNull(customMood),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.labelSmall),
  );
  Widget _customField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) => TextField(
    controller: controller,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
  );
  String? _valueOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String _locationLabel(PainLocation location) => switch (location) {
    PainLocation.lowerAbdomen => 'Lower abdomen',
    PainLocation.pelvicArea => 'Pelvic area',
    PainLocation.lowerBack => 'Lower back',
    PainLocation.legs => 'Legs',
  };
  Widget _painButton(BuildContext context, int value) => Semantics(
    label: 'Pain $value out of 10',
    button: true,
    child: InkWell(
      onTap: () => setState(() => pain = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(right: 3),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pain == value
              ? AppColors.berry
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: pain == value
                ? AppColors.berry
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          '$value',
          style: TextStyle(color: pain == value ? Colors.white : null),
        ),
      ),
    ),
  );
}
