import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/coach_profile_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/attendance_session.dart';
import '../../../domain/entities/coach_profile.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAdmin = ref.watch(currentAdminUserProvider);
    if (currentAdmin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profileAsync = ref.watch(
      coachProfileProvider(currentAdmin.firebaseUid),
    );
    final disciplinesAsync = ref.watch(disciplineListProvider);
    final disciplines = disciplinesAsync.asData?.value ?? [];
    final disciplineMap = {for (final d in disciplines) d.id: d};

    final assignedNames = disciplines
        .where((d) => currentAdmin.assignedDisciplineIds.contains(d.id))
        .map((d) => d.name)
        .join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _PersonalDetailsCard(
              admin: currentAdmin,
              profile: profile,
              assignedDisciplineNames: assignedNames,
            ),
            const SizedBox(height: 16),
            if (profile != null) ...[
              _DbsCard(profile: profile),
              const SizedBox(height: 16),
              _FirstAidCard(profile: profile),
              const SizedBox(height: 16),
            ],
            _UpcomingSessionsCard(
              disciplineIds: currentAdmin.assignedDisciplineIds,
              disciplineMap: disciplineMap,
            ),
            const SizedBox(height: 16),
            _UpcomingGradingsCard(
              disciplineIds: currentAdmin.assignedDisciplineIds,
              disciplineMap: disciplineMap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Personal Details Card ──────────────────────────────────────────────────

class _PersonalDetailsCard extends StatelessWidget {
  const _PersonalDetailsCard({
    required this.admin,
    required this.profile,
    required this.assignedDisciplineNames,
  });

  final dynamic admin;
  final CoachProfile? profile;
  final String assignedDisciplineNames;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Personal Details',
      trailing: TextButton.icon(
        onPressed: () => context.pushNamed('coachMyProfileEdit'),
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Edit'),
      ),
      children: [
        _LabelValue(label: 'Name', value: admin.fullName),
        _LabelValue(label: 'Email', value: admin.email, muted: true),
        if (assignedDisciplineNames.isNotEmpty)
          _LabelValue(label: 'Disciplines', value: assignedDisciplineNames),
        if (profile?.qualificationsNotes?.isNotEmpty == true)
          _LabelValue(
            label: 'Qualifications',
            value: profile!.qualificationsNotes!,
          ),
      ],
    );
  }
}

// ── DBS Card ───────────────────────────────────────────────────────────────

class _DbsCard extends StatelessWidget {
  const _DbsCard({required this.profile});

  final CoachProfile profile;

