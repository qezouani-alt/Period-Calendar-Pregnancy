import 'package:flutter/material.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    required this.profile,
    required this.prediction,
    required this.logs,
    required this.periodNotes,
    required this.periods,
    required this.onLogDate,
    required this.onStartPeriod,
    required this.onRemovePeriod,
    required this.onRemoveLog,
    required this.onQuickCheckIn,
    required this.onAddPeriodNote,
    required this.onPregnancySetup,
  });
  final UserProfile profile;
  final CyclePrediction prediction;
  final Map<String, DailyHealthLog> logs;
  final List<PeriodNote> periodNotes;
  final List<PeriodEntry> periods;
  final ValueChanged<DateTime> onLogDate,
      onStartPeriod,
      onRemovePeriod,
      onRemoveLog;
  final ValueChanged<String> onQuickCheckIn;
  final ValueChanged<DateTime> onAddPeriodNote;
  final VoidCallback onPregnancySetup;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime month;
  DateTime? selected;
  @override
  void initState() {
    super.initState();
    month = DateTime(DateTime.now().year, DateTime.now().month);
    selected = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month),
        offset = first.weekday % 7,
        days = DateTime(month.year, month.month + 1, 0).day;
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your cycle dates and estimates.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _PregnancyModeButton(onTap: widget.onPregnancySetup),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              SurfaceCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(
                            () => month = DateTime(month.year, month.month - 1),
                          ),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            _monthName(month),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(
                            () => month = DateTime(month.year, month.month + 1),
                          ),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    Row(
                      children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                          .map(
                            (label) => Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 42,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 5,
                          ),
                      itemBuilder: (_, index) {
                        final day = index - offset + 1;
                        if (day < 1 || day > days) {
                          return const SizedBox();
                        }
                        final date = DateTime(month.year, month.month, day);
                        final state = _state(date);
                        final chosen = _same(selected!, date);
                        return Semantics(
                          button: true,
                          label: '${_monthName(date)} $day, $state',
                          child: InkWell(
                            onTap: () {
                              setState(() => selected = date);
                              _openDaySheet(date);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: chosen
                                    ? AppColors.plum
                                    : state == 'Period' ||
                                          state == 'Period estimate'
                                    ? AppColors.rose.withValues(alpha: .42)
                                    : state == 'Fertile estimate'
                                    ? AppColors.lavender.withValues(alpha: .38)
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                border: state == 'Ovulation estimate'
                                    ? Border.all(
                                        color: AppColors.fertility,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: _CalendarDayLabel(
                                day: day,
                                state: state,
                                selected: chosen,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedTitle(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _state(selected!),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _detail(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_periodNotesFor(selected!).isNotEmpty) ...[
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        '${_periodNotesFor(selected!).length} private ${_periodNotesFor(selected!).length == 1 ? 'note' : 'notes'} saved for this date.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => widget.onLogDate(selected!),
                      child: Text(
                        _log(selected!) == null ? '+ Log this day' : 'Edit day',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              SurfaceCard(
                onTap: () => widget.onAddPeriodNote(selected!),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: AppColors.berry),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        _periodNotesFor(selected!).isEmpty
                            ? 'Add note'
                            : 'View notes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              const SectionHeader(title: 'How are you feeling today?'),
              const SizedBox(height: AppSpace.sm),
              _CycleFeelingCard(onSelected: widget.onQuickCheckIn),
            ]),
          ),
        ),
      ],
    );
  }

  String _detail() {
    if (_state(selected!) == 'Fertile estimate' ||
        _state(selected!) == 'Ovulation estimate') {
      return 'This window is estimated from your cycle history and can vary from actual ovulation.';
    }
    if (_state(selected!) == 'Period estimate') {
      return 'This period date is estimated from your recorded cycle history and can shift.';
    }
    final log = _log(selected!);
    if (log != null) {
      return '${log.symptoms.join(' · ')}${log.painIntensity != null ? ' · Pain ${log.painIntensity}/10' : ''}';
    }
    return 'Add a note or log a symptom for this date.';
  }

  String _state(DateTime d) {
    if (widget.periods.any(
      (entry) => !d.isBefore(_day(entry.start)) && !d.isAfter(_day(entry.end)),
    )) {
      return 'Period';
    }
    for (final forecast in widget.prediction.futureCycles) {
      if (_inRange(d, forecast.periodStart, forecast.periodEnd)) {
        return 'Period estimate';
      }
      if (_inRange(d, forecast.fertileStart, forecast.fertileEnd)) {
        return _inRange(d, forecast.ovulationStart, forecast.ovulationEnd)
            ? 'Ovulation estimate'
            : 'Fertile estimate';
      }
    }
    return 'No entry';
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool _inRange(DateTime value, DateTime start, DateTime end) =>
      !value.isBefore(_day(start)) && !value.isAfter(_day(end));
  String _selectedTitle() =>
      '${_monthName(selected!)} ${selected!.day}'.toUpperCase();
  String _monthName(DateTime d) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][d.month - 1];
  DailyHealthLog? _log(DateTime date) =>
      widget.logs['${date.year}-${date.month}-${date.day}'];
  List<PeriodNote> _periodNotesFor(DateTime date) =>
      widget.periodNotes
          .where(
            (note) =>
                note.date.year == date.year &&
                note.date.month == date.month &&
                note.date.day == date.day,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);
  void _openDaySheet(DateTime date) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheet) {
      final log = _log(date);
      final period = _periodAt(date);
      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.xxl,
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
              '${_monthName(date)} ${date.day}',
              style: Theme.of(sheet).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(_state(date), style: Theme.of(sheet).textTheme.bodyMedium),
            if (log != null) ...[
              const SizedBox(height: AppSpace.md),
              SurfaceCard(
                child: Text(
                  log.symptoms.isEmpty
                      ? 'A log was saved for this day.'
                      : '${log.symptoms.join(' · ')}${log.painIntensity == null ? '' : ' · Pain ${log.painIntensity}/10'}',
                ),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            PrimaryButton(
              label: log == null ? 'Log this day' : 'Edit day',
              icon: Icons.edit_outlined,
              onPressed: () {
                Navigator.pop(sheet);
                widget.onLogDate(date);
              },
            ),
            if (period == null)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(sheet);
                  widget.onStartPeriod(date);
                },
                icon: const Icon(Icons.water_drop_outlined),
                label: const Text('Period started on this date'),
              )
            else
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(sheet);
                  widget.onRemovePeriod(period.start);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.critical,
                ),
                label: const Text(
                  'Remove this period entry',
                  style: TextStyle(color: AppColors.critical),
                ),
              ),
            if (log != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  widget.onRemoveLog(date);
                },
                child: const Text(
                  'Delete this day\'s log',
                  style: TextStyle(color: AppColors.critical),
                ),
              ),
          ],
        ),
      );
    },
  );
  PeriodEntry? _periodAt(DateTime date) {
    for (final entry in widget.periods) {
      if (!date.isBefore(_day(entry.start)) && !date.isAfter(_day(entry.end))) {
        return entry;
      }
    }
    return null;
  }
}

