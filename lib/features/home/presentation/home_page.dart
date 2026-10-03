import 'package:flutter/material.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';
import '../../shared/domain/health_mode_service.dart';
import '../../pregnancy/domain/pregnancy_timeline.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.profile,
    required this.prediction,
    required this.periods,
    required this.appointments,
    required this.onTrack,
    required this.onPainHub,
    required this.onProfile,
    required this.onPregnancy,
    required this.onAddReminder,
    required this.onAddNote,
    required this.onAddSymptoms,
    required this.onCalendar,
    required this.onFood,
    required this.healthContext,
  });
  final UserProfile profile;
  final CyclePrediction prediction;
  final List<PeriodEntry> periods;
  final List<PregnancyAppointment> appointments;
  final VoidCallback onTrack,
      onPainHub,
      onProfile,
      onPregnancy,
      onAddReminder,
      onAddNote,
      onAddSymptoms,
      onCalendar,
      onFood;
  final ActiveHealthContext healthContext;
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final state = _todayState(today, healthContext);
    final isPregnancy = healthContext.isPregnancy;
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning, ${profile.name}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A gentle check-in, on your terms.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open settings',
                    onPressed: onProfile,
                    icon: CircleAvatar(
                      backgroundColor: AppColors.rose,
                      child: Text(
                        _initial(profile.name),
                        style: const TextStyle(color: AppColors.plum),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              _CycleHero(
                state: state,
                prediction: prediction,
                dueDate: profile.estimatedDueDate,
                onTap: isPregnancy ? onPregnancy : onTrack,
              ),
              const SizedBox(height: AppSpace.lg),
              if (isPregnancy) ...[
                Row(
                  children: [
                    Expanded(
                      child: _DashboardActionButton(
                        icon: Icons.edit_note_outlined,
                        title: 'ADD NOTE',
                        color: AppColors.berry,
                        onTap: onAddNote,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _DashboardActionButton(
                        icon: Icons.notifications_active_outlined,
                        title: 'SET REMINDER',
                        color: AppColors.pregnancy,
                        onTap: onAddReminder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardActionButton(
                        icon: Icons.medical_information_outlined,
                        title: 'ADD SYMPTOMS',
                        color: AppColors.berry,
                        onTap: onAddSymptoms,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _DashboardActionButton(
                        icon: Icons.restaurant_outlined,
                        title: 'AI CHEF',
                        color: AppColors.fertility,
                        onTap: onFood,
                      ),
                    ),
                  ],
                ),
              ],
              if (!isPregnancy) ...[
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: isPregnancy
                            ? 'ADD NOTE'
                            : state.isPeriod
                            ? 'TODAY'
                            : 'NEXT PERIOD',
                        value: isPregnancy
                            ? 'Write a private note'
                            : state.isPeriod
                            ? state.title
                            : prediction.nextPeriod == null
                            ? 'Building'
                            : '~${prediction.nextPeriod!.difference(today).inDays} days',
                        icon: isPregnancy
                            ? Icons.edit_note_outlined
                            : state.isPeriod
                            ? Icons.water_drop_outlined
                            : Icons.calendar_month_outlined,
                        color: isPregnancy
                            ? AppColors.pregnancy
                            : state.isPeriod
                            ? AppColors.berry
                            : AppColors.fertility,
                        onTap: isPregnancy ? onAddNote : null,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _Metric(
                        label: isPregnancy ? 'SET REMINDER' : 'CYCLE LENGTH',
                        value: isPregnancy
                            ? 'Set one now'
                            : prediction.averageLength == null
                            ? 'Building'
                            : '${prediction.averageLength!.round()} days',
                        icon: isPregnancy
                            ? Icons.notifications_active_outlined
                            : Icons.timeline_outlined,
                        color: isPregnancy
                            ? AppColors.pregnancy
                            : AppColors.fertility,
                        onTap: isPregnancy ? onAddReminder : null,
                      ),
                    ),
                  ],
                ),
                if (!isPregnancy) ...[
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: isPregnancy
                              ? 'ADD SYMPTOMS'
                              : 'TODAY\'S PHASE',
                          value: isPregnancy
                              ? 'Log how you feel'
                              : state.shortLabel,
                          icon: isPregnancy
                              ? Icons.medical_information_outlined
                              : state.icon,
                          color: isPregnancy
                              ? AppColors.pregnancy
                              : state.color,
                          onTap: isPregnancy ? onAddSymptoms : onCalendar,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _Metric(
                          label: 'NUTRITION',
                          value: _foodLabel(),
                          icon: Icons.restaurant_outlined,
                          color: AppColors.warning,
                          onTap: onFood,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
                  SurfaceCard(
                    color: AppColors.plum,
                    onTap: onPainHub,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.health_and_safety_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Period pain, in context',
                                style: Theme.of(context).textTheme.titleMedium!
                                    .copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Track what affects your day and find calm, sourced guidance.',
                                style: TextStyle(
                                  color: Color(0xFFF2DFE9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ],
            ]),
          ),
        ),
      ],
    );
  }

  _TodayState _todayState(DateTime today, ActiveHealthContext context) {
    if (context.isPregnancy) {
      return _TodayState.pregnancy(profile.estimatedDueDate);
    }
    final period = periods
        .where(
          (entry) =>
              !_day(today).isBefore(_day(entry.start)) &&
              !_day(today).isAfter(_day(entry.end)),
        )
        .cast<PeriodEntry?>()
        .firstOrNull;
    if (period != null) {
      final number = _day(today).difference(_day(period.start)).inDays + 1;
      return _TodayState.period(number);
    }
    final fertileStart = prediction.fertileStart,
        fertileEnd = prediction.fertileEnd,
        ovulationStart = prediction.ovulationStart,
        ovulationEnd = prediction.ovulationEnd;
    if (fertileStart != null &&
        fertileEnd != null &&
        !today.isBefore(_day(fertileStart)) &&
        !today.isAfter(_day(fertileEnd))) {
      final ovulation =
          ovulationStart != null &&
          ovulationEnd != null &&
          !today.isBefore(_day(ovulationStart)) &&
          !today.isAfter(_day(ovulationEnd));
      return ovulation ? _TodayState.ovulation() : _TodayState.fertile();
    }
    final day = profile.lastPeriodStart == null
        ? null
        : _day(today).difference(_day(profile.lastPeriodStart!)).inDays + 1;
    return _TodayState.cycle(day);
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  String _foodLabel() => 'AI Chef';
}

