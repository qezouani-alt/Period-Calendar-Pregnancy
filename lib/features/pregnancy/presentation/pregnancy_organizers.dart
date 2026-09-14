import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';

Future<void> showDoctorQuestionsSheet(
  BuildContext context, {
  required List<DoctorQuestion> questions,
  required Future<void> Function(DoctorQuestion) onSave,
  required Future<void> Function(String) onRemove,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _DoctorQuestionsSheet(
    questions: questions,
    onSave: onSave,
    onRemove: onRemove,
  ),
);

class _DoctorQuestionsSheet extends StatelessWidget {
  const _DoctorQuestionsSheet({
    required this.questions,
    required this.onSave,
    required this.onRemove,
  });
  final List<DoctorQuestion> questions;
  final Future<void> Function(DoctorQuestion) onSave;
  final Future<void> Function(String) onRemove;

  @override
  Widget build(BuildContext context) => _OrganizerShell(
    title: 'Questions for my doctor',
    subtitle:
        'Keep a private list for your next visit. The app does not answer or diagnose personal medical questions.',
    emptyTitle: 'Your question list starts here.',
    emptyAction: 'Add a question',
    onAdd: () => _editQuestion(context),
    children:
        (questions.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
            .map(
              (item) => SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: item.discussed,
                      onChanged: (value) => onSave(
                        DoctorQuestion(
                          id: item.id,
                          text: item.text,
                          createdAt: item.createdAt,
                          discussed: value ?? false,
                          appointmentId: item.appointmentId,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          decoration: item.discussed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete question',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onRemove(item.id),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
  );

  Future<void> _editQuestion(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Add a question'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'What would you like to ask?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await onSave(
        DoctorQuestion(
          id: '${DateTime.now().microsecondsSinceEpoch}-question',
          text: result,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}

Future<void> showPregnancyRecordsSheet(
  BuildContext context, {
  required List<PregnancyRecord> records,
  required Future<void> Function(PregnancyRecord) onSave,
  required Future<void> Function(String) onRemove,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _PregnancyRecordsSheet(
    records: records,
    onSave: onSave,
    onRemove: onRemove,
  ),
);

class _PregnancyRecordsSheet extends StatelessWidget {
  const _PregnancyRecordsSheet({
    required this.records,
    required this.onSave,
    required this.onRemove,
  });
  final List<PregnancyRecord> records;
  final Future<void> Function(PregnancyRecord) onSave;
  final Future<void> Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    final sorted = records.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _OrganizerShell(
      title: 'My Documents',
      subtitle:
          'Keep private copies of health documents and images in one place. They are never interpreted by the app.',
      emptyTitle: 'No documents saved yet.',
      emptyAction: 'Add a document',
      onAdd: () => _editRecord(context),
      children: [
        Text('Add a document', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: _UploadOption(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: _UploadOption(
                icon: Icons.photo_camera_outlined,
                label: 'Take picture',
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
            ),
          ],
        ),
        if (sorted.isEmpty)
          const SurfaceCard(
            child: Text(
              'No documents saved yet. Add a photo or a document note.',
            ),
          )
        else ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            'Saved documents',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...sorted.map(
            (item) => _DocumentCard(item: item, onRemove: onRemove),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
    );
    if (image == null || !context.mounted) return;
    final title = TextEditingController(
      text: source == ImageSource.camera
          ? 'Camera document'
          : 'Gallery document',
    );
    final note = TextEditingController();
    final result = await showDialog<_RecordDraft>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Save document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Document name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Private note (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialog,
              _RecordDraft(title.text.trim(), note.text.trim()),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.title.isEmpty) return;
    final now = DateTime.now();
    await onSave(
      PregnancyRecord(
        id: '${now.microsecondsSinceEpoch}-record',
        title: result.title,
        date: now,
        createdAt: now,
        note: result.note.isEmpty ? null : result.note,
        attachmentPaths: [image.path],
      ),
    );
  }

  Future<void> _editRecord(BuildContext context) async {
    final title = TextEditingController();
    final note = TextEditingController();
    final result = await showDialog<_RecordDraft>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Add a record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Private note (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialog,
              _RecordDraft(title.text.trim(), note.text.trim()),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.title.isNotEmpty) {
      final now = DateTime.now();
      await onSave(
        PregnancyRecord(
          id: '${now.microsecondsSinceEpoch}-record',
          title: result.title,
          date: now,
          createdAt: now,
          note: result.note.isEmpty ? null : result.note,
        ),
      );
    }
  }
}

class _UploadOption extends StatelessWidget {
  const _UploadOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    child: Column(
      children: [
        Icon(icon, color: AppColors.pregnancy),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.item, required this.onRemove});

  final PregnancyRecord item;
  final Future<void> Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    final imagePath = item.attachmentPaths.isEmpty
        ? null
        : item.attachmentPaths.first;
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DocumentPreview(path: imagePath),
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
                  '${item.date.day}/${item.date.month}/${item.date.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.note!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete document',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => onRemove(item.id),
          ),
        ],
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: 48,
      height: 48,
      child: path == null
          ? const ColoredBox(
              color: Color(0x1AC27195),
              child: Icon(
                Icons.description_outlined,
                color: AppColors.pregnancy,
              ),
            )
          : Image.file(
              File(path!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0x1AC27195),
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.pregnancy,
                ),
              ),
            ),
    ),
  );
}

class _OrganizerShell extends StatelessWidget {
  const _OrganizerShell({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptyAction,
    required this.onAdd,
    required this.children,
  });
  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptyAction;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .72,
    minChildSize: .5,
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
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpace.lg),
          if (children.isEmpty)
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emptyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: Text(emptyAction),
                  ),
                ],
              ),
            )
          else ...[
            ...children.expand(
              (item) => [item, const SizedBox(height: AppSpace.sm)],
            ),
            const SizedBox(height: AppSpace.sm),
            PrimaryButton(
              label: emptyAction,
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ],
      ),
    ),
  );
}

class _RecordDraft {
  const _RecordDraft(this.title, this.note);
  final String title;
  final String note;
}
