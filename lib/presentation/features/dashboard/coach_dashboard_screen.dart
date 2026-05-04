import 'dart:math' as math;

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
import '../../../domain/entities/attendance_session.dart';
import '../../../domain/entities/coach_profile.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event.dart';
import 'admin_drawer.dart';

class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(currentAdminUserProvider);
    final firstName = adminUser?.firstName ?? 'Coach';
    final disciplineIds = ref.watch(assignedDisciplineIdsProvider);

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: Text(_greeting(firstName)),
        actions: [
          TextButton.icon(
            onPressed: () => context.pushNamed('adminMyProfile'),
            icon: const Icon(Icons.manage_accounts_outlined, size: 18),
            label: const Text('My profile'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Quick actions',
            onSelected: (route) => context.pushNamed(route),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'adminAttendanceCreate',
                child: Text('Mark attendance'),
              ),
              PopupMenuItem(
                value: 'adminGradingCreate',
                child: Text('Create grading'),
              ),
              PopupMenuItem(
                value: 'adminPaymentsRecord',
                child: Text('Record PAYT'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CoachGreetingHeader(
            disciplineIds: disciplineIds,
            firstName: firstName,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return _WideLayout(disciplineIds: disciplineIds);
              }
              return _NarrowLayout(disciplineIds: disciplineIds);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _greeting(String firstName) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return '$salutation, $firstName';
  }
}

// ── Greeting header ───────────────────────────────────────────────────────────

class _CoachGreetingHeader extends ConsumerWidget {
  const _CoachGreetingHeader({
    required this.disciplineIds,
    required this.firstName,
  });

  final List<String> disciplineIds;
  final String firstName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingAsync = ref.watch(
      coachRemainingWeekSessionsProvider(disciplineIds),
    );
    final remaining = remainingAsync.asData?.value ?? 0;
    final summaryText = remaining == 0
        ? 'No more sessions this week.'
        : remaining == 1
        ? 'One session left this week.'
        : '$remaining sessions left this week.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE d MMMM · HH:mm').format(DateTime.now()),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 0.8,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                summaryText,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (disciplineIds.isNotEmpty)
              Wrap(
                spacing: 6,
                children: disciplineIds
                    .map((id) => _DisciplineScopeTag(disciplineId: id))
                    .toList(),
              ),
          ],
        ),
      ],
    );
  }
}

class _DisciplineScopeTag extends ConsumerWidget {
  const _DisciplineScopeTag({required this.disciplineId});

  final String disciplineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        ref.watch(disciplineProvider(disciplineId)).asData?.value?.name ??
        disciplineId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _disciplineColor(name),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wide layout ───────────────────────────────────────────────────────────────

class _WideLayout extends ConsumerWidget {
  const _WideLayout({required this.disciplineIds});

  final List<String> disciplineIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _LeftColumn(disciplineIds: disciplineIds)),
        const SizedBox(width: 14),
        Expanded(flex: 4, child: _RightColumn(disciplineIds: disciplineIds)),
      ],
    );
  }
}

// ── Narrow layout ─────────────────────────────────────────────────────────────

class _NarrowLayout extends ConsumerWidget {
  const _NarrowLayout({required this.disciplineIds});

  final List<String> disciplineIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _TodaySessionsPanel(disciplineIds: disciplineIds),
        const SizedBox(height: 14),
        _UpcomingGradingsPanel(disciplineIds: disciplineIds),
        const SizedBox(height: 14),
        _RightColumn(disciplineIds: disciplineIds),
      ],
    );
  }
}

// ── Left column ───────────────────────────────────────────────────────────────

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.disciplineIds});

  final List<String> disciplineIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TodaySessionsPanel(disciplineIds: disciplineIds),
        const SizedBox(height: 14),
        _UpcomingGradingsPanel(disciplineIds: disciplineIds),
      ],
    );
  }
}

// ── Right column ──────────────────────────────────────────────────────────────

class _RightColumn extends ConsumerWidget {
  const _RightColumn({required this.disciplineIds});

  final List<String> disciplineIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(currentAdminUserProvider);
    final coachProfile = adminUser != null
        ? ref.watch(coachProfileProvider(adminUser.firebaseUid)).asData?.value
        : null;

