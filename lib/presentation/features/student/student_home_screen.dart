import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/dashboard_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/student_session_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import 'student_nav_bar.dart';
import '../../../domain/entities/attendance_session.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_record.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/rank.dart';

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
    final profile = profileAsync?.asData?.value;
    final firstName = profile?.firstName ?? 'Student';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _updateActivity,
      onPanDown: (_) => _updateActivity(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Student Portal'),
          actions: [
            if (session.profileId != null)
              _StudentBellButton(profileId: session.profileId!),
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
        bottomNavigationBar: const StudentNavBar(currentIndex: 0),
        body: SafeArea(
          child: session.profileId == null || profile == null
              ? _buildStudentView(
                  context,
                  profileId: session.profileId ?? '',
                  profile: null,
                  firstName: firstName,
                )
              : _buildRoleBasedView(context, profile: profile),
        ),
      ),
    );
  }

  Widget _buildRoleBasedView(BuildContext context, {required Profile profile}) {
    final isStudent = profile.isAdult || profile.isJunior;
    final isParent = profile.isParentGuardian;

    if (isStudent && isParent) {
      return _DualRoleView(profile: profile);
    } else if (isParent && !isStudent) {
      return _ParentOnlyView(profile: profile);
    } else {
      return _buildStudentView(
        context,
        profileId: profile.id,
        profile: profile,
        firstName: profile.firstName,
      );
    }
  }

  Widget _buildStudentView(
    BuildContext context, {
    required String profileId,
    required Profile? profile,
    required String firstName,
  }) {
    final enrollmentsAsync = profileId.isNotEmpty
        ? ref.watch(allEnrollmentsForStudentProvider(profileId))
        : null;
    final activeEnrollments =
        enrollmentsAsync?.asData?.value.where((e) => e.isActive).toList() ?? [];

    final allAdminsAsync = ref.watch(adminUserListProvider);
    final allAdmins = allAdminsAsync.asData?.value ?? [];
    final allDisciplinesAsync = ref.watch(disciplineListProvider);
    final disciplineMap = <String, Discipline>{
      for (final d in allDisciplinesAsync.asData?.value ?? []) d.id: d,
    };

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

    final membership = profileId.isNotEmpty
        ? ref.watch(membershipForStudentPortalProvider(profileId))
        : null;

    final gradingRecordsAsync = profileId.isNotEmpty
        ? ref.watch(gradingRecordsForStudentProvider(profileId))
        : null;
    final records = gradingRecordsAsync?.asData?.value ?? <GradingRecord>[];
    final byDiscipline = <String, List<GradingRecord>>{};
    for (final r in records) {
      byDiscipline.putIfAbsent(r.disciplineId, () => []).add(r);
    }
    for (final list in byDiscipline.values) {
      list.sort((a, b) => b.gradingDate.compareTo(a.gradingDate));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Welcome card ───────────────────────────────────────────────────
        _WelcomeCard(
          firstName: firstName,
          coachNamesByDiscipline: coachNamesByDiscipline,
          disciplineMap: disciplineMap,
        ),

        const SizedBox(height: 24),

        // ── Check In button ────────────────────────────────────────────────
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

        const SizedBox(height: 20),

        // ── Today's sessions ───────────────────────────────────────────────
        _StudentTodaySessions(
          disciplineIds: activeEnrollments
              .map((e) => e.disciplineId)
              .toSet()
              .toList(),
        ),

        // ── Membership status ──────────────────────────────────────────────
        if (membership != null) ...[
          const SizedBox(height: 20),
          _MembershipCard(membership: membership),
        ],

        // ── Grades ────────────────────────────────────────────────────────
        if (activeEnrollments.isNotEmpty) ...[
          const SizedBox(height: 20),
          _StudentGradesSection(
            enrollments: activeEnrollments,
            byDiscipline: byDiscipline,
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Welcome card ───────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.firstName,
    required this.coachNamesByDiscipline,
    required this.disciplineMap,
  });

  final String firstName;
  final Map<String, String> coachNamesByDiscipline;
  final Map<String, Discipline> disciplineMap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.sports_martial_arts,
                color: AppColors.textOnPrimary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hi, $firstName 👋',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ready to train today?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
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
    );
  }
}

// ── Today's sessions (student view) ──────────────────────────────────────────

class _StudentTodaySessions extends ConsumerWidget {
  const _StudentTodaySessions({required this.disciplineIds});

