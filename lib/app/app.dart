import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/permissions/permissions_onboarding_sheet.dart';
import '../core/design_system/app_theme.dart';
import '../core/widgets/premium_widgets.dart';
import '../features/calendar/presentation/calendar_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/home/presentation/wellbeing_advice_sheet.dart';
import '../features/ai_agent/presentation/ai_agent_page.dart';
import '../features/learn/presentation/learn_page.dart';
import '../features/nutrition/presentation/ai_chef_page.dart';
import '../features/pregnancy/presentation/pregnancy_hub.dart';
import '../features/pregnancy/presentation/pregnancy_notes_sheet.dart';
import '../features/pregnancy/presentation/symptoms_history_sheet.dart';
import '../features/pregnancy/presentation/pregnancy_organizers.dart';
import '../features/pregnancy/presentation/reminders_sheet.dart';
import '../features/pregnancy/domain/pregnancy_timeline.dart';
import '../features/shared/domain/health_models.dart';
import '../features/shared/domain/wellbeing_advice_service.dart';
import '../features/tracking/presentation/tracking_sheet.dart';
import 'app_controller.dart';
import 'onboarding_flow.dart';

class LunaApp extends StatefulWidget {
  const LunaApp({super.key, this.launchDuration = const Duration(seconds: 5)});

  final Duration launchDuration;

  @override
  State<LunaApp> createState() => _LunaAppState();
}

class _LunaAppState extends State<LunaApp> {
  late final Future<AppController> _controller = _loadApp();

  Future<AppController> _loadApp() async {
    final results = await Future.wait<dynamic>([
      AppController.load(),
      Future<void>.delayed(widget.launchDuration),
    ]);
    return results.first as AppController;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppController>(
    future: _controller,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return MaterialApp(
          theme: lunaTheme(Brightness.light),
          home: const _LaunchScreen(),
        );
      }
      return _Product(controller: snapshot.data!);
    },
  );
}

class _LaunchScreen extends StatefulWidget {
  const _LaunchScreen();

  @override
  State<_LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<_LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..forward();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Center(
              child: Container(
                width: 128,
                height: 128,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A4A2145),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/app_icon/appicon.png',
                    semanticLabel: 'Period Calendar and Pregnancy',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Center(
              child: Text(
                'Period Calendar & Pregnancy',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Ovulation & Fertility',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Spacer(flex: 2),
            Text(
              'Preparing your private space',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: _progress.value,
                    minHeight: 7,
                    color: AppColors.plum,
                    backgroundColor: AppColors.rose.withValues(alpha: .28),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
        ),
      ),
    ),
  );
}

class _Product extends StatefulWidget {
  const _Product({required this.controller});
  final AppController controller;
  @override
  State<_Product> createState() => _ProductState();
}

class _ProductState extends State<_Product> {
  int index = 0;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      return MaterialApp(
        title: 'Period Calendar & Pregnancy',
        debugShowCheckedModeBanner: false,
        theme: lunaTheme(Brightness.light),
        darkTheme: lunaTheme(Brightness.dark),
        themeMode: controller.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: controller.profile == null
            ? OnboardingFlow(controller: controller)
            : _PermissionsGate(
                controller: controller,
                index: index,
                onIndex: (value) => setState(() => index = value),
              ),
      );
    },
  );
}

class _PermissionsGate extends StatefulWidget {
  const _PermissionsGate({
    required this.controller,
    required this.index,
    required this.onIndex,
  });

  final AppController controller;
  final int index;
  final ValueChanged<int> onIndex;

  @override
  State<_PermissionsGate> createState() => _PermissionsGateState();
}