    return Column(
      children: [
        _CompliancePanel(profile: coachProfile),
        const SizedBox(height: 14),
        _DisciplineSummaryPanel(disciplineIds: disciplineIds),
        const SizedBox(height: 14),
        _QuickActionsPanel(disciplineIds: disciplineIds),
      ],
    );
  }
}

// ── Today's sessions panel ────────────────────────────────────────────────────

class _TodaySessionsPanel extends ConsumerWidget {
  const _TodaySessionsPanel({required this.disciplineIds});

  final List<String> disciplineIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAllSessionsProvider);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's sessions",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    disciplineIds.isEmpty
                        ? 'All disciplines'
                        : 'Scoped to your disciplines',
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.5,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
              const _LiveIndicator(),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.hairline),
          todayAsync.when(
            loading: () => const _SessionSkeleton(),
            error: (e, _) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Could not load sessions'),
            ),
            data: (allSessions) {
              final sessions = disciplineIds.isEmpty
                  ? allSessions
                  : allSessions
                        .where((s) => disciplineIds.contains(s.disciplineId))
                        .toList();

              if (sessions.isEmpty) {
                return _SessionEmptyState(
                  onCreateTap: () => context.pushNamed('adminAttendanceCreate'),
                );
              }

              // Sort by startTime ascending
              sessions.sort((a, b) => a.startTime.compareTo(b.startTime));

              return Column(
                children: sessions.map((s) => _SessionRow(session: s)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Session row ───────────────────────────────────────────────────────────────

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.session});

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
    final recordsAsync = ref.watch(
      attendanceRecordsForSessionProvider(session.id),
    );
    final checkedIn = recordsAsync.asData?.value.length ?? 0;

    final enrolledCount =
        ref
            .watch(coachDisciplineSummaryProvider(session.disciplineId))
            .asData
            ?.value
            .activeMemberCount ??
        0;

    final now = DateTime.now();
    final sessionStart = _parseTime(session.startTime, session.sessionDate);
    final sessionEnd = _parseTime(session.endTime, session.sessionDate);
    final minutesUntilStart = sessionStart.difference(now).inMinutes;
    final isUpNext = minutesUntilStart > 0 && minutesUntilStart <= 60;
    final isInProgress = now.isAfter(sessionStart) && now.isBefore(sessionEnd);
    final isHighlighted = isUpNext || isInProgress;

    final disciplineColor = _disciplineColor(disciplineName);
    final fraction = enrolledCount > 0 ? checkedIn / enrolledCount : 0.0;

    return Container(
      decoration: isHighlighted
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.ochre.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUpNext || isInProgress)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _UpNextTag(
                isInProgress: isInProgress,
                minutesUntilStart: minutesUntilStart,
                sessionStart: sessionStart,
                now: now,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Time column
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.startTime,
                      style: TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isUpNext ? AppColors.ochre : AppColors.ink1,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      '– ${session.endTime}',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 10,
                        color: AppColors.ink3,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Name + sub
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: disciplineColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.title ?? disciplineName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (session.notes != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        session.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Check-in count + progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink1,
                      ),
                      children: [
                        TextSpan(
                          text: '$checkedIn',
                          style: const TextStyle(fontSize: 20, height: 1),
                        ),
                        if (enrolledCount > 0)
                          TextSpan(
                            text: ' / $enrolledCount',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.ink3,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.paper3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: fraction.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: fraction >= 0.9
                              ? AppColors.ochre
                              : AppColors.success,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.hairline),
        ],
      ),
    );
  }

  DateTime _parseTime(String timeStr, DateTime date) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return date;
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );
  }
}

class _UpNextTag extends StatelessWidget {
  const _UpNextTag({
    required this.isInProgress,
    required this.minutesUntilStart,
    required this.sessionStart,
    required this.now,
  });

  final bool isInProgress;
  final int minutesUntilStart;
  final DateTime sessionStart;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final label = isInProgress
        ? 'In progress · ${now.difference(sessionStart).inMinutes}m'
        : 'Up next · ${minutesUntilStart}m';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ochre.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: 0.8,
          color: AppColors.ochre,
        ),
      ),
    );
  }
}

// ── Session empty state ───────────────────────────────────────────────────────

