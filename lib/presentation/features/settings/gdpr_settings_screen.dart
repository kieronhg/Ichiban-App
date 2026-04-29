import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_providers.dart';
import '../../../core/theme/app_colors.dart';

class GdprSettingsScreen extends ConsumerWidget {
  const GdprSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('GDPR & Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _RetentionSection(),
          SizedBox(height: 24),
          Divider(),
          SizedBox(height: 24),
          _AnonymisationSection(),
          SizedBox(height: 24),
          Divider(),
          SizedBox(height: 24),
          _ExportSection(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Retention periods ──────────────────────────────────────────────────────

class _RetentionSection extends ConsumerStatefulWidget {
  const _RetentionSection();

  @override
  ConsumerState<_RetentionSection> createState() => _RetentionSectionState();
}

class _RetentionSectionState extends ConsumerState<_RetentionSection> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Enter a whole number';
    if (n < 1) return 'Minimum 1 month';
    return null;
  }

  Future<void> _save() async {
    final notifier = ref.read(gdprRetentionFormProvider.notifier);
    final value = int.tryParse(_ctrl.text);
    if (value != null) notifier.setRetentionMonths(value);
    try {
      await notifier.save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retention period saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(gdprRetentionFormProvider);

    return formAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (form) {
        if (_ctrl.text.isEmpty) {
          _ctrl.text = form.gdprRetentionMonths.toString();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Retention Periods',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (ctx, setInner) => TextField(
                controller: _ctrl,
                onChanged: (_) => setInner(() {}),
                decoration: InputDecoration(
                  labelText: 'Lapsed member retention',
                  suffixText: 'months',
                  helperText:
                      'Personal data is retained for this many months '
                      'after a member lapses before they become eligible '
                      'for anonymisation.',
                  helperMaxLines: 3,
                  errorText: _validate(_ctrl.text),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 12),
            // Read-only financial retention note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Financial record retention: 7 years\n'
                      'UK tax law requires financial records to be retained '
                      'for 7 years. This value cannot be changed.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: (_validate(_ctrl.text) != null || form.isSaving)
                  ? null
                  : _save,
              child: form.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Retention Period'),
            ),
          ],
        );
      },
    );
  }
}

// ── Bulk anonymisation ─────────────────────────────────────────────────────

class _AnonymisationSection extends ConsumerWidget {
  const _AnonymisationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(anonymisationEligibleCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bulk Anonymisation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Permanently anonymise all member records whose personal data '
          'retention period has expired. This cannot be undone.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        countAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(
            'Unable to count eligible records: $e',
            style: TextStyle(color: AppColors.error),
          ),
          data: (count) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count == 0
                    ? 'No members are currently eligible for anonymisation.'
                    : '$count member${count == 1 ? '' : 's'} eligible for anonymisation.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: count == 0
                    ? null
                    : () => _runAnonymisation(context, ref, count),
                icon: const Icon(Icons.person_remove_outlined),
                label: const Text('Run Anonymisation'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _runAnonymisation(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Anonymisation'),
        content: Text(
          'This will permanently anonymise $count member '
          '${count == 1 ? 'record' : 'records'}. '
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
            child: const Text('Anonymise'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final anonymised = await ref
          .read(triggerBulkAnonymiseUseCaseProvider)
          .call();
      if (!context.mounted) return;
      ref.invalidate(anonymisationEligibleCountProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anonymised $anonymised '
            '${anonymised == 1 ? 'record' : 'records'} successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anonymisation failed. The Cloud Function may not yet be deployed. '
            'Error: $e',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ── Bulk export ────────────────────────────────────────────────────────────

class _ExportSection extends ConsumerWidget {
  const _ExportSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bulk Data Export',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Export all non-anonymised member records including memberships, '
          'payments, grading records, and attendance.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          'To export a single member\'s data, visit their profile.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _showExportDialog(context),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export All Member Data'),
        ),
      ],
    );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    String format = 'csv';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Export Member Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose export format:'),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'csv', label: Text('CSV')),
                  ButtonSegment(value: 'pdf', label: Text('PDF')),
                  ButtonSegment(value: 'both', label: Text('Both')),
                ],
                selected: {format},
                onSelectionChanged: (s) => setState(() => format = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Cloud Function not yet deployed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bulk export is not yet available. '
                      'The export Cloud Function has not been deployed.',
                    ),
                  ),
                );
              },
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }
}
