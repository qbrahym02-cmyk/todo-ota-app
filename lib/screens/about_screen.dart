import 'package:flutter/material.dart';

import '../config.dart';
import '../services/remote_config_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

class AboutScreen extends StatefulWidget {
  final RemoteConfigService remote;
  final UpdateService updates;
  const AboutScreen({super.key, required this.remote, required this.updates});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.updates.currentVersionLabel().then((v) => setState(() => _version = v));
  }

  Future<void> _refreshConfig() async {
    setState(() => _busy = true);
    final ok = await widget.remote.refresh();
    setState(() => _busy = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'تم جلب آخر الإعدادات ✅' : 'تعذّر الاتصال: ${widget.remote.lastError}'),
    ));
  }

  Future<void> _checkUpdate() async {
    setState(() => _busy = true);
    final u = await widget.updates.checkForUpdate();
    setState(() => _busy = false);
    if (!mounted) return;
    if (u == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أنت على آخر إصدار 👍')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => UpdateDialog(update: u, service: widget.updates),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.remote;
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: ListenableBuilder(
        listenable: r,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_busy) const LinearProgressIndicator(),
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('إصدار التطبيق'),
              subtitle: Text(_version),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync_outlined),
              title: const Text('نسخة الإعدادات عن بعد'),
              subtitle: Text(
                'v${r.config.configVersion} • آخر جلب: '
                '${r.lastFetch == null ? 'لم يتم بعد' : TimeOfDay.fromDateTime(r.lastFetch!).format(context)}',
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('جلب التحديثات الفورية الآن'),
              subtitle: const Text('الألوان، النصوص، الإعلانات، الميزات... بدون تنزيل'),
              onTap: _busy ? null : _refreshConfig,
            ),
            ListTile(
              leading: const Icon(Icons.system_update),
              title: const Text('فحص إصدار جديد للتطبيق'),
              subtitle: const Text('للتحديثات الكبيرة في الكود (أندرويد)'),
              onTap: _busy ? null : _checkUpdate,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'مصدر الإعدادات:\n${AppConfig.remoteConfigUrl}',
                style: Theme.of(context).textTheme.bodySmall,
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
