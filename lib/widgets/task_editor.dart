import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_tile.dart';

class TaskEditor extends StatefulWidget {
  final Task? task;
  final List<String> categories;
  final bool showPriority, showCategories;
  final String Function() newId;

  const TaskEditor({
    super.key,
    this.task,
    required this.categories,
    required this.showPriority,
    required this.showCategories,
    required this.newId,
  });

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  late final TextEditingController _title =
      TextEditingController(text: widget.task?.title ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.task?.note ?? '');
  late Priority _priority = widget.task?.priority ?? Priority.medium;
  late String _category = widget.task?.category ??
      (widget.categories.isNotEmpty ? widget.categories.first : 'عام');
  late DateTime? _due = widget.task?.dueDate;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final t = widget.task;
    Navigator.pop(
      context,
      Task(
        id: t?.id ?? widget.newId(),
        title: title,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        done: t?.done ?? false,
        priority: _priority,
        category: _category,
        createdAt: t?.createdAt,
        dueDate: _due,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = {...widget.categories, _category}.toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.task == null ? 'مهمة جديدة' : 'تعديل المهمة',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            autofocus: widget.task == null,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'عنوان المهمة',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ملاحظة (اختياري)',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.showPriority) ...[
            const SizedBox(height: 12),
            SegmentedButton<Priority>(
              segments: [
                for (final p in Priority.values.reversed)
                  ButtonSegment(
                    value: p,
                    label: Text(TaskTile.priorityLabel(p)),
                    icon: Icon(Icons.flag, color: TaskTile.priorityColor(p)),
                  ),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
          ],
          if (widget.showCategories) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                for (final c in cats)
                  ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.event),
                label: Text(_due == null
                    ? 'إضافة موعد'
                    : '${_due!.year}/${_due!.month}/${_due!.day}'),
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _due ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 5),
                  );
                  if (d != null) setState(() => _due = d);
                },
              ),
              if (_due != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _due = null),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
