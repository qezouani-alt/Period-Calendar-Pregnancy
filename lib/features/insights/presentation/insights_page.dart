import 'package:flutter/material.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';
import '../../shared/domain/health_mode_service.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({
    super.key,
    required this.prediction,
    required this.log,
    required this.healthContext,
    required this.appointments,
    required this.journalCount,
  });
  final CyclePrediction prediction;
  final DailyHealthLog? log;
  final ActiveHealthContext healthContext;
  final List<PregnancyAppointment> appointments;
  final int journalCount;
  @override
  Widget build(BuildContext context) {
    if (healthContext.isPregnancy) {
      return _PregnancyInsights(
        log: log,
        appointments: appointments,
        journalCount: journalCount,
      );
    }
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
                'Your insights',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Patterns, never judgments.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.xl),
              SectionHeader(title: 'Cycle overview'),
              const SizedBox(height: AppSpace.sm),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR CYCLE PATTERN',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _Data(
                            label: 'Average length',
                            value: prediction.averageLength == null
                                ? '—'
                                : '${prediction.averageLength!.round()} days',
                          ),
                        ),
                        Expanded(
                          child: _Data(
                            label: 'Period length',
                            value: prediction.averagePeriodLength == null
                                ? '—'
                                : '${prediction.averagePeriodLength!.round()} days',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    const _Bars(),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      prediction.confidence == PredictionConfidence.personalized
                          ? 'Your recent cycles are relatively consistent.'
                          : 'Keep tracking for a few more cycles to make estimates more personal.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              SectionHeader(title: 'Symptoms'),
              const SizedBox(height: AppSpace.sm),
              log == null
                  ? _EmptyInsight()
                  : SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TODAY',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            log!.symptoms.isEmpty
                                ? 'No symptoms were logged.'
                                : log!.symptoms.join(' · '),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (log!.painIntensity != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Pain logged at ${log!.painIntensity}/10. This is a record, not a diagnosis.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
              const SizedBox(height: AppSpace.xl),
              SurfaceCard(
                color: AppColors.fertility.withValues(alpha: .11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.fertility),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fertility estimates need context',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Cycle-based predictions may vary from actual ovulation and are not contraception.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _PregnancyInsights extends StatelessWidget {
  const _PregnancyInsights({
    required this.log,
    required this.appointments,
    required this.journalCount,
  });
  final DailyHealthLog? log;
  final List<PregnancyAppointment> appointments;
  final int journalCount;

  @override
  Widget build(BuildContext context) {
    final completed = appointments
        .where((item) => item.status == AppointmentStatus.completed)
        .length;
    final isPreview = journalCount == 0 && completed == 0 && log == null;
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
                'Your insights',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                isPreview
                    ? 'A private preview of the activity you choose to log.'
                    : 'Your pregnancy activity, without scores or judgments.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.xl),
              SectionHeader(
                title: isPreview
                    ? 'How your insights will look'
                    : 'Pregnancy activity',
              ),
              const SizedBox(height: AppSpace.sm),
              SurfaceCard(
                color: isPreview
                    ? AppColors.lavender.withValues(alpha: .14)
                    : null,
                child: Row(
                  children: [
                    Expanded(
                      child: _Data(
                        label: isPreview ? 'Example notes' : 'Journal notes',
                        value: isPreview ? '3' : '$journalCount',
                      ),
                    ),
                    Expanded(
                      child: _Data(
                        label: isPreview
                            ? 'Example visits completed'
                            : 'Appointments completed',
                        value: isPreview ? '1' : '$completed',
                      ),
                    ),
                  ],
                ),
              ),
              if (isPreview) ...[
                const SizedBox(height: 8),
                Text(
                  'EXAMPLE ONLY · Your private entries will replace this preview after you save them.',
                  style: const TextStyle(
                    color: AppColors.berry,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.xl),
              SectionHeader(
                title: isPreview ? 'Example check-in' : 'Today\'s check-in',
              ),
              const SizedBox(height: AppSpace.sm),
              isPreview
                  ? const _PregnancyInsightsPreview()
                  : log == null
                  ? const _EmptyInsight(pregnancy: true)
                  : SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TODAY',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            log!.symptoms.isEmpty
                                ? 'No symptoms were logged.'
                                : log!.symptoms.join(' · '),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your entries are personal notes, not an assessment of pregnancy health.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _PregnancyInsightsPreview extends StatelessWidget {
  const _PregnancyInsightsPreview();

  @override
  Widget build(BuildContext context) => SurfaceCard(
    color: AppColors.lavender.withValues(alpha: .14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXAMPLE · NOT YOUR HEALTH RECORD',
          style: TextStyle(
            color: AppColors.berry,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tired · Low energy',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'A saved check-in can help you remember what you wanted to discuss at your next visit. It is not a health assessment or diagnosis.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

class _Data extends StatelessWidget {
  const _Data({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(c).textTheme.headlineMedium),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(c).textTheme.bodyMedium),
    ],
  );
}

class _Bars extends StatelessWidget {
  const _Bars();
  @override
  Widget build(BuildContext c) => SizedBox(
    height: 60,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [.45, .65, .52, .7, .58, .8, .62]
          .map(
            (height) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  height: 60 * height,
                  decoration: BoxDecoration(
                    color: AppColors.berry.withValues(alpha: .25),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _EmptyInsight extends StatelessWidget {
  const _EmptyInsight({this.pregnancy = false});
  final bool pregnancy;
  @override
  Widget build(BuildContext c) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_graph_outlined, color: AppColors.fertility),
        const SizedBox(height: 12),
        Text(
          pregnancy
              ? 'Your check-ins start here.'
              : 'Your patterns grow with you.',
          style: Theme.of(c).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        Text(
          pregnancy
              ? 'Save a few pregnancy check-ins to see your personal activity here.'
              : 'Keep tracking for a few more cycles to unlock symptom and pain trends.',
          style: Theme.of(c).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'START TODAY\'S CHECK-IN',
          style: TextStyle(
            color: AppColors.berry,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
