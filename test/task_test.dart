import 'package:flutter_test/flutter_test.dart';
import 'package:todo_ota/models/task.dart';
import 'package:todo_ota/services/remote_config_service.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  test('Task JSON round trip', () {
    final t = Task(id: '1', title: 'اختبار', priority: Priority.high, dueDate: DateTime(2026, 8, 1));
    final back = Task.decodeList(Task.encodeList([t])).single;
    expect(back.title, 'اختبار');
    expect(back.priority, Priority.high);
    expect(back.dueDate, DateTime(2026, 8, 1));
  });

  test('remote/config.json parses', () {
    final j = jsonDecode(File('remote/config.json').readAsStringSync());
    final c = RemoteConfig.fromJson(j);
    expect(c.configVersion, 1);
    expect(c.categories, contains('عمل'));
    expect(c.remoteTasks, isNotEmpty);
    expect(c.announcementEnabled, isTrue);
  });
}