  @override
  Widget build(BuildContext context) {
    final dbs = profile.dbs;
    final expiryInfo = _expiryInfo(dbs.expiryDate);

    return _SectionCard(
      title: 'DBS Check',
      trailing: TextButton.icon(
        onPressed: () => context.pushNamed('coachMyProfileDbs'),
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Update'),
      ),
      children: [
        Row(
          children: [
            _DbsStatusBadge(status: dbs.status),
            if (dbs.pendingVerification) ...[
              const SizedBox(width: 8),
              _PendingBadge(),
            ],
          ],
        ),
        if (dbs.certificateNumber != null) ...[
          const SizedBox(height: 4),
          _MaskedCertNumber(number: dbs.certificateNumber!),
        ],
        if (dbs.issueDate != null)
          _LabelValue(label: 'Issued', value: _formatDate(dbs.issueDate!)),
        if (dbs.expiryDate != null) ...[
          _LabelValue(label: 'Expires', value: _formatDate(dbs.expiryDate!)),
          if (expiryInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                expiryInfo.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: expiryInfo.color,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ── First Aid Card ─────────────────────────────────────────────────────────

class _FirstAidCard extends StatelessWidget {
  const _FirstAidCard({required this.profile});

  final CoachProfile profile;

  @override
  Widget build(BuildContext context) {
    final fa = profile.firstAid;
    final expiryInfo = _expiryInfo(fa.expiryDate);
    final hasDetails =
        fa.certificationName != null ||
        fa.issuingBody != null ||
        fa.issueDate != null;

    return _SectionCard(
      title: 'First Aid Certification',
      trailing: TextButton.icon(
        onPressed: () => context.pushNamed('coachMyProfileFirstAid'),
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Update'),
      ),
      children: [
        if (fa.pendingVerification) ...[
          _PendingBadge(),
          const SizedBox(height: 8),
        ],
        if (fa.certificationName != null)
          _LabelValue(label: 'Certification', value: fa.certificationName!),
        if (fa.issuingBody != null)
          _LabelValue(label: 'Issued by', value: fa.issuingBody!),
        if (fa.issueDate != null)
          _LabelValue(label: 'Issued', value: _formatDate(fa.issueDate!)),
        if (fa.expiryDate != null) ...[
          _LabelValue(label: 'Expires', value: _formatDate(fa.expiryDate!)),
          if (expiryInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                expiryInfo.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: expiryInfo.color,
                ),
              ),
            ),
        ],
        if (!hasDetails)
          Text(
            'No first aid details recorded.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
      ],
    );
  }
}

// ── Upcoming Sessions Card ─────────────────────────────────────────────────

class _UpcomingSessionsCard extends ConsumerWidget {
  const _UpcomingSessionsCard({
    required this.disciplineIds,
    required this.disciplineMap,
  });

  final List<String> disciplineIds;
  final Map<String, Discipline> disciplineMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    final allSessions = <AttendanceSession>[];
    for (final id in disciplineIds) {
      final async = ref.watch(attendanceSessionListProvider(id));
      allSessions.addAll(async.asData?.value ?? []);
    }

    final upcoming =
        allSessions.where((s) => s.sessionDate.isAfter(now)).toList()
          ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    final shown = upcoming.take(5).toList();

    return _SectionCard(
      title: 'Upcoming Sessions',
      trailing: TextButton(
        onPressed: () => context.go(RouteNames.adminAttendance),
        child: const Text('View all'),
      ),
      children: shown.isEmpty
          ? [
              Text(
                'No upcoming sessions.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ]
          : shown
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            disciplineMap[s.disciplineId]?.name ??
                                s.disciplineId,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${_formatDate(s.sessionDate)}  '
                          '${s.startTime}–${s.endTime}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
    );
  }
}

// ── Upcoming Gradings Card ─────────────────────────────────────────────────

class _UpcomingGradingsCard extends ConsumerWidget {
  const _UpcomingGradingsCard({
    required this.disciplineIds,
    required this.disciplineMap,
  });

  final List<String> disciplineIds;
  final Map<String, Discipline> disciplineMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    final allEvents = <GradingEvent>[];
    for (final id in disciplineIds) {
      final async = ref.watch(gradingEventsForDisciplineProvider(id));
      allEvents.addAll(async.asData?.value ?? []);
    }

    final upcoming =
        allEvents
            .where(
              (e) =>
                  e.status == GradingEventStatus.upcoming &&
                  e.eventDate.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    final shown = upcoming.take(3).toList();

    return _SectionCard(
      title: 'Upcoming Gradings',
      trailing: TextButton(
        onPressed: () => context.go(RouteNames.adminGrading),
        child: const Text('View all'),
      ),
      children: shown.isEmpty
          ? [
              Text(
                'No upcoming grading events.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ]
          : shown
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                disciplineMap[e.disciplineId]?.name ??
                                    e.disciplineId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (e.title?.isNotEmpty == true)
                                Text(
                                  e.title!,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(e.eventDate),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: muted ? AppColors.textSecondary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DbsStatusBadge extends StatelessWidget {
  const _DbsStatusBadge({required this.status});

  final DbsStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DbsStatus.clear => ('Clear', AppColors.success),
      DbsStatus.pending => ('Pending', AppColors.warning),
      DbsStatus.expired => ('Expired', AppColors.error),
      DbsStatus.notSubmitted => ('Not Submitted', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withAlpha(77)),
      ),
      child: const Text(
        'Awaiting verification',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.warning,
        ),
      ),
    );
  }
}

class _MaskedCertNumber extends StatefulWidget {
  const _MaskedCertNumber({required this.number});
  final String number;

  @override
  State<_MaskedCertNumber> createState() => _MaskedCertNumberState();
}

class _MaskedCertNumberState extends State<_MaskedCertNumber> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final last4 = widget.number.length > 4
        ? widget.number.substring(widget.number.length - 4)
        : widget.number;
    final display = _expanded ? widget.number : '••••••••$last4';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              'Certificate',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          Text(
            display,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Hide' : 'Show',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

String _formatDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

({String label, Color color})? _expiryInfo(DateTime? expiryDate) {
  if (expiryDate == null) return null;
  final now = DateTime.now();
  final diff = expiryDate.difference(now).inDays;
  if (diff < 0) {
    return (label: 'Expired ${-diff} days ago', color: AppColors.error);
  }
  if (diff <= 60) {
    return (label: 'Expires in $diff days', color: AppColors.warning);
  }
  return null;
}
