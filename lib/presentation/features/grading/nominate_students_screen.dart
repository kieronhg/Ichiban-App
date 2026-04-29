import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/rank.dart';

class NominateStudentsScreen extends ConsumerStatefulWidget {
  const NominateStudentsScreen({super.key, required this.event});

  final GradingEvent event;

  @override
  ConsumerState<NominateStudentsScreen> createState() =>
      _NominateStudentsScreenState();
}

class _NominateStudentsScreenState
    extends ConsumerState<NominateStudentsScreen> {
  final Set<String> _selectedStudentIds = {};
  bool _isSaving = false;

  // Cached during build so _nominateSelected can read profile names without
  // calling ref.read inside an async gap.
  Map<String, Profile> _profileMap = {};

  @override
  Widget build(BuildContext context) {
    final enrollmentsAsync = ref.watch(
      enrollmentsForDisciplineProvider(widget.event.disciplineId),
    );
    final eventStudentsAsync = ref.watch(
      gradingEventStudentsProvider(widget.event.id),
    );
    final profilesAsync = ref.watch(
      profilesByTypeProvider(ProfileType.adultStudent),
    );
    final juniorProfilesAsync = ref.watch(
      profilesByTypeProvider(ProfileType.juniorStudent),
    );

    final alreadyNominatedIds = {
      for (final s in eventStudentsAsync.asData?.value ?? <dynamic>[])
        s.studentId as String,
    };

    final allProfiles = [
      ...profilesAsync.asData?.value ?? <Profile>[],
      ...juniorProfilesAsync.asData?.value ?? <Profile>[],
    ];
    _profileMap = {for (final p in allProfiles) p.id: p};

    final enrollments = enrollmentsAsync.asData?.value ?? <Enrollment>[];
    final eligibleEnrollments = enrollments
        .where((e) => e.isActive && !alreadyNominatedIds.contains(e.studentId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nominate Students'),
        actions: [
          if (_selectedStudentIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _isSaving ? null : _nominateSelected,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Nominate (${_selectedStudentIds.length})',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: enrollmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) {
          if (eligibleEnrollments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.success.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'All enrolled students have already been nominated.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: eligibleEnrollments.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final enrollment = eligibleEnrollments[i];
              final profile = _profileMap[enrollment.studentId];
              final name = profile != null
                  ? '${profile.firstName} ${profile.lastName}'
                  : enrollment.studentId;
              final selected = _selectedStudentIds.contains(
                enrollment.studentId,
              );

              return CheckboxListTile(
                value: selected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedStudentIds.add(enrollment.studentId);
                    } else {
                      _selectedStudentIds.remove(enrollment.studentId);
                    }
                  });
                },
                title: Text(name),
                activeColor: AppColors.accent,
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _nominateSelected() async {
    if (_selectedStudentIds.isEmpty) return;

    final enrollmentsAsync = ref.read(
      enrollmentsForDisciplineProvider(widget.event.disciplineId),
    );
    final enrollments = enrollmentsAsync.asData?.value ?? <Enrollment>[];
    final enrollmentMap = {for (final e in enrollments) e.studentId: e};

    // Ranks for this discipline sorted by displayOrder (ascending).
    final ranks =
        (ref.read(rankListProvider(widget.event.disciplineId)).asData?.value ??
              <Rank>[])
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    // ── Attendance check ─────────────────────────────────────────────────────
    // For each selected student, find their next rank. If that rank has a
    // minAttendanceForGrading, verify the student has enough sessions.
    final warnings = <_AttendanceWarning>[];

    for (final studentId in _selectedStudentIds) {
      final enrollment = enrollmentMap[studentId];
      if (enrollment == null) continue;

      final currentIndex = ranks.indexWhere(
        (r) => r.id == enrollment.currentRankId,
      );
      final nextRank = (currentIndex >= 0 && currentIndex < ranks.length - 1)
          ? ranks[currentIndex + 1]
          : null;

      final minimum = nextRank?.minAttendanceForGrading;
      if (minimum == null) continue; // no threshold set — skip

      final records = await ref
          .read(getAttendanceRecordsUseCaseProvider)
          .getForStudentAndDiscipline(studentId, widget.event.disciplineId);

      if (records.length < minimum) {
        warnings.add(
          _AttendanceWarning(
            studentName: _profileMap[studentId]?.fullName ?? studentId,
            targetRankName: nextRank!.name,
            actual: records.length,
            required: minimum,
          ),
        );
      }
    }

    // ── Warning dialog ───────────────────────────────────────────────────────
    if (warnings.isNotEmpty && mounted) {
      final proceed = await _showAttendanceWarningDialog(warnings);
      if (!proceed) return;
    }

    // ── Write nominations ────────────────────────────────────────────────────
    final adminId = ref.read(currentAdminIdProvider) ?? '';

    setState(() => _isSaving = true);
    try {
      for (final studentId in _selectedStudentIds) {
        final enrollment = enrollmentMap[studentId];
        if (enrollment == null) continue;
        await ref
            .read(nominateStudentUseCaseProvider)
            .call(
              gradingEventId: widget.event.id,
              studentId: studentId,
              disciplineId: widget.event.disciplineId,
              enrollmentId: enrollment.id,
              currentRankId: enrollment.currentRankId,
              adminId: adminId,
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedStudentIds.length} student${_selectedStudentIds.length == 1 ? '' : 's'} nominated.',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _showAttendanceWarningDialog(
    List<_AttendanceWarning> warnings,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text('Attendance Below Minimum'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              warnings.length == 1
                  ? 'This student has not reached the minimum attendance for their target rank:'
                  : '${warnings.length} students have not reached the minimum attendance for their target rank:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: w.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' — ${w.actual} session${w.actual == 1 ? '' : 's'}'
                                  ' attended, ${w.required} needed for ${w.targetRankName}.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'You can still nominate them — this is a warning only.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nominate Anyway'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ── Data class for attendance warning ─────────────────────────────────────────

class _AttendanceWarning {
  const _AttendanceWarning({
    required this.studentName,
    required this.targetRankName,
    required this.actual,
    required this.required,
  });

  final String studentName;
  final String targetRankName;
  final int actual;
  final int required;
}
