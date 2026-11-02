import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';

class AppUpdate {
  final String version; // مثال: 1.0.3
  final int build; // مثال: 4
  final String notes;
  final String apkUrl;
  final bool force;

  AppUpdate({
    required this.version,
    required this.build,
    required this.notes,
    required this.apkUrl,
    required this.force,
  });
}

/// يفحص GitHub Releases لوجود إصدار أحدث من التطبيق (تحديث الكود نفسه)
/// ثم ينزّله ويثبّته من داخل التطبيق (أندرويد).
class UpdateService {
  Future<String> currentVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  Future<AppUpdate?> checkForUpdate() async {
    if (kIsWeb) return null; // نسخة الويب تتحدث تلقائياً
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final res = await http.get(Uri.parse(AppConfig.latestReleaseApi), headers: {
        'Accept': 'application/vnd.github+json'
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

      // tag بالشكل: v1.0.3+4
      final tag = (j['tag_name'] as String? ?? '').replaceFirst('v', '');
      final parts = tag.split('+');
      final version = parts.first;
      final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      if (build <= currentBuild) return null;

      final assets = (j['assets'] as List? ?? []).cast<Map<String, dynamic>>();
      final apk = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => {},
      );
      final url = apk['browser_download_url'] as String?;
      if (url == null) return null;

      final body = j['body'] as String? ?? '';
      return AppUpdate(
        version: version,
        build: build,
        notes: body.replaceAll('[force]', '').trim(),
        apkUrl: url,
        force: body.contains('[force]'),
      );
    } catch (e) {
      debugPrint('update check failed: $e');
      return null;
    }
  }

  Stream<OtaEvent> install(AppUpdate u) {
    return OtaUpdate().execute(u.apkUrl, destinationFilename: 'todo_update.apk');
  }
}
