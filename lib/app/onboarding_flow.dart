import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/design_system/app_theme.dart';
import '../core/widgets/premium_widgets.dart';
import '../features/shared/domain/health_models.dart';
import 'app_controller.dart';

enum _HeightUnit {
  centimeters('cm'),
  inches('in');

  const _HeightUnit(this.label);

  final String label;
}

final _heightInputFormatter = TextInputFormatter.withFunction((
  oldValue,
  value,
) {
  return RegExp(r'^\d*(?:[.,]\d*)?$').hasMatch(value.text) ? value : oldValue;
});

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.controller});
  final AppController controller;
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const total = 8;
  var step = 0;
  final name = TextEditingController();
  String? nameError;
  final goals = <TrackingGoal>{};
  DateTime? lastPeriod;
  int? cycleLength, periodLength;
  bool? currentlyPregnant;
  bool enterPregnancyAge = true;
  DateTime? pregnancyDueDate;
  int pregnancyWeeks = 12;
  int pregnancyDays = 0;
  String? pregnancyError;
  final maternalHeight = TextEditingController();
  var heightUnit = _HeightUnit.centimeters;
  final startingWeight = TextEditingController();
  final permissions = <Permission, PermissionStatus>{};

  void _next() {
    if (step == 0 && name.text.trim().isEmpty) {
      setState(() => nameError = 'Enter your name to continue.');
      return;
    }
    if (step == 3 && goals.contains(TrackingGoal.pregnancy)) {
      if (currentlyPregnant != true) {
        setState(
          () => pregnancyError =
              'Tell us whether you are currently pregnant to continue.',
        );
        return;
      }
      if (pregnancyDueDate == null) {
        setState(
          () => pregnancyError =
              'Choose your estimated due date or current pregnancy age to continue.',
        );
        return;
      }
    }
    if (step < total - 1) {
      setState(() => step++);
      return;
    }
    widget.controller.completeOnboarding(
      name: name.text.trim(),
      goals: goals,
      cycleLength: cycleLength,
      periodLength: periodLength,
      lastPeriod: lastPeriod,
      estimatedDueDate: goals.contains(TrackingGoal.pregnancy)
          ? pregnancyDueDate
          : null,
      heightCm: _heightInCentimeters,
      startingWeightKg: double.tryParse(
        startingWeight.text.trim().replaceAll(',', '.'),
      ),
    );
  }

  @override
  void dispose() {
    name.dispose();
    maternalHeight.dispose();
    startingWeight.dispose();
    super.dispose();
  }

  int? get _heightInCentimeters {
    final value = double.tryParse(
      maternalHeight.text.trim().replaceAll(',', '.'),
    );
    if (value == null || value <= 0) return null;
    return heightUnit == _HeightUnit.centimeters
        ? value.round()
        : (value * 2.54).round();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'LUNA',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge!.copyWith(color: AppColors.berry),
                ),
                const Spacer(),
                Text(
                  '${step + 1} of $total',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (step + 1) / total,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: AppColors.rose.withValues(alpha: .25),
              color: AppColors.berry,
            ),
            const SizedBox(height: AppSpace.md),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: SingleChildScrollView(
                  key: ValueKey(step),
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  child: _page(context),
                ),
              ),
            ),
            Row(
              children: [
                if (step > 0)
                  TextButton(
                    onPressed: () => setState(() => step--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                if (step != 0 &&
                    !(step == 3 && goals.contains(TrackingGoal.pregnancy)))
                  TextButton(
                    onPressed: _next,
                    child: Text(step == total - 1 ? 'Set later' : 'Skip'),
                  ),
              ],
            ),
            PrimaryButton(
              label: step == total - 1 ? 'Start my journey' : 'Continue',
              onPressed: _next,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _page(BuildContext context) {
    switch (step) {
      case 0:
        return _name(context);
      case 1:
        return _copy(
          context,
          'Understand your cycle.\nFeel more prepared.',
          'A private place to notice patterns, log what matters, and learn at your pace.',
        );
      case 2:
        return _goals(context);
      case 3:
        return goals.contains(TrackingGoal.pregnancy)
            ? _pregnancyDating(context)
            : _date(context);
      case 4:
        return _choices(
          context,
          'How long is your cycle usually?',
          'There is no “right” number. Estimates adapt as you log.',
          const {
            '21–24': 22,
            '25–27': 26,
            '28–30': 29,
            '31–35': 33,
            'Varies': null,
            "I don't know": null,
          },
          cycleLength,
        );
      case 5:
        return _choices(
          context,
          'How long does your period usually last?',
          'This is optional and can be updated later.',
          const {
            '2–3 days': 3,
            '4–5 days': 5,
            '6–7 days': 7,
            "I don't know": null,
          },
          periodLength,
        );
      case 6:
        return _privacy(context);
      default:
        return _permissions(context);
    }
  }

  Widget _copy(BuildContext context, String title, String description) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: AppSpace.md),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
        ],
      );

  Widget _name(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'What should we\ncall you?',
        style: Theme.of(context).textTheme.displayMedium,
      ),
      const SizedBox(height: AppSpace.md),
      Text(
        'Your name helps make this private space feel personal. It stays on this device.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpace.xl),
      TextField(
        controller: name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          if (nameError != null && name.text.trim().isNotEmpty) {
            setState(() => nameError = null);
          }
        },
        onSubmitted: (_) => _next(),
        decoration: InputDecoration(
          labelText: 'Your name',
          hintText: 'Enter your name',
          errorText: nameError,
        ),
      ),
    ],
  );

  Widget _goals(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'What would you like\nto focus on?',
        style: Theme.of(context).textTheme.displayMedium,
      ),
      const SizedBox(height: AppSpace.md),
      Text(
        'Pick one or more. Your home will adapt to what matters now.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpace.xl),
      Wrap(
        spacing: 8,
        runSpacing: 10,
        children: TrackingGoal.values
            .map(
              (goal) => FilterChip(
                label: Text(_label(goal)),
                selected: goals.contains(goal),
                onSelected: (value) => setState(() {
                  if (value) {
                    goals.add(goal);
                    if (goal == TrackingGoal.pregnancy) {
                      currentlyPregnant = null;
                      pregnancyDueDate = null;
                    }
                  } else {
                    goals.remove(goal);
                    if (goal == TrackingGoal.pregnancy) {
                      currentlyPregnant = null;
                      pregnancyDueDate = null;
                    }
                  }
                }),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget _pregnancyDating(BuildContext context) {
    if (currentlyPregnant == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you currently\npregnant?',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'If yes, we will use your pregnancy age or estimated due date to organise your private timeline.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpace.xl),
          PrimaryButton(
            label: 'Yes, I am pregnant',
            icon: Icons.pregnant_woman_rounded,
            onPressed: () => setState(() {
              currentlyPregnant = true;
              pregnancyDueDate = _dueDateFromAge(pregnancyWeeks, pregnancyDays);
              pregnancyError = null;
            }),
          ),
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                currentlyPregnant = false;
                goals.remove(TrackingGoal.pregnancy);
                pregnancyError = null;
              }),
              icon: const Icon(Icons.calendar_today_outlined),
              label: const Text('Not currently'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.plum,
                side: const BorderSide(color: AppColors.plum, width: 1.5),
                textStyle: Theme.of(context).textTheme.titleMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          if (pregnancyError != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              pregnancyError!,
              style: const TextStyle(color: AppColors.critical),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your pregnancy\ntimeline',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          'Start with your current pregnancy age. If you have a date from your maternity-care team, you can use that instead.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpace.lg),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Pregnancy age')),
            ButtonSegment(value: false, label: Text('Due date')),
          ],
          selected: {enterPregnancyAge},
          onSelectionChanged: (value) => setState(() {
            enterPregnancyAge = value.first;
            if (enterPregnancyAge && pregnancyDueDate == null) {
              pregnancyDueDate = _dueDateFromAge(pregnancyWeeks, pregnancyDays);
            }
            pregnancyError = null;
          }),
        ),
        const SizedBox(height: AppSpace.md),
        if (!enterPregnancyAge)
          SurfaceCard(
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 280)),
                lastDate: DateTime.now().add(const Duration(days: 300)),
                initialDate:
                    pregnancyDueDate ??
                    DateTime.now().add(const Duration(days: 200)),
                helpText: 'Estimated due date',
              );
              if (selected != null) {
                setState(() {
                  pregnancyDueDate = selected;
                  pregnancyError = null;
                });
              }
            },
            child: Row(
              children: [
                const Icon(Icons.event_outlined, color: AppColors.pregnancy),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pregnancyDueDate == null
                        ? 'Choose estimated due date'
                        : '${pregnancyDueDate!.day}/${pregnancyDueDate!.month}/${pregnancyDueDate!.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _PregnancyAgeSlider(
                  label: 'Weeks pregnant',
                  value: pregnancyWeeks,
                  maximum: 42,
                  suffix: 'weeks',
                  onChanged: (value) => setState(() {
                    pregnancyWeeks = value;
                    pregnancyDueDate = _dueDateFromAge(
                      pregnancyWeeks,
                      pregnancyDays,
                    );
                    pregnancyError = null;
                  }),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: _PregnancyAgeSlider(
                  label: 'Days',
                  value: pregnancyDays,
                  maximum: 6,
                  suffix: 'days',
                  onChanged: (value) => setState(() {
                    pregnancyDays = value;
                    pregnancyDueDate = _dueDateFromAge(
                      pregnancyWeeks,
                      pregnancyDays,
                    );
                    pregnancyError = null;
                  }),
                ),
              ),
            ],
          ),
        if (enterPregnancyAge) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            'Estimated due date: ${pregnancyDueDate == null ? 'choose your pregnancy age' : '${pregnancyDueDate!.day}/${pregnancyDueDate!.month}/${pregnancyDueDate!.year}'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        Text(
          'Your optional starting details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'These support a private weekly maternal-weight record. They do not create a health target or replace your clinician’s advice.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: maternalHeight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_heightInputFormatter],
                decoration: const InputDecoration(
                  labelText: 'Your height (optional)',
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            SizedBox(
              width: 96,
              child: DropdownButtonFormField<_HeightUnit>(
                initialValue: heightUnit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: _HeightUnit.values
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label),
                      ),
                    )
                    .toList(),
                onChanged: (unit) {
                  if (unit != null) setState(() => heightUnit = unit);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        TextField(
          controller: startingWeight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Your current weight (kg, optional)',
          ),
        ),
        if (pregnancyError != null) ...[
          const SizedBox(height: AppSpace.md),
          Text(
            pregnancyError!,
            style: const TextStyle(color: AppColors.critical),
          ),
        ],
      ],
    );
  }

  DateTime _dueDateFromAge(int weeks, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.add(Duration(days: 280 - (weeks * 7 + days)));
  }

  Widget _date(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'When did your last\nperiod begin?',
        style: Theme.of(context).textTheme.displayMedium,
      ),
      const SizedBox(height: AppSpace.md),
      Text(
        'This helps create a first estimate. You can correct it anytime.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpace.xl),
      SurfaceCard(
        onTap: () async {
          final selected = await showDatePicker(
            context: context,
            firstDate: DateTime(2010),
            lastDate: DateTime.now(),
            initialDate: lastPeriod ?? DateTime.now(),
          );
          if (selected != null) setState(() => lastPeriod = selected);
        },
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.berry),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lastPeriod == null
                    ? 'Choose a date'
                    : '${lastPeriod!.day}/${lastPeriod!.month}/${lastPeriod!.year}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => setState(() => lastPeriod = null),
        child: const Text("I don't remember"),
      ),
    ],
  );
  Widget _choices(
    BuildContext context,
    String title,
    String description,
    Map<String, int?> choices,
    int? value,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.displayMedium),
      const SizedBox(height: AppSpace.md),
      Text(description, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: AppSpace.xl),
      ...choices.entries.map(
        (entry) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SurfaceCard(
            onTap: () => setState(() {
              if (step == 4) {
                cycleLength = entry.value;
              } else {
                periodLength = entry.value;
              }
            }),
            color: value == entry.value && value != null
                ? AppColors.lavender.withValues(alpha: .23)
                : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (value == entry.value && value != null)
                  const Icon(Icons.check_circle, color: AppColors.berry),
              ],
            ),
          ),
        ),
      ),
    ],
  );
  Widget _privacy(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Your health data\nbelongs to you.',
        style: Theme.of(context).textTheme.displayMedium,
      ),
      const SizedBox(height: AppSpace.md),
      Text(
        'Your logs are saved on this device. Notification previews can stay private, and you can delete your data in Settings.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpace.xl),
      const PrivacyPill(),
      const SizedBox(height: AppSpace.md),
      SurfaceCard(
        child: const Row(
          children: [
            Icon(Icons.phone_android_outlined, color: AppColors.success),
            SizedBox(width: 12),
            Expanded(
              child: Text('Local storage\nNo account is required to begin.'),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _permissions(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Choose your\npermissions.',
        style: Theme.of(context).textTheme.displayMedium,
      ),
      const SizedBox(height: AppSpace.md),
      Text(
        'These are optional. You can change them later in your phone settings. We only ask for access when it supports a feature you choose to use.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpace.xl),
      _PermissionCard(
        icon: Icons.notifications_none,
        title: 'Reminders',
        description: 'Receive private appointment and health reminders.',
        status: permissions[Permission.notification],
        onRequest: () => _requestPermission(Permission.notification),
        onOpenSettings: openAppSettings,
      ),
      const SizedBox(height: AppSpace.sm),
      _PermissionCard(
        icon: Icons.photo_camera_outlined,
        title: 'Camera',
        description: 'Scan or photograph a document for My Documents.',
        status: permissions[Permission.camera],
        onRequest: () => _requestPermission(Permission.camera),
        onOpenSettings: openAppSettings,
      ),
      const SizedBox(height: AppSpace.sm),
      _PermissionCard(
        icon: Icons.photo_library_outlined,
        title: 'Photos',
        description: 'Choose a document image from your gallery.',
        status: permissions[Permission.photos],
        onRequest: () => _requestPermission(Permission.photos),
        onOpenSettings: openAppSettings,
      ),
    ],
  );

  Future<void> _requestPermission(Permission permission) async {
    if (permission == Permission.notification) {
      await widget.controller.requestNotificationPermission();
    } else {
      await permission.request();
    }
    final status = await permission.status;
    if (mounted) setState(() => permissions[permission] = status);
  }

  String _label(TrackingGoal goal) => switch (goal) {
    TrackingGoal.cycle => 'Track my cycle',
    TrackingGoal.understandPeriod => 'Understand my period',
    TrackingGoal.conceive => 'Trying to conceive',
    TrackingGoal.pregnancy => 'Track pregnancy',
    TrackingGoal.pain => 'Manage period pain',
  };
}

class _PregnancyAgeSlider extends StatelessWidget {
  const _PregnancyAgeSlider({
    required this.label,
    required this.value,
    required this.maximum,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int maximum;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label · $value', style: Theme.of(context).textTheme.labelSmall),
      Slider(
        value: value.toDouble(),
        min: 0,
        max: maximum.toDouble(),
        divisions: maximum,
        label: '$value $suffix',
        onChanged: (next) => onChanged(next.round()),
      ),
      Text('$value $suffix', style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final IconData icon;
  final String title;
  final String description;
  final PermissionStatus? status;
  final VoidCallback onRequest;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final granted = status?.isGranted == true || status?.isLimited == true;
    final blocked = status?.isPermanentlyDenied == true;
    return SurfaceCard(
      onTap: granted
          ? null
          : blocked
          ? () => onOpenSettings()
          : onRequest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.berry),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  granted
                      ? 'Allowed'
                      : blocked
                      ? 'Open phone settings to allow'
                      : 'Tap to allow',
                  style: TextStyle(
                    color: granted ? AppColors.success : AppColors.berry,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            granted ? Icons.check_circle : Icons.chevron_right,
            color: granted ? AppColors.success : null,
          ),
        ],
      ),
    );
  }
}