  final List<String> disciplineIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAllSessionsProvider);
    final sessions =
        todayAsync.asData?.value
            .where(
              (s) =>
                  disciplineIds.isEmpty ||
                  disciplineIds.contains(s.disciplineId),
            )
            .toList() ??
        [];

    if (sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TODAY'S CLASSES",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.surfaceVariant),
          ),
          child: Column(
            children: sessions
                .map((s) => _StudentSessionTile(session: s))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _StudentSessionTile extends ConsumerWidget {
  const _StudentSessionTile({required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineName =
        ref
            .watch(disciplineProvider(session.disciplineId))
            .asData
            ?.value
            ?.name ??
        session.disciplineId;

    return ListTile(
      dense: true,
      leading: const Icon(
        Icons.fitness_center_outlined,
        size: 20,
        color: AppColors.primary,
      ),
      title: Text(
        disciplineName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${session.startTime} – ${session.endTime}',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

// ── Membership card ───────────────────────────────────────────────────────────

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (membership.status) {
      MembershipStatus.active => AppColors.success,
      MembershipStatus.trial => AppColors.info,
      MembershipStatus.payt => AppColors.accent,
      _ => AppColors.textSecondary,
    };
    final statusLabel =
        membership.status.name[0].toUpperCase() +
        membership.status.name.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEMBERSHIP',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.surfaceVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.card_membership_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _planLabel(membership.planType),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (membership.subscriptionRenewalDate != null)
                        Text(
                          'Renews ${DateFormat('d MMM yyyy').format(membership.subscriptionRenewalDate!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (membership.trialEndDate != null &&
                          membership.status == MembershipStatus.trial)
                        Text(
                          'Trial ends ${DateFormat('d MMM yyyy').format(membership.trialEndDate!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _planLabel(MembershipPlanType plan) {
    return switch (plan) {
      MembershipPlanType.monthlyAdult => 'Monthly (Adult)',
      MembershipPlanType.monthlyJunior => 'Monthly (Junior)',
      MembershipPlanType.annualAdult => 'Annual (Adult)',
      MembershipPlanType.annualJunior => 'Annual (Junior)',
      MembershipPlanType.familyMonthly => 'Family Monthly',
      MembershipPlanType.payAsYouTrainAdult => 'Pay as You Train',
      MembershipPlanType.payAsYouTrainJunior => 'Pay as You Train (Junior)',
      MembershipPlanType.trial => 'Trial',
    };
  }
}

// ── Grades section ─────────────────────────────────────────────────────────────

class _StudentGradesSection extends ConsumerWidget {
  const _StudentGradesSection({
    required this.enrollments,
    required this.byDiscipline,
  });

  final List<Enrollment> enrollments;
  final Map<String, List<GradingRecord>> byDiscipline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MY GRADES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            TextButton(
              onPressed: () => context.pushNamed('studentGrades'),
              child: const Text('See all', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...enrollments.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InlineGradeCard(
              enrollment: e,
              records: byDiscipline[e.disciplineId] ?? [],
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineGradeCard extends ConsumerWidget {
  const _InlineGradeCard({required this.enrollment, required this.records});

  final Enrollment enrollment;
  final List<GradingRecord> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(
      disciplineProvider(enrollment.disciplineId),
    );
    final ranksAsync = ref.watch(rankListProvider(enrollment.disciplineId));

    final disciplineName =
        disciplineAsync.asData?.value?.name ?? enrollment.disciplineId;
    final ranks = ranksAsync.asData?.value ?? <Rank>[];
    final currentRank = ranks
        .where((r) => r.id == enrollment.currentRankId)
        .firstOrNull;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _BeltIcon(colourHex: currentRank?.colourHex),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disciplineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentRank?.name ?? 'Unknown rank',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (records.isNotEmpty)
                    Text(
                      '${records.length} grading${records.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Belt icon ─────────────────────────────────────────────────────────────────

class _BeltIcon extends StatelessWidget {
  const _BeltIcon({this.colourHex});

  final String? colourHex;

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (colourHex != null && colourHex!.length == 7) {
      final hex = colourHex!.replaceFirst('#', '');
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) color = Color(value);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.15) ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color ?? AppColors.textSecondary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.military_tech_outlined,
        color: color ?? AppColors.textSecondary,
        size: 22,
      ),
    );
  }
}

// ── Dual-role view (parent + student) ─────────────────────────────────────────

class _DualRoleView extends ConsumerStatefulWidget {
  const _DualRoleView({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_DualRoleView> createState() => _DualRoleViewState();
}

class _DualRoleViewState extends ConsumerState<_DualRoleView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'My Training'),
            Tab(text: 'Family'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _StudentTrainingTab(profile: widget.profile),
              _FamilyTab(parentId: widget.profile.id),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentTrainingTab extends ConsumerWidget {
  const _StudentTrainingTab({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(
      allEnrollmentsForStudentProvider(profile.id),
    );
    final activeEnrollments =
        enrollmentsAsync.asData?.value.where((e) => e.isActive).toList() ?? [];
    final membership = ref.watch(
      membershipForStudentPortalProvider(profile.id),
    );

    final gradingRecordsAsync = ref.watch(
      gradingRecordsForStudentProvider(profile.id),
    );
    final records = gradingRecordsAsync.asData?.value ?? <GradingRecord>[];
    final byDiscipline = <String, List<GradingRecord>>{};
    for (final r in records) {
      byDiscipline.putIfAbsent(r.disciplineId, () => []).add(r);
    }
    for (final list in byDiscipline.values) {
      list.sort((a, b) => b.gradingDate.compareTo(a.gradingDate));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _StudentTodaySessions(
          disciplineIds: activeEnrollments
              .map((e) => e.disciplineId)
              .toSet()
              .toList(),
        ),
        if (membership != null) ...[
          const SizedBox(height: 20),
          _MembershipCard(membership: membership),
        ],
        if (activeEnrollments.isNotEmpty) ...[
          const SizedBox(height: 20),
          _StudentGradesSection(
            enrollments: activeEnrollments,
            byDiscipline: byDiscipline,
          ),
        ],
      ],
    );
  }
}

// ── Parent-only view ──────────────────────────────────────────────────────────

class _ParentOnlyView extends ConsumerWidget {
  const _ParentOnlyView({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(
      membershipForStudentPortalProvider(profile.id),
    );
    final children = ref.watch(childProfilesForParentProvider(profile.id));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Hi, ${profile.firstName} 👋',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Family account',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),

        if (membership != null) ...[
          const SizedBox(height: 24),
          _MembershipCard(membership: membership),
        ],

        const SizedBox(height: 24),

        const Text(
          'LINKED CHILDREN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        if (children.isEmpty)
          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No linked children found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...children.map((child) => _ChildCard(child: child)),
      ],
    );
  }
}

class _ChildCard extends ConsumerWidget {
  const _ChildCard({required this.child});

  final Profile child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(
      allEnrollmentsForStudentProvider(child.id),
    );
    final activeEnrollments =
        enrollmentsAsync.asData?.value.where((e) => e.isActive).toList() ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.surfaceVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person,
                      color: AppColors.textOnPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    child.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (activeEnrollments.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...activeEnrollments.map(
                  (e) => _ChildEnrollmentRow(enrollment: e),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildEnrollmentRow extends ConsumerWidget {
  const _ChildEnrollmentRow({required this.enrollment});

  final Enrollment enrollment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineName =
        ref
            .watch(disciplineProvider(enrollment.disciplineId))
            .asData
            ?.value
            ?.name ??
        enrollment.disciplineId;
    final ranksAsync = ref.watch(rankListProvider(enrollment.disciplineId));
    final ranks = ranksAsync.asData?.value ?? <Rank>[];
    final rankName =
        ranks
            .where((r) => r.id == enrollment.currentRankId)
            .firstOrNull
            ?.name ??
        '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 48),
      child: Row(
        children: [
          const Icon(
            Icons.sports_martial_arts_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            '$disciplineName — $rankName',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Family tab (used inside dual-role view) ───────────────────────────────────

class _FamilyTab extends ConsumerWidget {
  const _FamilyTab({required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childProfilesForParentProvider(parentId));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (children.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No linked children.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...children.map((child) => _ChildCard(child: child)),
      ],
    );
  }
}

// ── Bell button for student AppBar ────────────────────────────────────────────

class _StudentBellButton extends ConsumerWidget {
  const _StudentBellButton({required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications =
        ref.watch(studentNotificationsProvider(profileId)).asData?.value ?? [];
    final unread = notifications.where((n) => n.isRead != true).length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => context.pushNamed('studentNotifications'),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
