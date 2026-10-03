import 'package:flutter/material.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';

Future<void> showSavedRemindersSheet(
  BuildContext context, {
  required List<PregnancyAppointment> appointments,
  required VoidCallback onAddReminder,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _SavedRemindersSheet(
    appointments: appointments,
    onAddReminder: onAddReminder,
  ),
);

class _SavedRemindersSheet extends StatelessWidget {
  const _SavedRemindersSheet({
    required this.appointments,
    required this.onAddReminder,
  });
  final List<PregnancyAppointment> appointments;
  final VoidCallback onAddReminder;

  @override
  Widget build(BuildContext context) {
    final reminders =
        appointments.where((item) => item.reminderAt != null).toList()
          ..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
    return DraggableScrollableSheet(
      initialChildSize: .62,
      minChildSize: .42,
      maxChildSize: .9,
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
              'Set a reminder',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              reminders.isEmpty
                  ? 'No reminders are saved yet. Set one with a date, time and private message.'
                  : 'Your saved appointment reminders. Tap one to review its details.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpace.lg),
            if (reminders.isEmpty)
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notifications_none,
                      color: AppColors.pregnancy,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your reminders will appear here.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            else
              ...reminders.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: SurfaceCard(
                    onTap: () => _openDetails(context, item),
                    child: Row(
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
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Reminder · ${_dateTime(context, item.reminderAt!)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpace.sm),
            PrimaryButton(
              label: 'Set a new reminder',
              icon: Icons.add_alert_outlined,
              onPressed: () {
                Navigator.pop(context);
                onAddReminder();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(
    BuildContext context,
    PregnancyAppointment item,
  ) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
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
          Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          _Detail(
            label: 'APPOINTMENT',
            value: _dateTime(context, item.dateTime),
          ),
          _Detail(
            label: 'REMINDER',
            value: _dateTime(context, item.reminderAt!),
          ),
          if (item.clinicName != null)
            _Detail(label: 'CLINIC', value: item.clinicName!),
          if (item.doctorName != null)
            _Detail(label: 'DOCTOR', value: item.doctorName!),
          if (item.reminderMessage != null && item.reminderMessage!.isNotEmpty)
            _Detail(label: 'REMINDER MESSAGE', value: item.reminderMessage!),
          if (item.notes != null && item.notes!.isNotEmpty)
            _Detail(label: 'PRIVATE NOTE', value: item.notes!),
          const SizedBox(height: AppSpace.lg),
          PrimaryButton(
            label: 'Done',
            icon: Icons.check,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );

  String _dateTime(BuildContext context, DateTime date) =>
      '${date.day}/${date.month}/${date.year} · ${TimeOfDay.fromDateTime(date).format(context)}';
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}
