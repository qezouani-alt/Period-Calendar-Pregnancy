import 'package:flutter/material.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';
import '../domain/pregnancy_timeline.dart';

class PregnancyCalendar extends StatefulWidget {
  const PregnancyCalendar({
    super.key,
    required this.dueDate,
    required this.journal,
    required this.appointments,
    required this.onSaveNote,
    required this.onSaveAppointment,
    required this.onRemoveAppointment,
  });
  final DateTime? dueDate;
  final Map<String, String> journal;
  final List<PregnancyAppointment> appointments;
  final Future<void> Function(DateTime, String) onSaveNote;
  final Future<void> Function(PregnancyAppointment) onSaveAppointment;
  final Future<void> Function(String) onRemoveAppointment;
  @override
  State<PregnancyCalendar> createState() => _PregnancyCalendarState();
}

class _PregnancyCalendarState extends State<PregnancyCalendar> {
  late DateTime month, selected;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    month = DateTime(now.year, now.month);
    selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final offset = first.weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((offset + days + 6) ~/ 7) * 7;
    final week = PregnancyTimeline.fromDueDate(
      widget.dueDate,
      onDate: selected,
    );
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
                'Pregnancy calendar',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                week?.label ??
                    'Add a due date to see your estimated week and day.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.lg),
              SurfaceCard(
                child: Column(
                  children: [
                    _MonthHeader(
                      month: month,
                      onPrevious: () => setState(
                        () => month = DateTime(month.year, month.month - 1),
                      ),
                      onNext: () => setState(
                        () => month = DateTime(month.year, month.month + 1),
                      ),
                    ),
                    Row(
                      children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                          .map(
                            (day) => Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    day,
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
                      itemCount: cells,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 5,
                          ),
                      itemBuilder: (_, index) {
                        final day = index - offset + 1;
                        if (day < 1 || day > days) return const SizedBox();
                        final date = DateTime(month.year, month.month, day);
                        return _PregnancyDayCell(
                          date: date,
                          selected: _same(date, selected),
                          appointments: _appointments(date),
                          note: widget.journal[_key(date)],
                          onTap: () {
                            setState(() => selected = date);
                            _openDay(date);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              _SelectedDayCard(
                date: selected,
                week: week,
                note: widget.journal[_key(selected)],
                appointments: _appointments(selected),
                onTap: () => _openDay(selected),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  List<PregnancyAppointment> _appointments(DateTime date) => widget.appointments
      .where(
        (item) =>
            _same(item.dateTime, date) &&
            item.status == AppointmentStatus.upcoming,
      )
      .toList();
  void _openDay(DateTime date) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) => _DaySheet(
      date: date,
      week: PregnancyTimeline.fromDueDate(widget.dueDate, onDate: date),
      note: widget.journal[_key(date)],
      appointments: _appointments(date),
      onSaveNote: widget.onSaveNote,
      onSaveAppointment: widget.onSaveAppointment,
      onRemoveAppointment: widget.onRemoveAppointment,
    ),
  );
  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime month;
  final VoidCallback onPrevious, onNext;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
      Expanded(
        child: Text(
          _name(month),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
    ],
  );
  String _name(DateTime d) => const [
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
}

class _PregnancyDayCell extends StatelessWidget {
  const _PregnancyDayCell({
    required this.date,
    required this.selected,
    required this.appointments,
    required this.note,
    required this.onTap,
  });
  final DateTime date;
  final bool selected;
  final List<PregnancyAppointment> appointments;
  final String? note;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final icon = appointments.isNotEmpty && note != null
        ? Icons.layers_outlined
        : appointments.isNotEmpty
        ? Icons.event_outlined
        : note != null
        ? Icons.edit_note_outlined
        : null;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${date.month}/${date.day}${appointments.isEmpty ? '' : '. ${appointments.length} health appointment'}${note == null ? '' : '. Private journal entry'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.pregnancy.withValues(alpha: .9) : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.pregnancy
                  : Theme.of(context).dividerColor.withValues(alpha: .35),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? Colors.white : null,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 11,
                  color: selected ? Colors.white : AppColors.pregnancy,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.date,
    required this.week,
    required this.note,
    required this.appointments,
    required this.onTap,
  });
  final DateTime date;
  final PregnancyWeek? week;
  final String? note;
  final List<PregnancyAppointment> appointments;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${date.day}/${date.month}/${date.year}'.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Text(
          week?.label ?? 'Pregnancy day',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          appointments.isNotEmpty
              ? '${appointments.first.title}${note == null ? '' : ' · Private journal entry'}'
              : note == null
              ? 'Nothing logged yet.'
              : 'Private journal entry',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          '+ ADD TO THIS DAY',
          style: TextStyle(
            color: AppColors.berry,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({
    required this.date,
    required this.week,
    required this.note,
    required this.appointments,
    required this.onSaveNote,
    required this.onSaveAppointment,
    required this.onRemoveAppointment,
  });
  final DateTime date;
  final PregnancyWeek? week;
  final String? note;
  final List<PregnancyAppointment> appointments;
  final Future<void> Function(DateTime, String) onSaveNote;
  final Future<void> Function(PregnancyAppointment) onSaveAppointment;
  final Future<void> Function(String) onRemoveAppointment;
  @override
  Widget build(BuildContext context) => Container(
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
            '${date.day}/${date.month}/${date.year}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            week?.label ?? 'Add a due date to calculate an estimated week.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (appointments.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            Text('APPOINTMENTS', style: Theme.of(context).textTheme.labelSmall),
            ...appointments.map(
              (item) => _AppointmentRow(
                item: item,
                onRemove: () async {
                  await onRemoveAppointment(item.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: AppSpace.lg),
            Text('JOURNAL', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            SurfaceCard(child: Text(note!)),
          ],
          const SizedBox(height: AppSpace.lg),
          PrimaryButton(
            label: 'Add journal note',
            icon: Icons.edit_note_outlined,
            onPressed: () => _noteEditor(context),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _appointmentEditor(context),
            icon: const Icon(Icons.event_outlined),
            label: const Text('Set reminder'),
          ),
        ],
      ),
    ),
  );
  void _noteEditor(BuildContext root) {
    final text = TextEditingController(text: note);
    showModalBottomSheet(
      context: root,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
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
                'Private journal note',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: text,
                maxLines: 5,
                autofocus: true,
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
                  await onSaveNote(date, text.text);
                  if (context.mounted) Navigator.pop(context);
                  if (root.mounted) Navigator.pop(root);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _appointmentEditor(BuildContext root) {
    showModalBottomSheet(
      context: root,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppointmentEditor(
        date: date,
        onSave: onSaveAppointment,
        onDone: () => Navigator.pop(root),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.item, required this.onRemove});
  final PregnancyAppointment item;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.event_outlined, color: AppColors.pregnancy),
    title: Text(item.title),
    subtitle: Text(
      '${TimeOfDay.fromDateTime(item.dateTime).format(context)}${item.clinicName == null ? '' : ' · ${item.clinicName}'}${item.reminderAt == null ? '' : '\nReminder · ${TimeOfDay.fromDateTime(item.reminderAt!).format(context)}${item.reminderMessage == null ? '' : ' · ${item.reminderMessage}'}'}',
    ),
    trailing: IconButton(
      onPressed: onRemove,
      tooltip: 'Remove appointment',
      icon: const Icon(Icons.delete_outline),
    ),
  );
}

class _AppointmentEditor extends StatefulWidget {
  const _AppointmentEditor({
    required this.date,
    required this.onSave,
    required this.onDone,
  });
  final DateTime date;
  final Future<void> Function(PregnancyAppointment) onSave;
  final VoidCallback onDone;
  @override
  State<_AppointmentEditor> createState() => _AppointmentEditorState();
}

class _AppointmentEditorState extends State<_AppointmentEditor> {
  AppointmentType type = AppointmentType.prenatal;
  late TimeOfDay time;
  late TimeOfDay reminderTime;
  final clinic = TextEditingController();
  final notes = TextEditingController();
  final reminderMessage = TextEditingController();
  @override
  void initState() {
    super.initState();
    time = TimeOfDay.now();
    reminderTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    clinic.dispose();
    notes.dispose();
    reminderMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      padding: const EdgeInsets.all(AppSpace.lg),
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
            Text(
              'Set reminder',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpace.md),
            DropdownButtonFormField<AppointmentType>(
              initialValue: type,
              items: AppointmentType.values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(_label(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => type = value!),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(time.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (picked != null) setState(() => time = picked);
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
                if (picked != null) setState(() => reminderTime = picked);
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
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: AppSpace.lg),
            PrimaryButton(
              label: 'Save reminder',
              onPressed: () async {
                final when = DateTime(
                  widget.date.year,
                  widget.date.month,
                  widget.date.day,
                  time.hour,
                  time.minute,
                );
                final reminderAt = DateTime(
                  widget.date.year,
                  widget.date.month,
                  widget.date.day,
                  reminderTime.hour,
                  reminderTime.minute,
                );
                await widget.onSave(
                  PregnancyAppointment(
                    id: when.microsecondsSinceEpoch.toString(),
                    type: type,
                    dateTime: when,
                    status: AppointmentStatus.upcoming,
                    clinicName: clinic.text.isEmpty ? null : clinic.text,
                    notes: notes.text.isEmpty ? null : notes.text,
                    reminderAt: reminderAt,
                    reminderMessage: reminderMessage.text.isEmpty
                        ? null
                        : reminderMessage.text,
                  ),
                );
                if (context.mounted) Navigator.pop(context);
                widget.onDone();
              },
            ),
          ],
        ),
      ),
    ),
  );
  String _label(AppointmentType value) => switch (value) {
    AppointmentType.prenatal => 'Prenatal visit',
    AppointmentType.gynecologist => 'Gynecologist',
    AppointmentType.ultrasound => 'Ultrasound',
    AppointmentType.bloodTest => 'Blood test',
    AppointmentType.labTest => 'Lab test',
    AppointmentType.midwife => 'Midwife',
    AppointmentType.hospital => 'Hospital',
    AppointmentType.other => 'Other',
  };
}