class _SessionEmptyState extends StatelessWidget {
  const _SessionEmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.hairline,
                style: BorderStyle.solid,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '空',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.ink3),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No classes today.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.ink2),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set up next week\'s schedule from the Attendance section.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.ink3),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onCreateTap,
            child: const Text('+ Create session'),
          ),
        ],
      ),
    );
  }
}

// ── Session skeleton ──────────────────────────────────────────────────────────

class _SessionSkeleton extends StatelessWidget {
  const _SessionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_SkeletonRow(), const SizedBox(height: 4), _SkeletonRow()],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Skel(width: 48, height: 14),
              const SizedBox(height: 6),
              _Skel(width: 36, height: 10),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Skel(width: double.infinity, height: 16),
                const SizedBox(height: 6),
                _Skel(width: 160, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Skel(width: 56, height: 22),
              const SizedBox(height: 6),
              _Skel(width: 100, height: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class _Skel extends StatefulWidget {
  const _Skel({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_Skel> createState() => _SkelState();
}

class _SkelState extends State<_Skel> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: widget.width == double.infinity ? null : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              colors: const [
                AppColors.paper2,
                AppColors.paper3,
                AppColors.paper2,
              ],
              stops: [
                math.max(0.0, _ctrl.value - 0.3),
                _ctrl.value,
                math.min(1.0, _ctrl.value + 0.3),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Live indicator ────────────────────────────────────────────────────────────

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing ring
                  Opacity(
                    opacity: (1.0 - _ctrl.value).clamp(0.0, 1.0),
                    child: Container(
                      width: 7 + _ctrl.value * 9,
                      height: 7 + _ctrl.value * 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.success, width: 1),
                      ),
                    ),
                  ),
                  // Solid dot
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'LIVE',
          style: TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 10,
            letterSpacing: 0.8,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

// ── Upcoming gradings panel ───────────────────────────────────────────────────

class _UpcomingGradingsPanel extends ConsumerWidget {
  const _UpcomingGradingsPanel({required this.disciplineIds});

  final List<String> disciplineIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gather upcoming gradings from all assigned disciplines
    final allGradings = <GradingEvent>[];
    for (final id in disciplineIds) {
      final summary = ref
          .watch(coachDisciplineSummaryProvider(id))
          .asData
          ?.value;
      if (summary != null) allGradings.addAll(summary.upcomingGradings);
    }
    allGradings.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    final gradings = allGradings.take(3).toList();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming gradings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'NEXT 3 · YOUR DISCIPLINES',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.5,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.pushNamed('adminGradingCreate'),
                child: const Text('+ Create event'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: AppColors.hairline),
          if (gradings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No upcoming gradings',
                  style: TextStyle(color: AppColors.ink3, fontSize: 13),
                ),
              ),
            )
          else
            ...gradings.map(
              (g) => _GradingRow(
                event: g,
                onTap: () => context.pushNamed(
                  'adminGradingDetail',
                  pathParameters: {'eventId': g.id},
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradingRow extends StatelessWidget {
  const _GradingRow({required this.event, required this.onTap});

  final GradingEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Calendar date block
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                border: Border.all(color: AppColors.hairline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE').format(event.eventDate).toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 9,
                      letterSpacing: 0.8,
                      color: AppColors.ink3,
                    ),
                  ),
                  Text(
                    DateFormat('dd').format(event.eventDate),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(event.eventDate).toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 9,
                      letterSpacing: 0.8,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title ??
                        'Grading — ${DateFormat('d MMM').format(event.eventDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusLabel(event.status),
                    style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }

  String _statusLabel(GradingEventStatus status) {
    return switch (status) {
      GradingEventStatus.upcoming => 'Upcoming',
      GradingEventStatus.completed => 'Completed',
      GradingEventStatus.cancelled => 'Cancelled',
    };
  }
}

// ── Compliance panel ──────────────────────────────────────────────────────────

class _CompliancePanel extends StatelessWidget {
  const _CompliancePanel({required this.profile});

  final CoachProfile? profile;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your compliance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'PERSONAL — ONLY YOU CAN SEE THIS',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.5,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.pushNamed('adminMyProfile'),
                child: const Text(
                  'Update',
                  style: TextStyle(color: AppColors.ink3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (profile == null)
            const Text(
              'Compliance profile not found',
              style: TextStyle(color: AppColors.ink3, fontSize: 13),
            )
          else ...[
            _ComplianceRow(
              label: 'DBS check',
              certName: profile!.dbs.certificateNumber != null
                  ? 'Cert ••••${_lastFour(profile!.dbs.certificateNumber!)}'
                  : null,
              expiryDate: profile!.dbs.expiryDate,
              status: _dbsComplianceStatus(profile!.dbs),
              isPending: profile!.dbs.pendingVerification,
              icon: Icons.shield_outlined,
            ),
            const SizedBox(height: 8),
            _ComplianceRow(
              label: 'First aid',
              certName: profile!.firstAid.certificationName,
              expiryDate: profile!.firstAid.expiryDate,
              status: _firstAidComplianceStatus(profile!.firstAid),
              isPending: profile!.firstAid.pendingVerification,
              icon: Icons.medical_services_outlined,
            ),
            if (profile!.dbs.pendingVerification) ...[
              const SizedBox(height: 8),
              _PendingVerificationRow(),
            ],
          ],
        ],
      ),
    );
  }

  _ComplianceStatus _dbsComplianceStatus(DbsRecord dbs) {
    if (dbs.status == DbsStatus.expired) return _ComplianceStatus.danger;
    if (dbs.expiryDate != null) {
      final days = dbs.expiryDate!.difference(DateTime.now()).inDays;
      if (days < 0) return _ComplianceStatus.danger;
      if (days < 60) return _ComplianceStatus.warn;
    }
    if (dbs.status == DbsStatus.notSubmitted) return _ComplianceStatus.pending;
    return _ComplianceStatus.clear;
  }

  _ComplianceStatus _firstAidComplianceStatus(FirstAidRecord fa) {
    if (fa.expiryDate != null) {
      final days = fa.expiryDate!.difference(DateTime.now()).inDays;
      if (days < 0) return _ComplianceStatus.danger;
      if (days < 60) return _ComplianceStatus.warn;
    }
    if (fa.certificationName == null) return _ComplianceStatus.pending;
    return _ComplianceStatus.clear;
  }
}

enum _ComplianceStatus { clear, warn, danger, pending }

class _ComplianceRow extends StatelessWidget {
  const _ComplianceRow({
    required this.label,
    required this.certName,
    required this.expiryDate,
    required this.status,
    required this.isPending,
    required this.icon,
  });

  final String label;
  final String? certName;
  final DateTime? expiryDate;
  final _ComplianceStatus status;
  final bool isPending;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final (borderColor, iconBg, iconColor, badgeText, badgeBg, badgeFg) =
        _style();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper1,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: borderColor, width: 2),
          top: const BorderSide(color: AppColors.hairline),
          right: const BorderSide(color: AppColors.hairline),
          bottom: const BorderSide(color: AppColors.hairline),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: AppColors.ink3,
                  ),
                ),
                if (certName != null)
                  Text(
                    certName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (expiryDate != null)
                  Text(
                    _expiryText(expiryDate!),
                    style: TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 11,
                      color: borderColor == AppColors.hairline
                          ? AppColors.ink3
                          : borderColor,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              badgeText.toUpperCase(),
              style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 9,
                letterSpacing: 0.8,
                color: badgeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color, String, Color, Color) _style() {
    return switch (status) {
      _ComplianceStatus.clear => (
        AppColors.hairline,
        AppColors.successWash,
        AppColors.success,
        'Clear',
        AppColors.successWash,
        AppColors.success,
      ),
      _ComplianceStatus.warn => (
        AppColors.ochre,
        AppColors.ochreWash,
        AppColors.ochre,
        'Renew soon',
        AppColors.ochreWash,
        AppColors.ochre,
      ),
      _ComplianceStatus.danger => (
        AppColors.error,
        AppColors.errorWash,
        AppColors.error,
        'Action required',
        AppColors.errorWash,
        AppColors.error,
      ),
      _ComplianceStatus.pending => (
        AppColors.hairline,
        AppColors.paper3,
        AppColors.ink2,
        'Not recorded',
        AppColors.paper3,
        AppColors.ink2,
      ),
    };
  }

  String _expiryText(DateTime d) {
    final days = d.difference(DateTime.now()).inDays;
    final formatted = DateFormat('d MMM yyyy').format(d);
    if (days < 0) return 'Expired $formatted';
    if (days < 60) return 'Expires $formatted · in $days days';
    return 'Expires $formatted';
  }
}

