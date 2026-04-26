import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../domain/entities/discipline.dart';

/// Multi-step wizard for creating a new attendance session.
///
/// Steps:
///   1 — Select discipline (active only)
///   2 — Pick date (max = today)
///   3 — Set start & end times
///   4 — Add optional notes
///   5 — Confirm & save
class CreateAttendanceSessionScreen extends ConsumerStatefulWidget {
  const CreateAttendanceSessionScreen({super.key});

  @override
  ConsumerState<CreateAttendanceSessionScreen> createState() =>
      _CreateAttendanceSessionScreenState();
}

class _CreateAttendanceSessionScreenState
    extends ConsumerState<CreateAttendanceSessionScreen> {
  int _step = 1;

  Discipline? _selectedDiscipline;
  DateTime? _selectedDate;
  String _startTime = '';
  String _endTime = '';
  String _notes = '';

  bool _isSaving = false;
  String? _errorMessage;

  // ── Navigation helpers ─────────────────────────────────────────────────

  void _onDisciplineSelected(Discipline d) {
    setState(() {
      _selectedDiscipline = d;
      _errorMessage = null;
      _step = 2;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _errorMessage = null;
      _step = 3;
    });
  }

  void _onTimesConfirmed(String start, String end) {
    setState(() {
      _startTime = start;
      _endTime = end;
      _errorMessage = null;
      _step = 4;
    });
  }

  void _onNotesConfirmed(String notes) {
    setState(() {
      _notes = notes;
      _errorMessage = null;
      _step = 5;
    });
  }

  void _goBack() {
    setState(() {
      _errorMessage = null;
      if (_step > 1) _step--;
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final adminId = ref.read(currentAdminIdProvider);
    if (adminId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(createAttendanceSessionUseCaseProvider)
          .call(
            disciplineId: _selectedDiscipline!.id,
            sessionDate: _selectedDate!,
            startTime: _startTime,
            endTime: _endTime,
            notes: _notes.trim().isEmpty ? null : _notes.trim(),
            createdByAdminId: adminId,
          );

      if (!mounted) return;

      final msg = result.resolvedQueueCount > 0
          ? 'Session created. ${result.resolvedQueueCount} queued check-in${result.resolvedQueueCount == 1 ? '' : 's'} resolved.'
          : 'Session created.';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      context.pop();
    } on ArgumentError catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.message as String;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Select Discipline',
      'Select Date',
      'Set Times',
      'Add Notes',
      'Confirm',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_step - 1]),
        leading: _step == 1 ? null : BackButton(onPressed: _goBack),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_step) {
          1 => _StepSelectDiscipline(
            key: const ValueKey(1),
            onSelected: _onDisciplineSelected,
          ),
          2 => _StepSelectDate(
            key: const ValueKey(2),
            onSelected: _onDateSelected,
          ),
          3 => _StepSetTimes(
            key: const ValueKey(3),
            initialStart: _startTime,
            initialEnd: _endTime,
            errorMessage: _errorMessage,
            onConfirmed: _onTimesConfirmed,
          ),
          4 => _StepAddNotes(
            key: const ValueKey(4),
            initialNotes: _notes,
            onConfirmed: _onNotesConfirmed,
          ),
          _ => _StepConfirm(
            key: const ValueKey(5),
            discipline: _selectedDiscipline!,
            date: _selectedDate!,
            startTime: _startTime,
            endTime: _endTime,
            notes: _notes,
            isSaving: _isSaving,
            errorMessage: _errorMessage,
            onConfirm: _save,
          ),
        },
      ),
    );
  }
}

// ── Step 1 — Select Discipline ───────────────────────────────────────────────

class _StepSelectDiscipline extends ConsumerWidget {
  const _StepSelectDiscipline({super.key, required this.onSelected});

  final void Function(Discipline) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Coaches see only their assigned disciplines; owners see all active ones.
    final disciplinesAsync = ref.watch(accessibleActiveDisciplineListProvider);

