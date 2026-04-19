import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/rank.dart';
import 'csv_enrolment_parser.dart';

/// Upload screen for CSV bulk enrolment.
///
/// If [preselectedDisciplineId] is provided (launched from a Discipline Detail
/// screen), the discipline is locked and the `discipline` CSV column is
/// ignored. Otherwise, the admin selects the discipline from a dropdown.
class BulkEnrolUploadScreen extends ConsumerStatefulWidget {
  const BulkEnrolUploadScreen({super.key, this.preselectedDisciplineId});

  final String? preselectedDisciplineId;

  @override
  ConsumerState<BulkEnrolUploadScreen> createState() =>
      _BulkEnrolUploadScreenState();
}

class _BulkEnrolUploadScreenState extends ConsumerState<BulkEnrolUploadScreen> {
  String? _selectedDisciplineId;
  String? _selectedFileName;
  List<Map<String, String>>? _parsedRows;
  bool _isValidating = false;
  String? _fileError;

  @override
  void initState() {
    super.initState();
    _selectedDisciplineId = widget.preselectedDisciplineId;
  }

  // ── File picking ───────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() {
      _fileError = null;
      _parsedRows = null;
      _selectedFileName = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() => _selectedFileName = file.name);

    try {
      final content = file.bytes != null
          ? String.fromCharCodes(file.bytes!)
          : await File(file.path!).readAsString();

      final rows = const CsvToListConverter(eol: '\n')
          .convert(content)
          .map((r) => r.map((c) => c.toString()).toList())
          .toList();

      if (rows.isEmpty) {
        setState(() => _fileError = 'The CSV file is empty.');
        return;
      }

      // First row is the header
      final headers = rows.first.map((h) => h.trim().toLowerCase()).toList();

      // Validate required columns
      const requiredColumns = ['firstname', 'lastname', 'dateofbirth'];
      final missingColumns = requiredColumns
          .where((c) => !headers.contains(c))
          .toList();
      if (missingColumns.isNotEmpty) {
        setState(
          () => _fileError =
              'Missing required column(s): ${missingColumns.map((c) => '"$c"').join(', ')}. '
              'Expected: firstName, lastName, dateOfBirth, discipline, rank',
        );
        return;
      }

      // Map rows to List<Map<String, String>> using original-case header names
      final originalHeaders = rows.first.map((h) => h.trim()).toList();
      final dataRows = rows.skip(1).map((row) {
        final map = <String, String>{};
        for (var i = 0; i < originalHeaders.length && i < row.length; i++) {
          map[originalHeaders[i]] = row[i].trim();
        }
        return map;
      }).toList();

      setState(() => _parsedRows = dataRows);
    } catch (e) {
      setState(() => _fileError = 'Failed to read file: $e');
    }
  }

  // ── Validate ───────────────────────────────────────────────────────────

  Future<void> _validate() async {
    if (_parsedRows == null) return;

    final disciplineId =
        _selectedDisciplineId ?? widget.preselectedDisciplineId;
    if (disciplineId == null && widget.preselectedDisciplineId == null) {
      // No discipline selected and no preselection — show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a discipline before uploading.'),
        ),
      );
      return;
    }

    setState(() => _isValidating = true);

    try {
      // Gather all data needed for validation
      final profiles = await ref.read(profileListProvider.future);
      final disciplines = await ref.read(activeDisciplineListProvider.future);

      // Fetch ranks for all disciplines (or just the preselected one)
      final Map<String, List<Rank>> ranksByDiscipline = {};
      final disciplineIds = disciplineId != null
          ? [disciplineId]
          : disciplines.map((d) => d.id).toList();
      for (final id in disciplineIds) {
        final ranks = await ref.read(rankListProvider(id).future);
        ranksByDiscipline[id] = ranks;
      }

      // Gather all enrollments for students in the profiles list
      final Map<String, List<Enrollment>> activeByStudent = {};
      final Map<String, List<Enrollment>> inactiveByStudent = {};
      for (final profile in profiles) {
        final all = await ref
            .read(getEnrollmentsUseCaseProvider)
            .getAllForStudent(profile.id);
        activeByStudent[profile.id] = all.where((e) => e.isActive).toList();
        inactiveByStudent[profile.id] = all.where((e) => !e.isActive).toList();
      }

      final parser = CsvEnrolmentParser(
        profiles: profiles,
        disciplines: disciplines,
        ranksByDiscipline: ranksByDiscipline,
        activeEnrollmentsByStudent: activeByStudent,
        inactiveEnrollmentsByStudent: inactiveByStudent,
      );

      final result = parser.parse(
        _parsedRows!,
        preselectedDisciplineId: disciplineId,
      );

      if (!mounted) return;
      context.pushNamed('adminBulkEnrolPreview', extra: result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activeDisciplinesAsync = ref.watch(activeDisciplineListProvider);
    final isPrelocked = widget.preselectedDisciplineId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Enrol via CSV')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Discipline selector ────────────────────────────────────────
          if (!isPrelocked) ...[
            Text(
              'Discipline',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            activeDisciplinesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (disciplines) => DropdownButtonFormField<String>(
                initialValue: _selectedDisciplineId,
                decoration: const InputDecoration(
                  hintText: 'Select discipline…',
                  border: OutlineInputBorder(),
                ),
                items: disciplines
                    .map(
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedDisciplineId = v),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            _LockedDisciplineChip(
              disciplineId: widget.preselectedDisciplineId!,
            ),
            const SizedBox(height: 24),
          ],

          // ── Instructions ───────────────────────────────────────────────
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CSV Format',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your CSV must include a header row with the following '
                    'column names:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _CsvColumnTable(isPrelocked: isPrelocked),
                  const SizedBox(height: 12),
                  Text(
                    '• Date of birth must be in DD/MM/YYYY format.\n'
                    '• Discipline and rank names must match exactly '
                    '(case-insensitive).\n'
                    '• Leave rank blank to default to the bottom rank of '
                    'the discipline.\n'
                    '• Students already enrolled are silently skipped.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── File picker ────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: Text(
              _selectedFileName != null
                  ? _selectedFileName!
                  : 'Choose CSV File',
            ),
          ),
          if (_fileError != null) ...[
            const SizedBox(height: 8),
            Text(
              _fileError!,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
          if (_parsedRows != null && _fileError == null) ...[
            const SizedBox(height: 8),
            Text(
              '${_parsedRows!.length} data '
              '${_parsedRows!.length == 1 ? 'row' : 'rows'} found.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: 32),

          // ── Validate button ────────────────────────────────────────────
          FilledButton(
            onPressed: (_parsedRows != null && !_isValidating)
                ? _validate
                : null,
            child: _isValidating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Upload and Validate'),
          ),
        ],
      ),
    );
  }
}

// ── Locked discipline chip ───────────────────────────────────────────────────

class _LockedDisciplineChip extends ConsumerWidget {
  const _LockedDisciplineChip({required this.disciplineId});

  final String disciplineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(disciplineProvider(disciplineId));
    final name = disciplineAsync.when(
      loading: () => '…',
      error: (_, _) => disciplineId,
      data: (d) => d?.name ?? disciplineId,
    );

    return Row(
      children: [
        Text(
          'Discipline: ',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        Chip(
          label: Text(name),
          avatar: const Icon(Icons.lock_outline, size: 14),
        ),
      ],
    );
  }
}

// ── CSV column table ─────────────────────────────────────────────────────────

class _CsvColumnTable extends StatelessWidget {
  const _CsvColumnTable({required this.isPrelocked});

  final bool isPrelocked;

  @override
  Widget build(BuildContext context) {
    final columns = [
      ('firstName', 'String', 'Must match profile exactly'),
      ('lastName', 'String', 'Must match profile exactly'),
      ('dateOfBirth', 'DD/MM/YYYY', 'Must match profile exactly'),
      if (!isPrelocked)
        (
          'discipline',
          'String',
          'Must match discipline name (case-insensitive)',
        ),
      ('rank', 'String', 'Optional — blank defaults to bottom rank'),
    ];

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.textSecondary.withAlpha(60)),
            ),
          ),
          children: [_th('Column'), _th('Format'), _th('Notes')],
        ),
        ...columns.map(
          (c) =>
              TableRow(children: [_td(c.$1, mono: true), _td(c.$2), _td(c.$3)]),
        ),
      ],
    );
  }

  Widget _th(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );

  Widget _td(String text, {bool mono = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontFamily: mono ? 'monospace' : null,
      ),
    ),
  );
}
