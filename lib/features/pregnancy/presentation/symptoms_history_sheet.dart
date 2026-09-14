import 'package:flutter/material.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';

Future<void> showSymptomsHistorySheet(
  BuildContext context, {
  required List<SymptomEntry> entries,
  required VoidCallback onAddSymptoms,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) =>
      _SymptomsHistorySheet(entries: entries, onAddSymptoms: onAddSymptoms),
);

class _SymptomsHistorySheet extends StatefulWidget {
  const _SymptomsHistorySheet({
    required this.entries,
    required this.onAddSymptoms,
  });

  final List<SymptomEntry> entries;
  final VoidCallback onAddSymptoms;

  @override
  State<_SymptomsHistorySheet> createState() => _SymptomsHistorySheetState();
}

class _SymptomsHistorySheetState extends State<_SymptomsHistorySheet> {
  String _query = '';
  DateTime? _selectedDate;

  List<SymptomEntry> get _visibleEntries {
    final query = _query.trim().toLowerCase();
    final results = widget.entries.where((entry) {
      final matchesSearch =
          query.isEmpty || entry.summary.toLowerCase().contains(query);
      final matchesDate =
          _selectedDate == null || _isSameDay(entry.createdAt, _selectedDate!);
      return matchesSearch && matchesDate;
    }).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;
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
                  'Your symptoms',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: 'Log symptoms',
                onPressed: _addSymptoms,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.berry,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Private symptom entries are saved with the date and time from your phone.',
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
                    hintText: 'Search symptoms',
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
            child: entries.isEmpty
                ? _EmptySymptoms(
                    hasFilters: _query.isNotEmpty || _selectedDate != null,
                  )
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _SymptomCard(
                      entry: entries[index],
                      onTap: () => _openEntry(entries[index]),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpace.sm),
          PrimaryButton(
            label: 'Log symptoms',
            icon: Icons.add_chart_outlined,
            onPressed: _addSymptoms,
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
      helpText: 'Filter symptoms by date',
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  void _addSymptoms() {
    Navigator.pop(context);
    widget.onAddSymptoms();
  }

  void _openEntry(SymptomEntry entry) => showModalBottomSheet<void>(
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
          Text(
            'Symptom details',
            style: Theme.of(sheet).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _dateTime(entry.createdAt),
            style: Theme.of(sheet).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.md),
          SurfaceCard(
            child: Text(
              entry.summary,
              style: Theme.of(sheet).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptySymptoms extends StatelessWidget {
  const _EmptySymptoms({required this.hasFilters});
  final bool hasFilters;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      hasFilters
          ? 'No symptom entries match your search or date.'
          : 'No symptom entries saved yet.',
      style: Theme.of(context).textTheme.bodyLarge,
      textAlign: TextAlign.center,
    ),
  );
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard({required this.entry, required this.onTap});
  final SymptomEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.medical_information_outlined,
          color: AppColors.pregnancy,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.summary.replaceAll('\n', ' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                _dateTime(entry.createdAt),
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