class _PendingVerificationRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper1,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: const BorderSide(color: AppColors.indigo, width: 2),
          top: const BorderSide(color: AppColors.hairline),
          right: const BorderSide(color: AppColors.hairline),
          bottom: const BorderSide(color: AppColors.hairline),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.access_time_outlined,
              size: 16,
              color: AppColors.indigo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PENDING VERIFICATION',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: AppColors.indigo,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'DBS update submitted — owner will verify within 48h',
                  style: TextStyle(fontSize: 13, color: AppColors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Discipline summary panel ──────────────────────────────────────────────────

class _DisciplineSummaryPanel extends ConsumerWidget {
  const _DisciplineSummaryPanel({required this.disciplineIds});

  final List<String> disciplineIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (disciplineIds.isEmpty) return const SizedBox.shrink();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discipline summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              const Text(
                'MEMBERS IN YOUR DISCIPLINES',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.5,
                  color: AppColors.ink3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.hairline),
          ...disciplineIds.map((id) => _DisciplineStatsRow(disciplineId: id)),
        ],
      ),
    );
  }
}

class _DisciplineStatsRow extends ConsumerWidget {
  const _DisciplineStatsRow({required this.disciplineId});

  final String disciplineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        ref.watch(disciplineProvider(disciplineId)).asData?.value?.name ??
        disciplineId;
    final statsAsync = ref.watch(coachDisciplineStatsProvider(disciplineId));
    final stats = statsAsync.asData?.value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _disciplineColor(name),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (stats != null) ...[
                _StatCol(
                  value: '${stats.enrolled}',
                  label: 'Enrolled',
                  isWarning: false,
                ),
                const SizedBox(width: 8),
                _StatCol(
                  value: '${stats.lapsed}',
                  label: 'Lapsed',
                  isWarning: stats.lapsed > 0,
                ),
                const SizedBox(width: 8),
                _StatCol(
                  value: '${stats.payt}',
                  label: 'PAYT',
                  isWarning: stats.payt > 0,
                ),
              ] else
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.hairline),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({
    required this.value,
    required this.label,
    required this.isWarning,
  });

  final String value;
  final String label;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isWarning ? AppColors.ochre : AppColors.ink1,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 9,
              letterSpacing: 0.8,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions panel ───────────────────────────────────────────────────────