class _CycleFeelingCard extends StatelessWidget {
  const _CycleFeelingCard({required this.onSelected});

  final ValueChanged<String> onSelected;

  static const _feelings = [
    'Good',
    'Calm',
    'Low energy',
    'Cramps',
    'Bloated',
    'Emotional',
    'Headache',
    'Dizzy',
    'Anxious',
    'Low mood',
  ];

  IconData _iconFor(String feeling) => switch (feeling) {
    'Good' => Icons.sentiment_very_satisfied_rounded,
    'Calm' => Icons.sentiment_satisfied_rounded,
    'Low energy' => Icons.sentiment_neutral_rounded,
    'Cramps' => Icons.sentiment_dissatisfied_rounded,
    'Bloated' => Icons.sentiment_dissatisfied_rounded,
    'Emotional' => Icons.face_rounded,
    'Headache' => Icons.sentiment_very_dissatisfied_rounded,
    'Dizzy' => Icons.sick_rounded,
    'Anxious' => Icons.sentiment_dissatisfied_rounded,
    'Low mood' => Icons.sentiment_very_dissatisfied_rounded,
    _ => Icons.sentiment_neutral_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: AppColors.rose.withValues(alpha: .07),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - AppSpace.sm) / 2;
          return Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: _feelings
                .map(
                  (feeling) => SizedBox(
                    width: tileWidth,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () => onSelected(feeling),
                      icon: Icon(
                        _iconFor(feeling),
                        color: AppColors.berry,
                        size: 20,
                      ),
                      label: Text(
                        feeling,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _CalendarDayLabel extends StatelessWidget {
  const _CalendarDayLabel({
    required this.day,
    required this.state,
    required this.selected,
  });
  final int day;
  final String state;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isPeriod = state == 'Period' || state == 'Period estimate';
    final isFertility =
        state == 'Fertile estimate' || state == 'Ovulation estimate';
    final icon = isPeriod
        ? Icons.water_drop_rounded
        : isFertility
        ? Icons.child_care_rounded
        : null;
    final markerColor = selected
        ? Colors.white
        : isPeriod
        ? AppColors.berry
        : AppColors.fertility;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? Colors.white : null,
            ),
          ),
          if (icon != null)
            Icon(icon, size: 10, color: markerColor, semanticLabel: null),
        ],
      ),
    );
  }
}

class _PregnancyModeButton extends StatelessWidget {
  const _PregnancyModeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'I’m pregnant',
      child: Material(
        color: AppColors.pregnancy.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.child_care_rounded,
                  size: 18,
                  color: AppColors.pregnancy,
                ),
                const SizedBox(width: 6),
                Text(
                  'I’m pregnant',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.plum,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
