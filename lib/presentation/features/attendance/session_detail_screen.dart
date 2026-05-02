import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/attendance_session.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/profile.dart';

/// Shows full details for an [AttendanceSession] and lets an admin mark
/// students as present or absent (coach attendance marking).
///
/// Receives the session as a route `extra` so the UI is available immediately
/// while live record data streams in.
class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.session});

  final AttendanceSession session;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  /// Tracks which student IDs the admin has currently toggled as present.
  /// Null means "not yet initialised from Firestore data".
  Set<String>? _presentIds;

  /// Whether the local state has diverged from what's saved in Firestore.
  bool _isDirty = false;

  bool _isSaving = false;

  // ── Initialise present-set from live records ───────────────────────────

  /// Called once the first records snapshot arrives; after that the user
  /// controls the checkboxes so we do not overwrite their changes.
  void _initPresentIds(List<String> recordStudentIds) {
    if (_presentIds == null) {
      setState(() => _presentIds = Set.from(recordStudentIds));
    }
  }

  void _toggle(String studentId, bool value) {
    setState(() {
      _presentIds ??= {};
      if (value) {
        _presentIds!.add(studentId);
      } else {
        _presentIds!.remove(studentId);
      }
      _isDirty = true;
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final adminId = ref.read(currentAdminIdProvider);
    if (adminId == null) return;

    setState(() => _isSaving = true);

    try {
      final paytWarnings = await ref
          .read(markAttendanceUseCaseProvider)
          .call(
            session: widget.session,
            markedPresentIds: Set.from(_presentIds ?? {}),
            coachProfileId: adminId,
          );
      if (!mounted) return;
      setState(() {
        _isDirty = false;
        _isSaving = false;
      });
      if (paytWarnings.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${paytWarnings.length} PAYT student${paytWarnings.length == 1 ? '' : 's'} '
              'unmarked — their pending payment record${paytWarnings.length == 1 ? '' : 's'} '
              'need manual cancellation.',
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Attendance saved.')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    final disciplinesAsync = ref.watch(disciplineListProvider);
    final enrollmentsAsync = ref.watch(
      enrollmentsForDisciplineProvider(session.disciplineId),
    );
    final recordsAsync = ref.watch(
      attendanceRecordsForSessionProvider(session.id),
    );
    final allProfilesAsync = ref.watch(
      profilesByTypeProvider(ProfileType.adultStudent),
    );
    final juniorProfilesAsync = ref.watch(
      profilesByTypeProvider(ProfileType.juniorStudent),
    );

    // Derive the discipline name from cached list
    final disciplineName =
        disciplinesAsync.asData?.value
            .where((d) => d.id == session.disciplineId)
            .firstOrNull
            ?.name ??
        session.disciplineId;

    final appBarTitle = session.title?.isNotEmpty == true
        ? session.title!
        : disciplineName;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (_isDirty)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Session header card ──────────────────────────────────────
          _SessionHeader(session: session, disciplineName: disciplineName),

          // ── Student list ─────────────────────────────────────────────
          Expanded(
            child: _buildStudentList(
              enrollmentsAsync: enrollmentsAsync,
              recordsAsync: recordsAsync,
              allProfilesAsync: allProfilesAsync,
              juniorProfilesAsync: juniorProfilesAsync,
            ),
          ),
        ],
      ),
      floatingActionButton: _isDirty
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save Attendance'),
            )
          : null,
    );
  }

  Widget _buildStudentList({
    required AsyncValue enrollmentsAsync,
    required AsyncValue recordsAsync,
    required AsyncValue<List<Profile>> allProfilesAsync,
    required AsyncValue<List<Profile>> juniorProfilesAsync,
  }) {
    // Wait for all three streams
    if (enrollmentsAsync is AsyncLoading ||
        recordsAsync is AsyncLoading ||
        allProfilesAsync is AsyncLoading ||
        juniorProfilesAsync is AsyncLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final enrollmentsError = enrollmentsAsync.error;
    final recordsError = recordsAsync.error;
    if (enrollmentsError != null) {
      return Center(child: Text('Error: $enrollmentsError'));
    }
    if (recordsError != null) {
      return Center(child: Text('Error: $recordsError'));
    }

    final enrollments = enrollmentsAsync.asData?.value ?? [];
    final records = recordsAsync.asData?.value ?? [];
    final adultProfiles = allProfilesAsync.asData?.value ?? [];
    final juniorProfiles = juniorProfilesAsync.asData?.value ?? [];
    final allProfiles = [...adultProfiles, ...juniorProfiles];

    // Initialise present-set once from Firestore data
    _initPresentIds(records.map((r) => r.studentId).toList());

    // Build a profile lookup map
    final profileMap = {for (final p in allProfiles) p.id: p};

    // Enrolled student IDs (active enrolments only)
    final enrolledIds = enrollments
        .where((e) => e.isActive)
        .map((e) => e.studentId)
        .toSet();

    // Students present via self check-in who are not in the enrolled list
    // (edge case — should rarely occur after auto-enrol)
    final selfCheckInIds = records
        .where(
          (r) =>
              r.checkInMethod == CheckInMethod.self &&
              !enrolledIds.contains(r.studentId),
        )
        .map((r) => r.studentId)
        .toSet();

    // Combined ordered list: enrolled first, then extra self-check-ins
    final allStudentIds = [...enrolledIds, ...selfCheckInIds];

    if (allStudentIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'No students enrolled in this discipline.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final presentCount = (_presentIds ?? {}).length;

    return Column(
      children: [
        // Summary bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                '$presentCount / ${allStudentIds.length} present',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _presentIds = Set.from(allStudentIds);
                    _isDirty = true;
                  });
                },
                child: const Text('All present'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _presentIds = {};
                    _isDirty = true;
                  });
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: allStudentIds.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final studentId = allStudentIds[i];
              final profile = profileMap[studentId];
              final isPresent = (_presentIds ?? {}).contains(studentId);
              final isSelfCheckIn = selfCheckInIds.contains(studentId);
              final record = records
                  .where((r) => r.studentId == studentId)
                  .firstOrNull;

              return _StudentAttendanceTile(
                studentId: studentId,
                profile: profile,
                isPresent: isPresent,
                isSelfCheckIn: isSelfCheckIn,
                checkInMethod: record?.checkInMethod,
                onToggle: (v) => _toggle(studentId, v),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Session header ────────────────────────────────────────────────────────────

class _SessionHeader extends ConsumerWidget {
  const _SessionHeader({required this.session, required this.disciplineName});

  final AttendanceSession session;
  final String disciplineName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateLabel = DateFormat(
      'EEEE, d MMM yyyy',
    ).format(session.sessionDate);
    final timeLabel = session.startTime.isNotEmpty
        ? '${session.startTime} – ${session.endTime}'
        : 'No time set';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.title?.isNotEmpty == true) ...[
                      Text(
                        session.title!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        disciplineName,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      dateLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (session.isRecurring) _EditRecurringButton(session: session),
            ],
          ),
          if (session.isRecurring) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.repeat, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Recurring · Weekly',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              session.notes!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Edit recurring session button ─────────────────────────────────────────────

class _EditRecurringButton extends ConsumerStatefulWidget {
  const _EditRecurringButton({required this.session});

  final AttendanceSession session;

  @override
  ConsumerState<_EditRecurringButton> createState() =>
      _EditRecurringButtonState();
}

class _EditRecurringButtonState extends ConsumerState<_EditRecurringButton> {
  bool _saving = false;

  Future<void> _onEdit() async {
    final scope = await showModalBottomSheet<_EditScope>(
      context: context,
      builder: (ctx) => const _EditScopeSheet(),
    );
    if (scope == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => _EditSessionDialog(
        session: widget.session,
        scope: scope,
        onSave: (title, start, end, notes) async {
          setState(() => _saving = true);
          try {
            final repo = ref.read(attendanceRepositoryProvider);
            if (scope == _EditScope.single) {
              await repo.updateSingleSession(
                sessionId: widget.session.id,
                title: title,
                startTime: start,
                endTime: end,
                notes: notes,
              );
            } else {
              await repo.updateFutureSessionsInGroup(
                groupId: widget.session.recurringGroupId!,
                fromDate: widget.session.sessionDate,
                title: title,
                startTime: start,
                endTime: end,
                notes: notes,
              );
            }
          } finally {
            if (mounted) setState(() => _saving = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _saving ? null : _onEdit,
      icon: _saving
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.edit_outlined),
      tooltip: 'Edit session',
    );
  }
}

// ── Edit scope sheet ──────────────────────────────────────────────────────────

enum _EditScope { single, allFuture }

class _EditScopeSheet extends StatelessWidget {
  const _EditScopeSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Edit recurring session',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('This session only'),
              subtitle: const Text('Only changes this single occurrence'),
              onTap: () => Navigator.of(context).pop(_EditScope.single),
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('This and all future sessions'),
              subtitle: const Text('Updates this and all upcoming occurrences'),
              onTap: () => Navigator.of(context).pop(_EditScope.allFuture),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit session dialog ───────────────────────────────────────────────────────

class _EditSessionDialog extends StatefulWidget {
  const _EditSessionDialog({
    required this.session,
    required this.scope,
    required this.onSave,
  });

  final AttendanceSession session;
  final _EditScope scope;
  final Future<void> Function(
    String? title,
    String start,
    String end,
    String? notes,
  )
  onSave;

  @override
  State<_EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<_EditSessionDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late String _start;
  late String _end;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.session.title ?? '');
    _notesCtrl = TextEditingController(text: widget.session.notes ?? '');
    _start = widget.session.startTime;
    _end = widget.session.endTime;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    TimeOfDay initial = TimeOfDay.now();
    if (current.isNotEmpty) {
      final parts = current.split(':');
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
    });
  }

  int _toMinutes(String t) {
    if (t.isEmpty) return -1;
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _save() async {
    if (_toMinutes(_end) <= _toMinutes(_start)) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final title = _titleCtrl.text.trim().isEmpty
          ? null
          : _titleCtrl.text.trim();
      final notes = _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim();
      await widget.onSave(title, _start, _end, notes);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scopeLabel = widget.scope == _EditScope.single
        ? 'Edit this session'
        : 'Edit this & future sessions';

    return AlertDialog(
      title: Text(scopeLabel),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickTime(isStart: true),
              icon: const Icon(Icons.access_time_outlined),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Start Time'),
                  Text(
                    _start.isEmpty ? 'Not set' : _start,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickTime(isStart: false),
              icon: const Icon(Icons.access_time_outlined),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('End Time'),
                  Text(
                    _end.isEmpty ? 'Not set' : _end,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Student attendance tile ───────────────────────────────────────────────────

class _StudentAttendanceTile extends StatelessWidget {
  const _StudentAttendanceTile({
    required this.studentId,
    required this.profile,
    required this.isPresent,
    required this.isSelfCheckIn,
    required this.checkInMethod,
    required this.onToggle,
  });

  final String studentId;
  final Profile? profile;
  final bool isPresent;
  final bool isSelfCheckIn;
  final CheckInMethod? checkInMethod;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName ?? studentId;

    return Card(
      elevation: 0,
      color: isPresent
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isPresent
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.surfaceVariant,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Checkbox(
          value: isPresent,
          onChanged: (v) => onToggle(v ?? false),
          activeColor: AppColors.primary,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: profile == null ? AppColors.textSecondary : null,
          ),
        ),
        subtitle: _buildSubtitle(),
        onTap: () => onToggle(!isPresent),
      ),
    );
  }

  Widget? _buildSubtitle() {
    if (checkInMethod == null) return null;

    String label;
    IconData icon;
    if (isSelfCheckIn) {
      label = 'Self check-in';
      icon = Icons.phone_android_outlined;
    } else if (checkInMethod == CheckInMethod.self) {
      label = 'Self check-in';
      icon = Icons.phone_android_outlined;
    } else if (checkInMethod == CheckInMethod.coach) {
      label = 'Coach marked';
      icon = Icons.sports_outlined;
    } else {
      return null;
    }

    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
