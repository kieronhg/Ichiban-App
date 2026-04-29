import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/use_cases/grading/nominate_student_use_case.dart';

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
    final profileMap = {for (final p in allProfiles) p.id: p};

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
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final enrollment = eligibleEnrollments[i];
              final profile = profileMap[enrollment.studentId];
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

  Future<void> _nominateSelected({
    Set<String> overrideIds = const {},
  }) async {
    if (_selectedStudentIds.isEmpty) return;

    final enrollmentsAsync = ref.read(
      enrollmentsForDisciplineProvider(widget.event.disciplineId),
    );
    final enrollments = enrollmentsAsync.asData?.value ?? <Enrollment>[];
    final enrollmentMap = {for (final e in enrollments) e.studentId: e};

    final allProfiles = [
      ...ref.read(profilesByTypeProvider(ProfileType.adultStudent)).asData?.value ?? <Profile>[],
      ...ref.read(profilesByTypeProvider(ProfileType.juniorStudent)).asData?.value ?? <Profile>[],
    ];
    final profileMap = {for (final p in allProfiles) p.id: p};

    final adminId = ref.read(currentAdminIdProvider) ?? '';

    setState(() => _isSaving = true);

    int nominated = 0;
    final missingMembership = <String>[]; // studentIds

    for (final studentId in _selectedStudentIds) {
      final enrollment = enrollmentMap[studentId];
      if (enrollment == null) continue;
      try {
        await ref
            .read(nominateStudentUseCaseProvider)
            .call(
              gradingEventId: widget.event.id,
              studentId: studentId,
              disciplineId: widget.event.disciplineId,
              enrollmentId: enrollment.id,
              currentRankId: enrollment.currentRankId,
              adminId: adminId,
              allowWithoutMembership: overrideIds.contains(studentId),
            );
        nominated++;
      } on MissingMembershipException catch (e) {
        missingMembership.add(e.studentId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    // If any students had no membership, prompt the owner to override.
    if (missingMembership.isNotEmpty) {
      final names = missingMembership.map((id) {
        final p = profileMap[id];
        return p != null ? '${p.firstName} ${p.lastName}' : id;
      }).join(', ');

      final override = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No active membership'),
          content: Text(
            'The following student${missingMembership.length == 1 ? ' has' : 's have'} '
            'no active membership:\n\n$names\n\n'
            'Nominate them anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black87,
              ),
              child: const Text('Nominate Anyway'),
            ),
          ],
        ),
      );

      if (override == true && mounted) {
        await _nominateSelected(overrideIds: missingMembership.toSet());
        return;
      }
    }

    if (nominated > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$nominated student${nominated == 1 ? '' : 's'} nominated.',
          ),
        ),
      );
      context.pop();
    }
  }
}
