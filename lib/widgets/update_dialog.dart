import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdate update;
  final UpdateService service;
  const UpdateDialog({super.key, required this.update, required this.service});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double? _progress;
  String? _status;
  StreamSubscription<OtaEvent>? _sub;

  void _start() {
    setState(() {
      _progress = 0;
      _status = 'جاري التنزيل...';
    });
    _sub = widget.service.install(widget.update).listen(
      (e) {
        setState(() {
          switch (e.status) {
            case OtaStatus.DOWNLOADING:
              _progress = (double.tryParse(e.value ?? '0') ?? 0) / 100;
              _status = 'جاري التنزيل ${e.value}%';
            case OtaStatus.INSTALLING:
              _progress = 1;
              _status = 'جاري التثبيت...';
            default:
              _status = 'تعذّر التحديث (${e.status.name})';
              _progress = null;
          }
        });
      },
      onError: (e) => setState(() {
        _status = 'خطأ: $e';
        _progress = null;
      }),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.update;
    return PopScope(
      canPop: !u.force,
      child: AlertDialog(
        icon: const Icon(Icons.system_update, size: 40),
        title: Text('إصدار جديد ${u.version}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (u.notes.isNotEmpty) Text(u.notes),
            if (_status != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(_status!),
            ],
          ],
        ),
        actions: [
          if (!u.force && _progress == null)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لاحقاً'),
            ),
          if (_progress == null)
            FilledButton(onPressed: _start, child: const Text('تحديث الآن')),
        ],
      ),
    );
  }
}
