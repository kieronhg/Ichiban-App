import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/coach_profile_providers.dart';
import '../../../core/providers/dashboard_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/coach_profile.dart';
import 'admin_drawer.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event.dart';

class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(currentAdminUserProvider);
    final disciplineIds = ref.watch(assignedDisciplineIdsProvider);
    final coachProfile = adminUser != null
        ? ref.watch(coachProfileProvider(adminUser.firebaseUid)).asData?.value
        : null;

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: Text('Hi, ${adminUser?.firstName ?? 'Coach'}'),
        actions: [
          TextButton.icon(
            onPressed: () => context.pushNamed('adminMyProfile'),
            icon: const Icon(Icons.manage_accounts_outlined, size: 18),
            label: const Text('My Profile'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Quick actions',
            onSelected: (route) => context.pushNamed(route),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'createAttendanceSession',
                child: Text('Mark attendance'),
              ),
              PopupMenuItem(
                value: 'createGradingEvent',
                child: Text('Create grading'),
              ),
              PopupMenuItem(value: 'recordPayment', child: Text('Record PAYT')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Today's sessions ────────────────────────────────────────────
          _SectionLabel(label: "Today's sessions"),
          const SizedBox(height: 8),
          _TodaySessionsCard(disciplineIds: disciplineIds),

          const SizedBox(height: 20),

          // ── Compliance ───────────────────────────────────────────────────
          _SectionLabel(label: 'My compliance'),
          const SizedBox(height: 8),
          if (coachProfile != null)
            _ComplianceCard(profile: coachProfile)
          else
            const _CompliancePlaceholder(),

          const SizedBox(height: 20),

          // ── Discipline summaries ─────────────────────────────────────────
          if (disciplineIds.isNotEmpty) ...[
            _SectionLabel(label: 'My disciplines'),
            const SizedBox(height: 8),
            ...disciplineIds.map(
              (id) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DisciplineSummaryCard(disciplineId: id),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Today's sessions ──────────────────────────────────────────────────────────

class _TodaySessionsCard extends ConsumerWidget {
  const _TodaySessionsCard({required this.disciplineIds});

  final List<String> disciplineIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAllSessionsProvider);
    return todayAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (allSessions) {
        final sessions = disciplineIds.isEmpty
            ? allSessions
            : allSessions
                  .where((s) => disciplineIds.contains(s.disciplineId))
                  .toList();

        if (sessions.isEmpty) {
          return Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.surfaceVariant),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No sessions scheduled today',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.surfaceVariant),
          ),
          child: Column(
            children: sessions.map((s) => _SessionTile(session: s)).toList(),
          ),
        );
      },
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final dynamic session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineName =
        ref
            .watch(disciplineProvider(session.disciplineId))
            .asData
            ?.value
            ?.name ??
        session.disciplineId;
    final recordsAsync = ref.watch(
      attendanceRecordsForSessionProvider(session.id),
    );
    final attendeeCount = recordsAsync.asData?.value.length ?? 0;

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
      trailing: _AttendancePill(count: attendeeCount),
      onTap: () => context.pushNamed(
        'attendanceSession',
        pathParameters: {'sessionId': session.id},
      ),
    );
  }
}

class _AttendancePill extends StatelessWidget {
  const _AttendancePill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count in',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Compliance card ───────────────────────────────────────────────────────────

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.profile});

  final CoachProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ComplianceRow(label: 'DBS', record: profile.dbs),
            const Divider(height: 20),
            _FirstAidRow(record: profile.firstAid),
          ],
        ),
      ),
    );
  }
}

class _CompliancePlaceholder extends StatelessWidget {
  const _CompliancePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Compliance profile not found',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ComplianceRow extends StatelessWidget {
  const _ComplianceRow({required this.label, required this.record});

  final String label;
  final DbsRecord record;

  @override
  Widget build(BuildContext context) {
    final (color, statusLabel) = _dbsStatus(record);
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        if (record.expiryDate != null)
          Text(
            'Exp: ${DateFormat('d MMM yyyy').format(record.expiryDate!)}',
            style: TextStyle(
              fontSize: 12,
              color: _expiryColor(record.expiryDate!),
            ),
          ),
      ],
    );
  }

  (Color, String) _dbsStatus(DbsRecord r) {
    return switch (r.status) {
      DbsStatus.clear => (AppColors.success, 'Clear'),
      DbsStatus.pending => (AppColors.warning, 'Pending'),
      DbsStatus.expired => (AppColors.error, 'Expired'),
      DbsStatus.notSubmitted => (AppColors.textSecondary, 'Not submitted'),
    };
  }

  Color _expiryColor(DateTime expiry) {
    final diff = expiry.difference(DateTime.now()).inDays;
    if (diff < 0) return AppColors.error;
    if (diff < 30) return AppColors.warning;
    return AppColors.textSecondary;
  }
}

class _FirstAidRow extends StatelessWidget {
  const _FirstAidRow({required this.record});

  final FirstAidRecord record;

  @override
  Widget build(BuildContext context) {
    final hasData =
        record.certificationName != null || record.expiryDate != null;
    return Row(
      children: [
        const Text(
          'First Aid',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(width: 12),
        if (!hasData)
          const Text(
            'Not recorded',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          )
        else ...[
          Expanded(
            child: Text(
              record.certificationName ?? '',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (record.expiryDate != null)
            Text(
              'Exp: ${DateFormat('d MMM yyyy').format(record.expiryDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: _expiryColor(record.expiryDate!),
              ),
            ),
        ],
      ],
    );
  }

  Color _expiryColor(DateTime expiry) {
    final diff = expiry.difference(DateTime.now()).inDays;
    if (diff < 0) return AppColors.error;
    if (diff < 30) return AppColors.warning;
    return AppColors.textSecondary;
  }
}

// ── Discipline summary card ───────────────────────────────────────────────────

class _DisciplineSummaryCard extends ConsumerWidget {
  const _DisciplineSummaryCard({required this.disciplineId});

  final String disciplineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineName =
        ref.watch(disciplineProvider(disciplineId)).asData?.value?.name ??
        disciplineId;
    final summaryAsync = ref.watch(
      coachDisciplineSummaryProvider(disciplineId),
    );

    return Card(
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
                const Icon(
                  Icons.sports_martial_arts_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  disciplineName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (e, _) => const Text('Could not load summary'),
              data: (summary) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${summary.activeMemberCount} active member${summary.activeMemberCount == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  if (summary.upcomingGradings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...summary.upcomingGradings.map(
                      (g) => _UpcomingGradingRow(event: g),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingGradingRow extends StatelessWidget {
  const _UpcomingGradingRow({required this.event});

  final GradingEvent event;

  @override
  Widget build(BuildContext context) {
    final daysUntil = event.eventDate.difference(DateTime.now()).inDays;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.military_tech_outlined,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              event.title ??
                  'Grading — ${DateFormat('d MMM').format(event.eventDate)}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            daysUntil == 0
                ? 'Today'
                : daysUntil == 1
                ? 'Tomorrow'
                : 'In $daysUntil days',
            style: TextStyle(
              fontSize: 12,
              color: daysUntil <= 7
                  ? AppColors.accent
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
