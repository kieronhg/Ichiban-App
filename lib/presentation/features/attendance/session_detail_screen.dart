import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/auth_providers.dart';
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
      await ref
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attendance saved.')));
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

    return Scaffold(
      appBar: AppBar(
        title: Text(disciplineName),
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
          _SessionHeader(session: session),

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

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
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
          ),
        ],
      ),
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
