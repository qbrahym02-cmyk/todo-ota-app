import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final bool showPriority, showCategory, allowDelete;
  final VoidCallback onToggle, onTap, onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.showPriority,
    required this.showCategory,
    required this.allowDelete,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  static Color priorityColor(Priority p) => switch (p) {
        Priority.high => Colors.red,
        Priority.medium => Colors.orange,
        Priority.low => Colors.green,
      };

  static String priorityLabel(Priority p) => switch (p) {
        Priority.high => 'عالية',
        Priority.medium => 'متوسطة',
        Priority.low => 'منخفضة',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = task.dueDate != null &&
        !task.done &&
        task.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    final card = Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: task.done ? scheme.surfaceContainerHighest.withValues(alpha: 0.5) : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: showPriority && !task.done
            ? BorderSide(color: priorityColor(task.priority).withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.done,
          onChanged: (_) => onToggle(),
          shape: const CircleBorder(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
            color: task.done ? scheme.outline : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (task.note != null && task.note!.isNotEmpty)
              Text(task.note!, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (showCategory)
              Text('#${task.category}', style: TextStyle(color: scheme.primary)),
            if (task.dueDate != null)
              Text(
                '📅 ${task.dueDate!.year}/${task.dueDate!.month}/${task.dueDate!.day}',
                style: TextStyle(color: overdue ? Colors.red : null),
              ),
          ],
        ),
        trailing: showPriority
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor(task.priority).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(priorityLabel(task.priority),
                    style: TextStyle(fontSize: 12, color: priorityColor(task.priority))),
              )
            : null,
      ),
    );

    if (!allowDelete) return card;
    return Dismissible(
      key: ValueKey('d_${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: card,
    );
  }
}