class _QuickActionsPanel extends ConsumerWidget {
  const _QuickActionsPanel({required this.disciplineIds});

  final List<String> disciplineIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get first discipline name for contextual "Mark attendance — X" label
    final firstDisciplineName = disciplineIds.isNotEmpty
        ? ref
                  .watch(disciplineProvider(disciplineIds.first))
                  .asData
                  ?.value
                  ?.name ??
              'session'
        : 'session';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink1,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              color: Color(0x8CF0E8D8),
            ),
          ),
          const SizedBox(height: 10),
          _QuickActionRow(
            label: 'Mark attendance — $firstDisciplineName',
            onTap: () => context.pushNamed('adminAttendanceCreate'),
          ),
          const SizedBox(height: 6),
          _QuickActionRow(
            label: 'Create grading event',
            onTap: () => context.pushNamed('adminGradingCreate'),
          ),
          const SizedBox(height: 6),
          _QuickActionRow(
            label: 'Record PAYT payment',
            onTap: () => context.pushNamed('adminPaymentsRecord'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.paper0),
            ),
            Text(
              '→',
              style: TextStyle(color: AppColors.paper0.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared panel shell ────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper0,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.hairline),
      ),
      child: child,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _lastFour(String s) => s.length > 4 ? s.substring(s.length - 4) : s;

Color _disciplineColor(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('karate')) return AppColors.discKarate;
  if (lower.contains('judo')) return AppColors.discJudo;
  if (lower.contains('jujitsu') || lower.contains('ju-jitsu')) {
    return AppColors.discJujitsu;
  }
  if (lower.contains('aikido')) return AppColors.discAikido;
  if (lower.contains('kendo')) return AppColors.discKendo;
  return AppColors.accent;
}
