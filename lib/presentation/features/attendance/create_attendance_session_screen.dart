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
///   1 — Enter class title
///   2 — Select discipline (active only)
///   3 — Pick date (first occurrence)
///   4 — Set start & end times
///   5 — Recurring toggle
///   6 — Add optional notes
///   7 — Confirm & save
class CreateAttendanceSessionScreen extends ConsumerStatefulWidget {
  const CreateAttendanceSessionScreen({super.key});

  @override
  ConsumerState<CreateAttendanceSessionScreen> createState() =>
      _CreateAttendanceSessionScreenState();
}

class _CreateAttendanceSessionScreenState
    extends ConsumerState<CreateAttendanceSessionScreen> {
  int _step = 1;

  String _title = '';
  Discipline? _selectedDiscipline;
  DateTime? _selectedDate;
  String _startTime = '';
  String _endTime = '';
  bool _isRecurring = false;
  String _notes = '';

  bool _isSaving = false;
  String? _errorMessage;

  // ── Step titles ────────────────────────────────────────────────────────

  static const _titles = [
    'Class Title',
    'Select Discipline',
    'Select Date',
    'Set Times',
    'Recurring',
    'Add Notes',
    'Confirm',
  ];

  // ── Navigation helpers ─────────────────────────────────────────────────

  void _goBack() {
    setState(() {
      _errorMessage = null;
      if (_step > 1) _step--;
    });
  }

  void _advance() {
    setState(() {
      _errorMessage = null;
      _step++;
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
            title: _title.trim().isEmpty ? null : _title.trim(),
            notes: _notes.trim().isEmpty ? null : _notes.trim(),
            createdByAdminId: adminId,
            isRecurring: _isRecurring,
          );

      if (!mounted) return;

      String msg;
      if (_isRecurring) {
        msg = result.resolvedQueueCount > 0
            ? '52 weekly sessions created. ${result.resolvedQueueCount} queued check-in${result.resolvedQueueCount == 1 ? '' : 's'} resolved.'
            : '52 weekly sessions created.';
      } else {
        msg = result.resolvedQueueCount > 0
            ? 'Session created. ${result.resolvedQueueCount} queued check-in${result.resolvedQueueCount == 1 ? '' : 's'} resolved.'
            : 'Session created.';
      }

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_step - 1]),
        leading: _step == 1 ? null : BackButton(onPressed: _goBack),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_step) {
          1 => _StepTitle(
            key: const ValueKey(1),
            initialTitle: _title,
            onConfirmed: (t) {
              setState(() => _title = t);
              _advance();
            },
          ),
          2 => _StepSelectDiscipline(
            key: const ValueKey(2),
            onSelected: (d) {
              setState(() => _selectedDiscipline = d);
              _advance();
            },
          ),
          3 => _StepSelectDate(
            key: const ValueKey(3),
            onSelected: (date) {
              setState(() => _selectedDate = date);
              _advance();
            },
          ),
          4 => _StepSetTimes(
            key: const ValueKey(4),
            initialStart: _startTime,
            initialEnd: _endTime,
            errorMessage: _errorMessage,
            onConfirmed: (start, end) {
              setState(() {
                _startTime = start;
                _endTime = end;
                _errorMessage = null;
              });
              _advance();
            },
          ),
          5 => _StepRecurring(
            key: const ValueKey(5),
            selectedDate: _selectedDate!,
            initialValue: _isRecurring,
            onConfirmed: (recurring) {
              setState(() => _isRecurring = recurring);
              _advance();
            },
          ),
          6 => _StepAddNotes(
            key: const ValueKey(6),
            initialNotes: _notes,
            onConfirmed: (notes) {
              setState(() => _notes = notes);
              _advance();
            },
          ),
          _ => _StepConfirm(
            key: const ValueKey(7),
            title: _title,
            discipline: _selectedDiscipline!,
            date: _selectedDate!,
            startTime: _startTime,
            endTime: _endTime,
            isRecurring: _isRecurring,
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

// ── Step 1 — Class Title ─────────────────────────────────────────────────────

class _StepTitle extends StatefulWidget {
  const _StepTitle({
    super.key,
    required this.initialTitle,
    required this.onConfirmed,
  });

  final String initialTitle;
  final void Function(String) onConfirmed;

  @override
  State<_StepTitle> createState() => _StepTitleState();
}

class _StepTitleState extends State<_StepTitle> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
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
            'Give this class a name that students will see',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Kids Karate Class, Adults BJJ…',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              if (_controller.text.trim().isNotEmpty) {
                widget.onConfirmed(_controller.text);
              }
            },
          ),
          const Spacer(),
          FilledButton(
            onPressed: _controller.text.trim().isEmpty
                ? null
                : () => widget.onConfirmed(_controller.text),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

// ── Step 2 — Select Discipline ───────────────────────────────────────────────

class _StepSelectDiscipline extends ConsumerWidget {
  const _StepSelectDiscipline({super.key, required this.onSelected});

  final void Function(Discipline) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

// ── Step 3 — Select Date ─────────────────────────────────────────────────────

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
      locale: const Locale('en', 'GB'),
      initialDate: _picked ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
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

// ── Step 4 — Set Times ───────────────────────────────────────────────────────

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
          _TimePickerTile(
            label: 'Start Time',
            value: _start,
            onTap: () => _pickTime(isStart: true),
          ),
          const SizedBox(height: 12),
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

// ── Step 5 — Recurring ───────────────────────────────────────────────────────

class _StepRecurring extends StatefulWidget {
  const _StepRecurring({
    super.key,
    required this.selectedDate,
    required this.initialValue,
    required this.onConfirmed,
  });

  final DateTime selectedDate;
  final bool initialValue;
  final void Function(bool) onConfirmed;

  @override
  State<_StepRecurring> createState() => _StepRecurringState();
}

class _StepRecurringState extends State<_StepRecurring> {
  late bool _isRecurring;

  @override
  void initState() {
    super.initState();
    _isRecurring = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEEE').format(widget.selectedDate);

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
            child: SwitchListTile(
              title: const Text(
                'Recurring class',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _isRecurring
                    ? 'Repeats every $dayName — 52 sessions will be created'
                    : 'One-off session',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sessions will be created every $dayName for 1 year. You can cancel individual sessions at any time.',
                      style: TextStyle(fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          FilledButton(
            onPressed: () => widget.onConfirmed(_isRecurring),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

// ── Step 6 — Add Notes ───────────────────────────────────────────────────────

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

// ── Step 7 — Confirm ─────────────────────────────────────────────────────────

class _StepConfirm extends StatelessWidget {
  const _StepConfirm({
    super.key,
    required this.title,
    required this.discipline,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isRecurring,
    required this.notes,
    required this.isSaving,
    required this.errorMessage,
    required this.onConfirm,
  });

  final String title;
  final Discipline discipline;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isRecurring;
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
    final dayName = DateFormat('EEEE').format(date);

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
                  if (title.trim().isNotEmpty) ...[
                    _SummaryRow(label: 'Title', value: title.trim()),
                    const Divider(height: 24),
                  ],
                  _SummaryRow(label: 'Discipline', value: discipline.name),
                  const Divider(height: 24),
                  _SummaryRow(label: 'Date', value: dateLabel),
                  const Divider(height: 24),
                  _SummaryRow(label: 'Time', value: timeLabel),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Schedule',
                    value: isRecurring
                        ? 'Weekly every $dayName (52 sessions)'
                        : 'One-off',
                  ),
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
                : Text(isRecurring ? 'Create 52 Sessions' : 'Create Session'),
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
