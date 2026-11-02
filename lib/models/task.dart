import 'dart:convert';

enum Priority { low, medium, high }

class Task {
  final String id;
  String title;
  String? note;
  bool done;
  Priority priority;
  String category;
  DateTime createdAt;
  DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    this.note,
    this.done = false,
    this.priority = Priority.medium,
    this.category = 'عام',
    DateTime? createdAt,
    this.dueDate,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'done': done,
        'priority': priority.name,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String,
        note: j['note'] as String?,
        done: j['done'] as bool? ?? false,
        priority: Priority.values.firstWhere(
          (p) => p.name == j['priority'],
          orElse: () => Priority.medium,
        ),
        category: j['category'] as String? ?? 'عام',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate']) : null,
      );

  static String encodeList(List<Task> tasks) =>
      jsonEncode(tasks.map((t) => t.toJson()).toList());

  static List<Task> decodeList(String raw) {
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
