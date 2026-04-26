import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/student_session_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';

/// Landing screen shown to a student after PIN authentication.
///
/// Wraps the entire body in a [GestureDetector] so any tap or drag resets
/// the inactivity-timeout clock. When the [StudentSessionNotifier] timer fires
/// and sets [isAuthenticated] to false, the router redirect automatically
/// sends the student back to the select screen — no explicit navigation needed.
class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  void _updateActivity() =>
      ref.read(studentSessionProvider.notifier).updateActivity();

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studentSessionProvider);
    final profileAsync = session.profileId != null
        ? ref.watch(profileProvider(session.profileId!))
        : null;

    final firstName = profileAsync?.asData?.value?.firstName ?? 'Student';

    // Resolve coaches per discipline for enrolled disciplines.
    final enrollmentsAsync = session.profileId != null
        ? ref.watch(allEnrollmentsForStudentProvider(session.profileId!))
        : null;
    final activeEnrollments =
        enrollmentsAsync?.asData?.value.where((e) => e.isActive).toList() ??
        [];

    final allAdminsAsync = ref.watch(adminUserListProvider);
    final allAdmins = allAdminsAsync.asData?.value ?? [];
    final allDisciplinesAsync = ref.watch(disciplineListProvider);
    final disciplineMap = {
      for (final d in allDisciplinesAsync.asData?.value ?? []) d.id: d,
    };

    // Build a map: disciplineId → coach names string.
    final coachNamesByDiscipline = <String, String>{};
    for (final enrol in activeEnrollments) {
      final coaches = allAdmins
          .where(
            (a) =>
                a.isCoach &&
                a.isActive &&
                a.assignedDisciplineIds.contains(enrol.disciplineId),
          )
          .map((a) => a.fullName)
          .toList();
      if (coaches.isNotEmpty) {
        coachNamesByDiscipline[enrol.disciplineId] = coaches.join(', ');
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _updateActivity,
      onPanDown: (_) => _updateActivity(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Student Portal'),
          actions: [
            TextButton.icon(
              onPressed: () {
                ref.read(studentSessionProvider.notifier).signOut();
                context.go(RouteNames.entry);
              },
              icon: const Icon(Icons.logout_outlined, size: 18),
              label: const Text('Sign out'),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Welcome card ──────────────────────────────────────
                Card(
                  elevation: 0,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary,
                          child: const Icon(
                            Icons.sports_martial_arts,
                            color: AppColors.textOnPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hi, $firstName 👋',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready to train today?',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        // ── Coach names per discipline ─────────────
                        if (coachNamesByDiscipline.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          ...coachNamesByDiscipline.entries.map((entry) {
                            final disciplineName =
                                disciplineMap[entry.key]?.name ?? entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$disciplineName: ${entry.value}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Check In button ───────────────────────────────────
                FilledButton.icon(
                  onPressed: () {
                    _updateActivity();
                    context.pushNamed('studentCheckin');
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: const Text('Check In to a Class'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── My Grades button ──────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () {
                    _updateActivity();
                    context.pushNamed('studentGrades');
                  },
                  icon: const Icon(Icons.military_tech_outlined, size: 22),
                  label: const Text('My Grades'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
