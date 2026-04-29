import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_providers.dart';
import '../../../core/theme/app_colors.dart';

class DangerZoneScreen extends ConsumerStatefulWidget {
  const DangerZoneScreen({super.key});

  @override
  ConsumerState<DangerZoneScreen> createState() => _DangerZoneScreenState();
}

class _DangerZoneScreenState extends ConsumerState<DangerZoneScreen> {
  final _ctrl = TextEditingController(text: '90');
  bool _isClearing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Enter a whole number';
    if (n < 1) return 'Minimum 1 day';
    return null;
  }

  Future<void> _clear() async {
    final days = int.tryParse(_ctrl.text);
    if (days == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Notification Logs'),
        content: Text(
          'This will permanently delete all notification logs older than '
          '$days ${days == 1 ? 'day' : 'days'}. '
          'This cannot be undone.\n\nProceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear Logs'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClearing = true);
    try {
      final count = await ref
          .read(clearNotificationLogsUseCaseProvider)
          .call(olderThanDays: days);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deleted $count notification ${count == 1 ? 'log' : 'logs'}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to clear logs. The Cloud Function may not yet be '
              'deployed. Error: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danger Zone'),
        foregroundColor: AppColors.error,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              border: Border.all(color: AppColors.error.withAlpha(80)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Actions in this section are permanent and cannot be undone.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Clear Notification Logs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently delete notification log records older than the '
            'specified number of days.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder: (ctx, setInner) => TextField(
              controller: _ctrl,
              onChanged: (_) => setInner(() {}),
              decoration: InputDecoration(
                labelText: 'Clear logs older than',
                suffixText: 'days',
                errorText: _validate(_ctrl.text),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder: (ctx, _) => FilledButton.icon(
              onPressed: (_validate(_ctrl.text) != null || _isClearing)
                  ? null
                  : _clear,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: _isClearing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Clear Logs'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
