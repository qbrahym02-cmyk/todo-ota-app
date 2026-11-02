import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

/// تخزين المهام محلياً على الجهاز.
class TaskStorage {
  static const _key = 'tasks_v1';
  static const _seenRemoteKey = 'seen_remote_task_ids';

  Future<List<Task>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return Task.decodeList(raw);
  }

  Future<void> save(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, Task.encodeList(tasks));
  }

  /// معرّفات المهام المرسلة عن بعد التي أُضيفت سابقاً (حتى لا تتكرر).
  Future<Set<String>> seenRemoteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_seenRemoteKey) ?? []).toSet();
  }

  Future<void> markRemoteSeen(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_seenRemoteKey) ?? []).toSet()
      ..addAll(ids);
    await prefs.setStringList(_seenRemoteKey, current.toList());
  }
}
