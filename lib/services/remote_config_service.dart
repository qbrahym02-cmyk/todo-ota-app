import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// إعدادات تُجلب عن بعد من ملف JSON على GitHub.
/// أي تعديل على remote/config.json في المستودع يصل للتطبيق مباشرة
/// بدون إعادة تثبيت (عند الفتح، عند الرجوع للتطبيق، وكل بضع دقائق).
class RemoteConfig {
  final int configVersion;
  final String appTitle;
  final Color primaryColor;
  final bool darkMode;
  final String welcomeMessage;

  final bool announcementEnabled;
  final String announcementText;
  final Color announcementColor;
  final String? announcementUrl;

  final bool maintenanceMode;
  final String maintenanceMessage;

  final bool showStats;
  final bool showPriority;
  final bool showCategories;
  final bool allowDelete;
  final bool showTips;

  final List<String> categories;
  final List<String> tips;
  final List<RemoteTask> remoteTasks;

  const RemoteConfig({
    this.configVersion = 0,
    this.appTitle = 'مهامي',
    this.primaryColor = const Color(0xFF4F46E5),
    this.darkMode = false,
    this.welcomeMessage = 'أهلاً بك 👋',
    this.announcementEnabled = false,
    this.announcementText = '',
    this.announcementColor = const Color(0xFFF59E0B),
    this.announcementUrl,
    this.maintenanceMode = false,
    this.maintenanceMessage = 'التطبيق تحت الصيانة، نعود قريباً.',
    this.showStats = true,
    this.showPriority = true,
    this.showCategories = true,
    this.allowDelete = true,
    this.showTips = true,
    this.categories = const ['عام', 'عمل', 'شخصي', 'تسوق'],
    this.tips = const [],
    this.remoteTasks = const [],
  });

  static Color _color(dynamic v, Color fallback) {
    if (v is! String) return fallback;
    var hex = v.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    final n = int.tryParse(hex, radix: 16);
    return n == null ? fallback : Color(n);
  }

  factory RemoteConfig.fromJson(Map<String, dynamic> j) {
    const d = RemoteConfig();
    final ann = (j['announcement'] as Map?)?.cast<String, dynamic>() ?? {};
    final feat = (j['features'] as Map?)?.cast<String, dynamic>() ?? {};
    final maint = (j['maintenance'] as Map?)?.cast<String, dynamic>() ?? {};
    final theme = (j['theme'] as Map?)?.cast<String, dynamic>() ?? {};
    return RemoteConfig(
      configVersion: (j['config_version'] as num?)?.toInt() ?? 0,
      appTitle: j['app_title'] as String? ?? d.appTitle,
      welcomeMessage: j['welcome_message'] as String? ?? d.welcomeMessage,
      primaryColor: _color(theme['primary_color'], d.primaryColor),
      darkMode: theme['dark_mode'] as bool? ?? d.darkMode,
      announcementEnabled: ann['enabled'] as bool? ?? false,
      announcementText: ann['text'] as String? ?? '',
      announcementColor: _color(ann['color'], d.announcementColor),
      announcementUrl: ann['url'] as String?,
      maintenanceMode: maint['enabled'] as bool? ?? false,
      maintenanceMessage: maint['message'] as String? ?? d.maintenanceMessage,
      showStats: feat['show_stats'] as bool? ?? true,
      showPriority: feat['show_priority'] as bool? ?? true,
      showCategories: feat['show_categories'] as bool? ?? true,
      allowDelete: feat['allow_delete'] as bool? ?? true,
      showTips: feat['show_tips'] as bool? ?? true,
      categories: (j['categories'] as List?)?.cast<String>() ?? d.categories,
      tips: (j['tips'] as List?)?.cast<String>() ?? const [],
      remoteTasks: ((j['remote_tasks'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => RemoteTask.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class RemoteTask {
  final String id;
  final String title;
  final String? note;
  final String category;
  final String priority;

  RemoteTask({
    required this.id,
    required this.title,
    this.note,
    this.category = 'عام',
    this.priority = 'medium',
  });

  factory RemoteTask.fromJson(Map<String, dynamic> j) => RemoteTask(
        id: j['id'].toString(),
        title: j['title'] as String? ?? '',
        note: j['note'] as String?,
        category: j['category'] as String? ?? 'عام',
        priority: j['priority'] as String? ?? 'medium',
      );
}

class RemoteConfigService extends ChangeNotifier with WidgetsBindingObserver {
  static const _cacheKey = 'remote_config_cache';

  RemoteConfig _config = const RemoteConfig();
  RemoteConfig get config => _config;

  DateTime? lastFetch;
  String? lastError;
  Timer? _timer;

  /// يُستدعى عند وصول إعدادات بنسخة جديدة (لإظهار تنبيه للمستخدم).
  void Function(RemoteConfig newConfig)? onNewVersion;

  Future<void> init() async {
    // 1) حمّل آخر نسخة مخزنة (يعمل بدون إنترنت)
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        _config = RemoteConfig.fromJson(jsonDecode(cached));
      } catch (_) {}
    }
    WidgetsBinding.instance.addObserver(this);
    // 2) اجلب الجديد من السيرفر
    unawaited(refresh());
    // 3) تحديث دوري
    _timer = Timer.periodic(AppConfig.remoteRefreshInterval, (_) => refresh());
  }

  Future<bool> refresh() async {
    try {
      // cache-buster حتى لا نأخذ نسخة قديمة من الكاش
      final uri = Uri.parse(
          '${AppConfig.remoteConfigUrl}?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        lastError = 'HTTP ${res.statusCode}';
        return false;
      }
      final body = utf8.decode(res.bodyBytes);
      final newConfig = RemoteConfig.fromJson(jsonDecode(body));
      final isNewer = newConfig.configVersion > _config.configVersion &&
          lastFetch != null;
      _config = newConfig;
      lastFetch = DateTime.now();
      lastError = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      notifyListeners();
      if (isNewer) onNewVersion?.call(newConfig);
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
