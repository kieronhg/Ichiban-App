import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/enrollment_providers.dart';
import 'csv_enrolment_parser.dart';

/// Preview screen shown after CSV validation, before any records are written.
/// Displays three sections: to-enrol, skipped, and errors.
class BulkEnrolPreviewScreen extends ConsumerStatefulWidget {
  const BulkEnrolPreviewScreen({super.key, required this.result});

  final CsvParseResult result;

  @override
  ConsumerState<BulkEnrolPreviewScreen> createState() =>
      _BulkEnrolPreviewScreenState();
}

class _BulkEnrolPreviewScreenState
    extends ConsumerState<BulkEnrolPreviewScreen> {
  bool _isCommitting = false;
  String? _commitError;

  // ── Commit ─────────────────────────────────────────────────────────────

  Future<void> _commit() async {
    setState(() {
      _isCommitting = true;
      _commitError = null;
    });

    int count = 0;
    try {
      for (final row in widget.result.successes) {
        if (row.isReactivation) {
          await ref
              .read(reactivateEnrollmentUseCaseProvider)
              .call(studentId: row.profile.id, disciplineId: row.discipline.id);
        } else {
          await ref
              .read(enrolStudentUseCaseProvider)
              .call(
                studentId: row.profile.id,
                disciplineId: row.discipline.id,
                startingRankId: row.rank.id,
                dateOfBirth: row.profile.dateOfBirth,
              );
        }
        count++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$count ${count == 1 ? 'enrolment' : 'enrolments'} saved.',
            ),
          ),
        );
        // Pop back to the screen that launched the upload
        context.pop(); // preview → upload
        context.pop(); // upload → discipline detail / members
      }
    } catch (e) {
      setState(() {
        _isCommitting = false;
        _commitError =
            'Failed after $count ${count == 1 ? 'enrolment' : 'enrolments'}: $e';
      });
    }
  }

  // ── Download error report ──────────────────────────────────────────────

  Future<void> _downloadErrorReport() async {
    final lines = StringBuffer('rowNumber,name,reason\n');
    for (final e in widget.result.errors) {
      final name = e.rawName.replaceAll(',', ' ');
      final reason = e.reason.replaceAll(',', ';');
      lines.writeln('${e.rowNumber},$name,$reason');
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/enrolment_errors_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv',
      );
      await file.writeAsString(lines.toString());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Enrolment CSV Errors'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Confirm'),
        automaticallyImplyLeading: !_isCommitting,
      ),
      body: Column(
        children: [
          // ── Summary bar ──────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _SummaryBadge(
                  count: r.successes.length,
                  label: 'To enrol',
                  color: AppColors.success,
                ),
                const SizedBox(width: 16),
                _SummaryBadge(
                  count: r.skipped.length,
                  label: 'Skipped',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 16),
                _SummaryBadge(
                  count: r.errors.length,
                  label: 'Errors',
                  color: AppColors.error,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Sections ─────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // To enrol
                _PreviewSection(
                  title: 'To Be Enrolled',
                  count: r.successes.length,
                  color: AppColors.success,
                  emptyMessage: 'No valid rows to enrol.',
                  children: r.successes
                      .map((s) => _SuccessRow(row: s))
                      .toList(),
                ),
                const SizedBox(height: 12),

                // Skipped
                if (r.skipped.isNotEmpty)
                  _PreviewSection(
                    title: 'Skipped',
                    count: r.skipped.length,
                    color: AppColors.warning,
                    emptyMessage: '',
                    children: r.skipped
                        .map((s) => _SkippedRow(row: s))
                        .toList(),
                  ),
                if (r.skipped.isNotEmpty) const SizedBox(height: 12),

                // Errors
                if (r.errors.isNotEmpty)
                  _PreviewSection(
                    title: 'Errors',
                    count: r.errors.length,
                    color: AppColors.error,
                    emptyMessage: '',
                    children: r.errors.map((e) => _ErrorRow(row: e)).toList(),
                  ),

                const SizedBox(height: 24),

                // Error message
                if (_commitError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withAlpha(80)),
                    ),
                    child: Text(
                      _commitError!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ),

          // ── Action bar ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (r.errors.isNotEmpty) ...[
                    OutlinedButton.icon(
                      onPressed: _isCommitting ? null : _downloadErrorReport,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Download Error Report'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isCommitting ? null : () => context.pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: (r.hasValidRows && !_isCommitting)
                              ? _commit
                              : null,
                          child: _isCommitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Confirm ${r.successes.length} '
                                  '${r.successes.length == 1 ? 'Enrolment' : 'Enrolments'}',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preview section ──────────────────────────────────────────────────────────

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.title,
    required this.count,
    required this.color,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final int count;
  final Color color;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$title ($count)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                emptyMessage,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

// ── Row widgets ──────────────────────────────────────────────────────────────

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({required this.row});

  final CsvRowSuccess row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.profile.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${row.discipline.name} — ${row.rank.name}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              row.isReactivation ? 'Reactivated' : 'New Enrolment',
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: AppColors.success.withAlpha(25),
            side: BorderSide(color: AppColors.success.withAlpha(80)),
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          ),
        ],
      ),
    );
  }
}

class _SkippedRow extends StatelessWidget {
  const _SkippedRow({required this.row});

  final CsvRowSkipped row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.rawName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${row.disciplineName} — ${row.reason}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.row});

  final CsvRowError row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Row ${row.rowNumber}',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (row.rawName.trim().isNotEmpty)
                  Text(
                    row.rawName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                Text(
                  row.reason,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary badge ────────────────────────────────────────────────────────────

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
