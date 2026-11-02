import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/remote_config_service.dart';
import '../services/task_storage.dart';
import '../services/update_service.dart';
import '../widgets/task_tile.dart';
import '../widgets/task_editor.dart';
import '../widgets/update_dialog.dart';
import 'about_screen.dart';

enum Filter { all, active, done }

class HomeScreen extends StatefulWidget {
  final RemoteConfigService remote;
  const HomeScreen({super.key, required this.remote});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = TaskStorage();
  final _updates = UpdateService();
  final _uuid = const Uuid();

  List<Task> _tasks = [];
  bool _loading = true;
  Filter _filter = Filter.all;
  String? _category; // null = الكل
  bool _updateDialogShown = false;

  RemoteConfig get cfg => widget.remote.config;

  @override
  void initState() {
    super.initState();
    _load();
    widget.remote.addListener(_onRemoteChanged);
    widget.remote.onNewVersion = (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ وصل تحديث جديد للتطبيق وتم تطبيقه')),
      );
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAppUpdate());
  }

  @override
  void dispose() {
    widget.remote.removeListener(_onRemoteChanged);
    super.dispose();
  }

  Future<void> _load() async {
    final t = await _storage.load();
    setState(() {
      _tasks = t;
      _loading = false;
    });
    await _mergeRemoteTasks();
  }

  void _onRemoteChanged() {
    _mergeRemoteTasks();
    if (mounted) setState(() {});
  }

  /// مهام يرسلها المطوّر عن بعد عبر config.json — تُضاف مرة واحدة فقط.
  Future<void> _mergeRemoteTasks() async {
    if (_loading) return;
    final seen = await _storage.seenRemoteIds();
    final fresh = cfg.remoteTasks.where((r) => !seen.contains(r.id)).toList();
    if (fresh.isEmpty) return;
    setState(() {
      for (final r in fresh) {
        _tasks.insert(
          0,
          Task(
            id: 'remote_${r.id}',
            title: r.title,
            note: r.note,
            category: r.category,
            priority: Priority.values.firstWhere((p) => p.name == r.priority,
                orElse: () => Priority.medium),
          ),
        );
      }
    });
    await _storage.markRemoteSeen(fresh.map((e) => e.id));
    await _storage.save(_tasks);
  }

  Future<void> _checkAppUpdate() async {
    final u = await _updates.checkForUpdate();
    if (u == null || !mounted || _updateDialogShown) return;
    _updateDialogShown = true;
    await showDialog(
      context: context,
      barrierDismissible: !u.force,
      builder: (_) => UpdateDialog(update: u, service: _updates),
    );
  }

  Future<void> _persist() => _storage.save(_tasks);

  Future<void> _openEditor([Task? task]) async {
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TaskEditor(
        task: task,
        categories: cfg.categories,
        showPriority: cfg.showPriority,
        showCategories: cfg.showCategories,
        newId: _uuid.v4,
      ),
    );
    if (result == null) return;
    setState(() {
      final i = _tasks.indexWhere((t) => t.id == result.id);
      if (i >= 0) {
        _tasks[i] = result;
      } else {
        _tasks.insert(0, result);
      }
    });
    _persist();
  }

  void _toggle(Task t) {
    setState(() => t.done = !t.done);
    _persist();
  }

  void _delete(Task t) {
    final index = _tasks.indexOf(t);
    setState(() => _tasks.remove(t));
    _persist();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('تم حذف "${t.title}"'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () {
            setState(() => _tasks.insert(index.clamp(0, _tasks.length), t));
            _persist();
          },
        ),
      ));
  }

  void _clearDone() {
    setState(() => _tasks.removeWhere((t) => t.done));
    _persist();
  }

  List<Task> get _visible {
    Iterable<Task> list = _tasks;
    if (_filter == Filter.active) list = list.where((t) => !t.done);
    if (_filter == Filter.done) list = list.where((t) => t.done);
    if (_category != null) list = list.where((t) => t.category == _category);
    final sorted = list.toList()
      ..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        return b.priority.index.compareTo(a.priority.index);
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (cfg.maintenanceMode) return _Maintenance(message: cfg.maintenanceMessage, onRetry: widget.remote.refresh);

    final scheme = Theme.of(context).colorScheme;
    final visible = _visible;
    final doneCount = _tasks.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(cfg.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (doneCount > 0 && cfg.allowDelete)
            IconButton(
              tooltip: 'حذف المكتملة',
              icon: const Icon(Icons.cleaning_services_outlined),
              onPressed: _clearDone,
            ),
          IconButton(
            tooltip: 'حول التطبيق والتحديثات',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AboutScreen(remote: widget.remote, updates: _updates),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('مهمة جديدة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await widget.remote.refresh();
                await _checkAppUpdate();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  if (cfg.announcementEnabled && cfg.announcementText.isNotEmpty)
                    _Announcement(
                      text: cfg.announcementText,
                      color: cfg.announcementColor,
                      url: cfg.announcementUrl,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(cfg.welcomeMessage,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (cfg.showStats) _Stats(total: _tasks.length, done: doneCount),
                  if (cfg.showTips && cfg.tips.isNotEmpty)
                    _Tip(text: cfg.tips[DateTime.now().day % cfg.tips.length]),
                  const SizedBox(height: 12),
                  SegmentedButton<Filter>(
                    segments: const [
                      ButtonSegment(value: Filter.all, label: Text('الكل')),
                      ButtonSegment(value: Filter.active, label: Text('الحالية')),
                      ButtonSegment(value: Filter.done, label: Text('المكتملة')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) => setState(() => _filter = s.first),
                  ),
                  if (cfg.showCategories) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: ChoiceChip(
                              label: const Text('كل التصنيفات'),
                              selected: _category == null,
                              onSelected: (_) => setState(() => _category = null),
                            ),
                          ),
                          for (final c in cfg.categories)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 6),
                              child: ChoiceChip(
                                label: Text(c),
                                selected: _category == c,
                                onSelected: (_) => setState(
                                    () => _category = _category == c ? null : c),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Icon(Icons.task_alt, size: 72, color: scheme.outlineVariant),
                          const SizedBox(height: 12),
                          Text('لا توجد مهام هنا',
                              style: TextStyle(color: scheme.outline)),
                        ],
                      ),
                    ),
                  for (final t in visible)
                    TaskTile(
                      key: ValueKey(t.id),
                      task: t,
                      showPriority: cfg.showPriority,
                      showCategory: cfg.showCategories,
                      allowDelete: cfg.allowDelete,
                      onToggle: () => _toggle(t),
                      onTap: () => _openEditor(t),
                      onDelete: () => _delete(t),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Announcement extends StatelessWidget {
  final String text;
  final Color color;
  final String? url;
  const _Announcement({required this.text, required this.color, this.url});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        leading: Icon(Icons.campaign_outlined, color: color),
        title: Text(text),
        trailing: url != null ? const Icon(Icons.open_in_new, size: 18) : null,
        onTap: url == null
            ? null
            : () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final int total, done;
  const _Stats({required this.total, required this.done});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = total == 0 ? 0.0 : done / total;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 6,
                    backgroundColor: scheme.surface,
                  ),
                  Center(
                    child: Text('${(pct * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أنجزت $done من $total',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('متبقي ${total - done} مهمة',
                      style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _Maintenance extends StatelessWidget {
  final String message;
  final Future<bool> Function() onRetry;
  const _Maintenance({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => unawaited(onRetry()),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