class _PermissionsGateState extends State<_PermissionsGate> {
  var _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showIfNeeded());
  }

  Future<void> _showIfNeeded() async {
    if (_shown || widget.controller.permissionsOnboardingSeen || !mounted) {
      return;
    }
    _shown = true;
    await showPermissionsOnboardingSheet(
      context,
      onComplete: widget.controller.completePermissionsOnboarding,
      onRequestNotifications: widget.controller.requestNotificationPermission,
    );
  }

  @override
  Widget build(BuildContext context) => _Shell(
    controller: widget.controller,
    index: widget.index,
    onIndex: widget.onIndex,
  );
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.controller,
    required this.index,
    required this.onIndex,
  });
  final AppController controller;
  final int index;
  final ValueChanged<int> onIndex;

  Future<void> _recordBirth(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('I gave birth'),
        content: const Text(
          'This will end pregnancy tracking and make Period available again. Your private pregnancy entries will remain saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('I gave birth'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await controller.recordBirth();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        icon: const Icon(Icons.favorite_rounded, color: AppColors.berry),
        title: const Text('Congratulations'),
        content: const Text(
          'Congratulations on your new arrival. Take things at your own pace—Period is available again whenever it feels useful to you.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Go to Period'),
          ),
        ],
      ),
    );
    if (context.mounted) onIndex(1);
  }

  Future<void> _track(BuildContext context, [DateTime? date]) async {
    final target = date ?? DateTime.now();
    final log = await showTrackingSheet(
      context,
      date: target,
      existing: controller.logFor(target),
      healthContext: controller.healthContext,
    );
    if (log != null) {
      await controller.saveLog(log);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Today\'s log saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile!;
    final pages = [
      HomePage(
        profile: profile,
        prediction: controller.prediction,
        periods: controller.periods,
        appointments: controller.appointments,
        onTrack: () => _track(context),
        onPainHub: () => _painHub(context),
        onProfile: () => _settings(context),
        onPregnancy: () => onIndex(2),
        onAddReminder: () => _quickAppointment(context),
        onAddNote: () => _quickPregnancyNote(context),
        onAddSymptoms: () => _track(context),
        onCalendar: () => onIndex(1),
        onFood: () => _food(context),
        healthContext: controller.healthContext,
      ),
      CalendarPage(
        profile: profile,
        prediction: controller.prediction,
        periods: controller.periods,
        periodNotes: controller.periodNotes,
        onLogDate: (date) => _track(context, date),
        onStartPeriod: (date) => controller.startPeriod(date),
        onRemovePeriod: (date) => controller.removePeriod(date),
        onRemoveLog: (date) => controller.removeLog(date),
        onQuickCheckIn: (value) => _quickCheckIn(context, value),
        onAddPeriodNote: (date) => _periodNotes(context, date),
        onPregnancySetup: () => _pregnancySetup(context),
        logs: controller.logs,
      ),
      PregnancyHub(
        profile: profile,
        appointments: controller.appointments,
        maternalWeights: controller.maternalWeights,
        onSetup: () => _pregnancySetup(context),
        onTrack: () => _track(context),
        onSymptoms: () => _symptoms(context),
        onWriteNote: () => _pregnancyNotes(context),
        onRecords: () => _pregnancyRecords(context),
        healthContext: controller.healthContext,
        onQuickCheckIn: (value) => _quickCheckIn(context, value),
        onReminders: () => _reminders(context),
        onAddMaternalWeight: controller.addMaternalWeight,
        onUpdateMaternalWeight: controller.updateMaternalWeight,
        onRemoveMaternalWeight: controller.removeMaternalWeight,
        onRecordBirth: () => _recordBirth(context),
      ),
      AiAgentPage(healthContext: controller.healthContext),
      const LearnPage(),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
        ),
      ),
      bottomNavigationBar: GlassBottomNavigation(
        index: index,
        onChanged: onIndex,
        isPregnancyActive: controller.healthContext.isPregnancy,
      ),
    );
  }

  Future<void> _food(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AiChefPage(
        profile: controller.profile!,
        healthContext: controller.healthContext,
      ),
    ),
  );

  Future<void> _pregnancyRecords(BuildContext context) =>
      showPregnancyRecordsSheet(
        context,
        records: controller.pregnancyRecords,
        onSave: controller.savePregnancyRecord,
        onRemove: controller.removePregnancyRecord,
      );

  Future<void> _reminders(BuildContext context) => showSavedRemindersSheet(
    context,
    appointments: controller.appointments,
    onAddReminder: () => _quickAppointment(context),
  );

  Future<void> _pregnancyNotes(BuildContext context) => showPregnancyNotesSheet(
    context,
    notes: controller.pregnancyNotes,
    onAddNote: () => _quickPregnancyNote(context),
  );

  Future<void> _symptoms(BuildContext context) => showSymptomsHistorySheet(
    context,
    entries: controller.symptomEntries,
    onAddSymptoms: () => _track(context),
  );

  Future<void> _quickCheckIn(BuildContext context, String value) async {
    await controller.quickCheckIn(value);
    if (context.mounted) {
      await showWellbeingAdvice(
        context,
        const WellbeingAdviceService().forFeeling(
          value,
          controller.healthContext.mode,
        ),
      );
    }
  }

  Future<void> _pregnancySetup(BuildContext context) async {
    final isNewPregnancy = !controller.healthContext.isPregnancy;
    DateTime? dueDate = controller.profile!.estimatedDueDate;
    var enterPregnancyAge = true;
    final existingAge = PregnancyTimeline.fromDueDate(dueDate);
    var ageWeeks = existingAge?.week ?? 12;
    var ageDays = existingAge?.day ?? 0;
    var weightUnit = WeightUnit.kilograms;
    var heightInCentimetres = true;
    dueDate ??= _dueDateFromPregnancyAge(ageWeeks, ageDays);
    String? validationMessage;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => _PregnancySetupFields(
        initialHeightText: controller.maternalHeightCm?.toString() ?? '',
        builder: (startingWeight, height) => StatefulBuilder(
          builder: (context, setSheet) => Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              AppSpace.xxl,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    isNewPregnancy ? 'Congratulations' : 'Pregnancy tracking',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isNewPregnancy
                        ? 'Congratulations on your pregnancy. Let’s set up your private timeline with the details you choose to share.'
                        : 'Update your private pregnancy timeline when you need to.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Pregnancy age')),
                      ButtonSegment(value: false, label: Text('Due date')),
                    ],
                    selected: {enterPregnancyAge},
                    onSelectionChanged: (value) => setSheet(() {
                      enterPregnancyAge = value.first;
                      if (enterPregnancyAge && dueDate == null) {
                        dueDate = _dueDateFromPregnancyAge(ageWeeks, ageDays);
                      }
                    }),
                  ),
                  const SizedBox(height: AppSpace.md),
                  if (!enterPregnancyAge)
                    SurfaceCard(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 280),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 300),
                          ),
                          initialDate:
                              dueDate ??
                              DateTime.now().add(const Duration(days: 200)),
                          helpText: 'Estimated due date',
                        );
                        if (picked != null) setSheet(() => dueDate = picked);
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_outlined,
                            color: AppColors.pregnancy,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated due date',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Text(
                                  dueDate == null
                                      ? 'Choose your due date'
                                      : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
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
                            label: 'Weeks',
                            value: ageWeeks,
                            maximum: 42,
                            suffix: 'weeks',
                            onChanged: (value) => setSheet(() {
                              ageWeeks = value;
                              dueDate = _dueDateFromPregnancyAge(
                                ageWeeks,
                                ageDays,
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: _PregnancyAgeSlider(
                            label: 'Days',
                            value: ageDays,
                            maximum: 6,
                            suffix: 'days',
                            onChanged: (value) => setSheet(() {
                              ageDays = value;
                              dueDate = _dueDateFromPregnancyAge(
                                ageWeeks,
                                ageDays,
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  if (enterPregnancyAge) ...[
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      'Estimated due date: ${dueDate == null ? 'choose pregnancy age' : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    'Your starting details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Optional. These stay private and can support your personal weight tracker.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpace.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: startingWeight,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Starting weight',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<WeightUnit>(
                          initialValue: weightUnit,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: WeightUnit.values
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setSheet(
                            () => weightUnit = value ?? WeightUnit.kilograms,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: height,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Height',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<bool>(
                          initialValue: heightInCentimetres,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: const [
                            DropdownMenuItem(value: true, child: Text('cm')),
                            DropdownMenuItem(value: false, child: Text('in')),
                          ],
                          onChanged: (value) => setSheet(
                            () => heightInCentimetres = value ?? true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (validationMessage != null) ...[
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      validationMessage!,
                      style: const TextStyle(color: AppColors.critical),
                    ),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  PrimaryButton(
                    label: controller.profile!.mode == CycleMode.pregnancy
                        ? 'Update pregnancy tracking'
                        : 'Start pregnancy tracking',
                    icon: Icons.pregnant_woman_rounded,
                    onPressed: () async {
                      if (dueDate == null) {
                        setSheet(
                          () => validationMessage =
                              'Choose an estimated due date or pregnancy age to continue.',
                        );
                        return;
                      }
                      final weightValue = _parseMeasurement(
                        startingWeight.text,
                      );
                      final heightValue = _parseMeasurement(height.text);
                      if (startingWeight.text.trim().isNotEmpty &&
                          (weightValue == null || weightValue <= 0)) {
                        setSheet(
                          () => validationMessage =
                              'Enter a valid starting weight, or leave it blank.',
                        );
                        return;
                      }
                      if (height.text.trim().isNotEmpty &&
                          (heightValue == null || heightValue <= 0)) {
                        setSheet(
                          () => validationMessage =
                              'Enter a valid height, or leave it blank.',
                        );
                        return;
                      }
                      final heightCm = heightValue == null
                          ? null
                          : (heightInCentimetres
                                    ? heightValue
                                    : heightValue * 2.54)
                                .round();
                      await controller.startPregnancy(
                        dueDate: dueDate!,
                        heightCm: heightCm,
                        startingWeight: weightValue,
                        weightUnit: weightUnit,
                      );
                      onIndex(2);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DateTime _dueDateFromPregnancyAge(int weeks, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.add(Duration(days: 280 - (weeks * 7 + days)));
  }

  double? _parseMeasurement(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> _periodNotes(BuildContext context, DateTime date) async {
    final shouldAdd = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) {
        final notes = controller.periodNotesFor(date);
        final localizations = MaterialLocalizations.of(sheet);
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            AppSpace.lg,
          ),
          decoration: BoxDecoration(
            color: Theme.of(sheet).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(sheet).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'Period notes',
                style: Theme.of(sheet).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'Private notes for this date in your Period calendar.',
                style: Theme.of(sheet).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.md),
              if (notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  child: Text(
                    'No notes saved for this date yet.',
                    style: Theme.of(sheet).textTheme.bodyMedium,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpace.sm),
                    itemBuilder: (_, index) {
                      final note = notes[index];
                      final dateText = localizations.formatFullDate(
                        note.createdAt,
                      );
                      final timeText = localizations.formatTimeOfDay(
                        TimeOfDay.fromDateTime(note.createdAt),
                      );
                      return SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.text,
                              style: Theme.of(sheet).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: AppSpace.xs),
                            Text(
                              'Created $dateText at $timeText',
                              style: Theme.of(sheet).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppSpace.lg),
              PrimaryButton(
                label: 'Add new note',
                icon: Icons.edit_note_rounded,
                onPressed: () => Navigator.pop(sheet, true),
              ),
            ],
          ),
        );
      },
    );
    if (shouldAdd == true && context.mounted) {
      await _addPeriodNote(context, date);
    }
  }

  Future<void> _addPeriodNote(BuildContext context, DateTime date) async {
    final note = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: Theme.of(sheet).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New period note',
                style: Theme.of(sheet).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'Private to this date in your Period calendar.',
                style: Theme.of(sheet).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: note,
                autofocus: true,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Write a note about this day',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              PrimaryButton(
                label: 'Save note',
                onPressed: () async {
                  await controller.addPeriodNote(date, note.text);
                  if (sheet.mounted) Navigator.pop(sheet);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _quickPregnancyNote(BuildContext context) {
    final note = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: Theme.of(sheet).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New private note',
                style: Theme.of(sheet).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                autofocus: true,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'How are you feeling today?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              PrimaryButton(
                label: 'Save note',
                onPressed: () async {
                  await controller.addPregnancyNote(note.text);
                  if (sheet.mounted) Navigator.pop(sheet);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _quickAppointment(BuildContext context) {
    var date = DateTime.now();
    var type = AppointmentType.prenatal;
    var appointmentTime = const TimeOfDay(hour: 9, minute: 0);
    var reminderTime = const TimeOfDay(hour: 8, minute: 0);
    final clinic = TextEditingController();
    final reminderMessage = TextEditingController();
    final notes = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) => DraggableScrollableSheet(
          initialChildSize: .84,
          minChildSize: .5,
          maxChildSize: .94,
          builder: (context, scroll) => Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
            ),
            child: ListView(
              controller: scroll,
              children: [
                Text(
                  'Set reminder',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the visit details, reminder time and private message.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpace.md),
                DropdownButtonFormField<AppointmentType>(
                  initialValue: type,
                  items: AppointmentType.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(_appointmentLabel(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setSheet(() => type = value!),
                  decoration: const InputDecoration(labelText: 'Visit type'),
                ),
                const SizedBox(height: AppSpace.sm),
                SurfaceCard(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 300)),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    'Appointment · ${appointmentTime.format(context)}',
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: appointmentTime,
                    );
                    if (picked != null) {
                      setSheet(() => appointmentTime = picked);
                    }
                  },
                ),
                TextField(
                  controller: clinic,
                  decoration: const InputDecoration(
                    labelText: 'Doctor or clinic (optional)',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Reminder time'),
                  subtitle: Text(
                    '${reminderTime.format(context)} on the appointment day',
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: reminderTime,
                    );
                    if (picked != null) setSheet(() => reminderTime = picked);
                  },
                ),
                TextField(
                  controller: reminderMessage,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Private reminder message',
                    hintText: 'What would you like this reminder to say?',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                PrimaryButton(
                  label: 'Save reminder',
                  onPressed: () async {
                    await controller.saveAppointment(
                      PregnancyAppointment(
                        id: '${date.microsecondsSinceEpoch}-prenatal',
                        type: type,
                        dateTime: DateTime(
                          date.year,
                          date.month,
                          date.day,
                          appointmentTime.hour,
                          appointmentTime.minute,
                        ),
                        status: AppointmentStatus.upcoming,
                        clinicName: clinic.text.isEmpty ? null : clinic.text,
                        notes: notes.text.isEmpty ? null : notes.text,
                        reminderAt: DateTime(
                          date.year,
                          date.month,
                          date.day,
                          reminderTime.hour,
                          reminderTime.minute,
                        ),
                        reminderMessage: reminderMessage.text.isEmpty
                            ? null
                            : reminderMessage.text,
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _appointmentLabel(AppointmentType type) => switch (type) {
    AppointmentType.prenatal => 'Prenatal visit',
    AppointmentType.gynecologist => 'Gynecologist visit',
    AppointmentType.ultrasound => 'Ultrasound',
    AppointmentType.bloodTest => 'Blood test',
    AppointmentType.labTest => 'Lab test',
    AppointmentType.midwife => 'Midwife appointment',
    AppointmentType.hospital => 'Hospital appointment',
    AppointmentType.other => 'Other health visit',
  };

  void _settings(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: .88,
      maxChildSize: .94,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
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
                  color: Theme.of(sheetContext).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              'Settings',
              style: Theme.of(sheetContext).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpace.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.rose,
                child: Text(
                  _profileInitial(controller.profile!.name),
                  style: const TextStyle(color: AppColors.plum),
                ),
              ),
              title: const Text('Your profile'),
              subtitle: Text(controller.profile!.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editName(sheetContext),
            ),
            const Divider(),
            Text(
              'SUPPORT & FEEDBACK',
              style: Theme.of(sheetContext).textTheme.labelSmall,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.ios_share_outlined),
              title: const Text('Share the app'),
              subtitle: const Text('Invite someone who may find it useful.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _shareApp(sheetContext),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: const Text('Contact us'),
              subtitle: const Text('Send feedback or ask for help.'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _contactSupport(sheetContext),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.star_outline_rounded),
              title: const Text('Rate us'),
              subtitle: const Text('A rating helps others find the app.'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _rateApp(sheetContext),
            ),
            const Divider(),
            Text('LEGAL', style: Theme.of(sheetContext).textTheme.labelSmall),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openPrivacyPolicy(sheetContext),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.article_outlined),
              title: const Text('Terms of use'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLegalDocument(
                sheetContext,
                title: 'Terms of use',
                sections: _termsOfUse,
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.critical,
              ),
              title: const Text('Delete all data'),
              subtitle: const Text('This removes locally saved health data.'),
              onTap: () => _confirmDelete(sheetContext),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _editName(BuildContext context) async {
    final name = TextEditingController(text: controller.profile!.name);
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Edit your name'),
          content: TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveName(
              dialog,
              name,
              (value) => setDialog(() => error = value),
            ),
            decoration: InputDecoration(
              labelText: 'Your name',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _saveName(
                dialog,
                name,
                (value) => setDialog(() => error = value),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
  }

  Future<void> _saveName(
    BuildContext dialog,
    TextEditingController name,
    ValueChanged<String?> setError,
  ) async {
    if (name.text.trim().isEmpty) {
      setError('Enter your name to continue.');
      return;
    }
    await controller.updateName(name.text);
    if (dialog.mounted) Navigator.pop(dialog);
  }

  Future<void> _shareApp(BuildContext context) => SharePlus.instance.share(
    ShareParams(
      title: 'Period Calendar & Pregnancy',
      subject: 'Period Calendar & Pregnancy',
      text:
          'I’m using Period Calendar & Pregnancy for private cycle, fertility, and pregnancy tracking: $_storeUrl',
      sharePositionOrigin: _shareOrigin(context),
    ),
  );

  Future<void> _contactSupport(BuildContext context) async {
    final didLaunch = await launchUrl(
      Uri(
        scheme: 'mailto',
        path: _supportEmail,
        queryParameters: const {
          'subject': 'Period Calendar & Pregnancy support',
        },
      ),
    );
    if (!didLaunch && context.mounted) {
      _showMessage(context, 'Couldn’t open an email app.');
    }
  }

  Future<void> _rateApp(BuildContext context) async {
    final didLaunch = await launchUrl(
      Uri.parse(_storeUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!didLaunch && context.mounted) {
      _showMessage(context, 'The app store listing is not available yet.');
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final didLaunch = await launchUrl(
      Uri.parse(_privacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!didLaunch && context.mounted) {
      _showMessage(context, 'Couldn’t open the privacy policy.');
    }
  }

  void _showLegalDocument(
    BuildContext context, {
    required String title,
    required List<_LegalSection> sections,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _LegalDocumentPage(title: title, sections: sections),
    ),
  );

  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  void _showMessage(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );

  void _confirmDelete(BuildContext context) => showDialog(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Delete all locally saved data?'),
      content: const Text(
        'This cannot be undone. Your health data will be removed from this device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await controller.deleteAllData();
            if (dialog.mounted) Navigator.pop(dialog);
          },
          child: const Text(
            'Delete',
            style: TextStyle(color: AppColors.critical),
          ),
        ),
      ],
    ),
  );
  void _painHub(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) {
      final pregnancy = controller.healthContext.isPregnancy;
      return DraggableScrollableSheet(
        initialChildSize: .7,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: Theme.of(sheet).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              Text(
                pregnancy ? 'Discomfort' : 'Period pain',
                style: Theme.of(sheet).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                pregnancy
                    ? 'Keep a personal note of discomfort, without assumptions.'
                    : 'Understand your pain patterns, without assumptions.',
                style: Theme.of(sheet).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.lg),
              SurfaceCard(
                color: AppColors.berry.withValues(alpha: .1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TODAY', style: Theme.of(sheet).textTheme.labelSmall),
                    const SizedBox(height: 6),
                    Text(
                      controller.logFor(DateTime.now())?.painIntensity == null
                          ? pregnancy
                                ? 'Discomfort not logged'
                                : 'Pain not logged'
                          : '${pregnancy ? 'Discomfort' : 'Pain'} ${controller.logFor(DateTime.now())!.painIntensity}/10',
                      style: Theme.of(sheet).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pregnancy
                          ? 'A score records your experience; it cannot assess pregnancy health or determine a cause.'
                          : 'A score records your experience; it cannot determine a cause.',
                      style: Theme.of(sheet).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              SurfaceCard(
                child: Text(
                  pregnancy
                      ? 'If discomfort, bleeding, or symptoms concern you, contact a healthcare professional.'
                      : 'If pain is severe, notably different for you, or disrupts daily life, consider discussing it with a qualified healthcare professional.',
                  style: Theme.of(sheet).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              PrimaryButton(
                label: pregnancy
                    ? 'Log discomfort details'
                    : 'Log pain details',
                icon: Icons.add,
                onPressed: () {
                  Navigator.pop(sheet);
                  _track(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

const _supportEmail = String.fromEnvironment(
  'SUPPORT_EMAIL',
  defaultValue: 'support@periodcalendar.app',
);
const _storeUrl = String.fromEnvironment(
  'STORE_URL',
  defaultValue: 'https://apps.apple.com/app/id6809212113',
);
const _privacyPolicyUrl = String.fromEnvironment(
  'PRIVACY_POLICY_URL',
  defaultValue:
      'https://periodcalendarpregnancy.blogspot.com/2026/09/blog-post.html',
);

String _profileInitial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

const _termsOfUse = <_LegalSection>[
  _LegalSection(
    'General information only',
    'Period Calendar & Pregnancy provides tracking, wellbeing, meal, and educational tools. It does not provide diagnosis, treatment, medical advice, or emergency care.',
  ),
  _LegalSection(
    'Your health decisions',
    'Cycle, fertility, and pregnancy dates are estimates. Always use your own judgement and contact a qualified healthcare professional for personalised advice or urgent symptoms.',
  ),
  _LegalSection(
    'Using AI features',
    'AI-generated replies can be incomplete or incorrect. Do not rely on them for urgent decisions, medication instructions, test interpretation, or confirmation of a pregnancy or health condition.',
  ),
  _LegalSection(
    'Respectful use',
    'Use the app lawfully and keep your device secure. You are responsible for deciding what information to record or share.',
  ),
];

class _LegalDocumentPage extends StatelessWidget {
  const _LegalDocumentPage({required this.title, required this.sections});

  final String title;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.xxl,
        ),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Last updated September 2026',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.xl),
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    section.body,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
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

class _PregnancySetupFields extends StatefulWidget {
  const _PregnancySetupFields({
    required this.initialHeightText,
    required this.builder,
  });

  final String initialHeightText;
  final Widget Function(
    TextEditingController startingWeight,
    TextEditingController height,
  )
  builder;

  @override
  State<_PregnancySetupFields> createState() => _PregnancySetupFieldsState();
}

class _PregnancySetupFieldsState extends State<_PregnancySetupFields> {
  late final TextEditingController _startingWeight = TextEditingController();
  late final TextEditingController _height = TextEditingController(
    text: widget.initialHeightText,
  );

  @override
  void dispose() {
    _startingWeight.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(_startingWeight, _height);
}