    return disciplinesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (disciplines) {
        if (disciplines.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No active disciplines found.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: disciplines.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = disciplines[i];
            return Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.surfaceVariant),
              ),
              child: ListTile(
                title: Text(
                  d.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onSelected(d),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Step 2 — Select Date ─────────────────────────────────────────────────────

class _StepSelectDate extends StatefulWidget {
  const _StepSelectDate({super.key, required this.onSelected});

  final void Function(DateTime) onSelected;

  @override
  State<_StepSelectDate> createState() => _StepSelectDateState();
}

class _StepSelectDateState extends State<_StepSelectDate> {
  DateTime? _picked;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _picked ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (result != null) setState(() => _picked = result);
  }

  @override
  Widget build(BuildContext context) {
    final label = _picked == null
        ? 'Tap to choose a date'
        : DateFormat('EEEE, d MMM yyyy').format(_picked!);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _picked == null
                ? null
                : () => widget.onSelected(_picked!),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

// ── Step 3 — Set Times ───────────────────────────────────────────────────────

class _StepSetTimes extends StatefulWidget {
  const _StepSetTimes({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.errorMessage,
    required this.onConfirmed,
  });

  final String initialStart;
  final String initialEnd;
  final String? errorMessage;
  final void Function(String start, String end) onConfirmed;

  @override
  State<_StepSetTimes> createState() => _StepSetTimesState();
}

class _StepSetTimesState extends State<_StepSetTimes> {
  late String _start;
  late String _end;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  Future<void> _pickTime({required bool isStart}) async {
    TimeOfDay initial = TimeOfDay.now();
    if (isStart && _start.isNotEmpty) {
      final parts = _start.split(':');
      initial = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else if (!isStart && _end.isNotEmpty) {
      final parts = _end.split(':');
      initial = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final result = await showTimePicker(context: context, initialTime: initial);
    if (result == null) return;

    final formatted =
        '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _start = formatted;
      } else {
        _end = formatted;
      }
      _localError = null;
    });
  }

  int _toMinutes(String t) {
    if (t.isEmpty) return -1;
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _confirm() {
    if (_start.isEmpty || _end.isEmpty) {
      setState(() => _localError = 'Please set both start and end times.');
      return;
    }
    if (_toMinutes(_end) <= _toMinutes(_start)) {
      setState(() => _localError = 'End time must be after start time.');
      return;
    }
    widget.onConfirmed(_start, _end);
  }

  @override
  Widget build(BuildContext context) {
    final error = _localError ?? widget.errorMessage;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Start time
          _TimePickerTile(
            label: 'Start Time',
            value: _start,
            onTap: () => _pickTime(isStart: true),
          ),
          const SizedBox(height: 12),
          // End time
          _TimePickerTile(
            label: 'End Time',
            value: _end,
            onTap: () => _pickTime(isStart: false),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
          const Spacer(),
          FilledButton(onPressed: _confirm, child: const Text('Next')),
        ],
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.access_time_outlined),
      label: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.isEmpty ? 'Not set' : value,
            style: TextStyle(
              color: value.isEmpty
                  ? AppColors.textSecondary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

// ── Step 4 — Add Notes ───────────────────────────────────────────────────────

class _StepAddNotes extends StatefulWidget {
  const _StepAddNotes({
    super.key,
    required this.initialNotes,
    required this.onConfirmed,
  });

  final String initialNotes;
  final void Function(String) onConfirmed;

  @override
  State<_StepAddNotes> createState() => _StepAddNotesState();
}

class _StepAddNotesState extends State<_StepAddNotes> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Notes (optional)',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'e.g. Sparring focus, guest instructor…',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => widget.onConfirmed(_controller.text),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

// ── Step 5 — Confirm ─────────────────────────────────────────────────────────

class _StepConfirm extends StatelessWidget {
  const _StepConfirm({
    super.key,
    required this.discipline,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.notes,
    required this.isSaving,
    required this.errorMessage,
    required this.onConfirm,
  });

  final Discipline discipline;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String notes;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, d MMM yyyy').format(date);
    final timeLabel = startTime.isNotEmpty
        ? '$startTime – $endTime'
        : 'No time set';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.surfaceVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(label: 'Discipline', value: discipline.name),
                  const Divider(height: 24),
                  _SummaryRow(label: 'Date', value: dateLabel),
                  const Divider(height: 24),
                  _SummaryRow(label: 'Time', value: timeLabel),
                  if (notes.trim().isNotEmpty) ...[
                    const Divider(height: 24),
                    _SummaryRow(label: 'Notes', value: notes.trim()),
                  ],
                ],
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(),
          FilledButton(
            onPressed: isSaving ? null : onConfirm,
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Session'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
