import 'package:flutter/material.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';

Future<void> showPregnancyNotesSheet(
  BuildContext context, {
  required List<PregnancyNote> notes,
  required VoidCallback onAddNote,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _PregnancyNotesSheet(notes: notes, onAddNote: onAddNote),
);

class _PregnancyNotesSheet extends StatefulWidget {
  const _PregnancyNotesSheet({required this.notes, required this.onAddNote});

  final List<PregnancyNote> notes;
  final VoidCallback onAddNote;

  @override
  State<_PregnancyNotesSheet> createState() => _PregnancyNotesSheetState();
}

class _PregnancyNotesSheetState extends State<_PregnancyNotesSheet> {
  String _query = '';
  DateTime? _selectedDate;

  List<PregnancyNote> get _visibleNotes {
    final query = _query.trim().toLowerCase();
    final results = widget.notes.where((note) {
      final matchesSearch =
          query.isEmpty || note.text.toLowerCase().contains(query);
      final matchesDate =
          _selectedDate == null || _isSameDay(note.createdAt, _selectedDate!);
      return matchesSearch && matchesDate;
    }).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final notes = _visibleNotes;
    return Container(
      height: MediaQuery.sizeOf(context).height * .86,
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
      child: Column(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your notes',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: 'Add note',
                onPressed: _addNote,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.berry,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Private notes are saved with the date and time from your phone.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search notes',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  _selectedDate == null ? 'Date' : _date(_selectedDate!),
                ),
              ),
            ],
          ),
          if (_selectedDate != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _selectedDate = null),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear date filter'),
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: notes.isEmpty
                ? _EmptyNotes(
                    hasFilters: _query.isNotEmpty || _selectedDate != null,
                  )
                : ListView.separated(
                    itemCount: notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _NoteCard(
                      note: notes[index],
                      onTap: () => _openNote(notes[index]),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpace.sm),
          PrimaryButton(
            label: 'Write a new note',
            icon: Icons.edit_note_outlined,
            onPressed: _addNote,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 1),
      initialDate: _selectedDate ?? today,
      helpText: 'Filter notes by date',
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  void _addNote() {
    Navigator.pop(context);
    widget.onAddNote();
  }

  void _openNote(PregnancyNote note) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheet) => Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.xl,
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
          Text('Private note', style: Theme.of(sheet).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            _dateTime(note.createdAt),
            style: Theme.of(sheet).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.md),
          SurfaceCard(
            child: Text(note.text, style: Theme.of(sheet).textTheme.bodyLarge),
          ),
        ],
      ),
    ),
  );
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.hasFilters});
  final bool hasFilters;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      hasFilters
          ? 'No notes match your search or date.'
          : 'No notes saved yet.',
      style: Theme.of(context).textTheme.bodyLarge,
      textAlign: TextAlign.center,
    ),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});
  final PregnancyNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.sticky_note_2_outlined, color: AppColors.pregnancy),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                _dateTime(note.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';

String _dateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${_date(value)} · $hour:$minute';
}