String _initial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

class _TodayState {
  const _TodayState({
    required this.title,
    required this.shortLabel,
    required this.detail,
    required this.advice,
    required this.icon,
    required this.color,
    this.cycleDay,
    this.dayCaption = 'CYCLE DAY',
    this.isPeriod = false,
  });
  final String title, shortLabel, detail, advice, dayCaption;
  final IconData icon;
  final Color color;
  final int? cycleDay;
  final bool isPeriod;
  factory _TodayState.period(int day) => _TodayState(
    title: 'Period · day $day',
    shortLabel: 'Period day $day',
    detail: 'Recorded period day · track flow, symptoms, and comfort.',
    advice: day == 1
        ? 'A low-demand day can be enough. Choose comfort measures that work for you, and log anything that feels different.'
        : 'Notice what supports you today. Logging flow and symptoms can help you recognise your own pattern.',
    icon: Icons.water_drop_rounded,
    color: AppColors.berry,
    cycleDay: day,
    isPeriod: true,
  );
  factory _TodayState.fertile() => const _TodayState(
    title: 'Estimated fertile window',
    shortLabel: 'Fertility estimate',
    detail: 'This window is estimated from your logged cycle pattern.',
    advice:
        'This is an estimate, not confirmation of ovulation. If it is useful to you, add an LH test, temperature, or other observation.',
    icon: Icons.child_care_rounded,
    color: AppColors.fertility,
  );
  factory _TodayState.ovulation() => const _TodayState(
    title: 'Estimated ovulation window',
    shortLabel: 'Ovulation estimate',
    detail: 'Your cycle pattern suggests an ovulation window today.',
    advice:
        'Ovulation can vary from cycle estimates. A quick check-in can add useful context without making assumptions.',
    icon: Icons.auto_awesome_rounded,
    color: AppColors.fertility,
  );
  factory _TodayState.cycle(int? day) => _TodayState(
    title: day == null ? 'Your cycle, your rhythm' : 'Cycle day $day',
    shortLabel: day == null ? 'Set up cycle' : 'Cycle day $day',
    detail: 'Predictions become more personal as you log cycles.',
    advice:
        'A short daily check-in is enough. You can log only what feels useful today.',
    icon: Icons.timeline_outlined,
    color: AppColors.berry,
    cycleDay: day,
  );
  factory _TodayState.pregnancy(DateTime? due) {
    final week = PregnancyTimeline.fromDueDate(due);
    return _TodayState(
      title: week == null ? 'Pregnancy tracking' : 'Week ${week.week}',
      shortLabel: week == null
          ? 'Setup needed'
          : '${week.trimester} · week ${week.week}',
      detail: week == null
          ? 'Add a due date when you are ready to see a weekly timeline.'
          : '${week.week} weeks + ${week.day} days · based on your entered due date.',
      advice:
          'Use this space for symptoms, appointments, and questions for your clinician. Tracking alone cannot assess pregnancy health.',
      icon: Icons.pregnant_woman_outlined,
      color: AppColors.pregnancy,
      cycleDay: week?.week,
      dayCaption: 'WEEK',
    );
  }
}

class _CycleHero extends StatelessWidget {
  const _CycleHero({
    required this.state,
    required this.prediction,
    required this.dueDate,
    required this.onTap,
  });
  final _TodayState state;
  final CyclePrediction prediction;
  final DateTime? dueDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cycleLength = prediction.averageLength?.round() ?? 29;
    final progress = state.cycleDay == null
        ? .16
        : (state.cycleDay! / cycleLength).clamp(.05, .98);
    return Semantics(
      button: true,
      label: '${state.title}. ${state.detail}. ${state.advice}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  state.color,
                  Color.lerp(state.color, AppColors.plum, .52)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PhasePill(state: state),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.title,
                            style: Theme.of(context).textTheme.headlineMedium!
                                .copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.detail,
                            style: const TextStyle(
                              color: Color(0xFFF8EAF0),
                              height: 1.35,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _DayBadge(day: state.cycleDay, caption: state.dayCaption),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: .20),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFFFE5AB),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.advice,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.35,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
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

class _PhasePill extends StatelessWidget {
  const _PhasePill({required this.state});
  final _TodayState state;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(state.icon, size: 14, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          state.shortLabel.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .7,
          ),
        ),
      ],
    ),
  );
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.day, required this.caption});
  final int? day;
  final String caption;
  @override
  Widget build(BuildContext context) => Container(
    width: 88,
    height: 88,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          day?.toString() ?? '•',
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
            color: Colors.white,
            fontSize: 38,
          ),
        ),
        Text(
          day == null ? 'TODAY' : caption,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
      ],
    ),
  );
}

class _DashboardActionButton extends StatelessWidget {
  const _DashboardActionButton({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 104,
    child: SurfaceCard(
      onTap: onTap,
      color: color.withValues(alpha: .09),
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.plum,
              fontSize: 14,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 116,
    child: SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(height: AppSpace.sm),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
