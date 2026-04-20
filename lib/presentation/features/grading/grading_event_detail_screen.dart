import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event.dart';
import '../../../domain/entities/grading_event_student.dart';

class GradingEventDetailScreen extends ConsumerWidget {
  const GradingEventDetailScreen({super.key, required this.event});

  final GradingEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(gradingEventStudentsProvider(event.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title ?? 'Grading Event'),
        actions: [
          if (event.status == GradingEventStatus.upcoming)
            PopupMenuButton<_Action>(
              onSelected: (action) => _handleAction(context, ref, action),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _Action.complete,
                  child: Text('Mark as Complete'),
                ),
                PopupMenuItem(
                  value: _Action.cancel,
                  child: Text('Cancel Event'),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Event info card ───────────────────────────────────────────
          _EventInfoCard(event: event),
          const SizedBox(height: 16),

          // ── Students section ──────────────────────────────────────────
          studentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (students) =>
                _StudentsSection(event: event, students: students),
          ),
        ],
      ),
      // Nominate students FAB (upcoming only)
      floatingActionButton: event.status == GradingEventStatus.upcoming
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed(
                RouteNames.adminGradingNominate,
                pathParameters: {'eventId': event.id},
                extra: event,
              ),
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textOnAccent,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Nominate Students'),
            )
          : null,
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _Action action,
  ) async {
    final adminId = ref.read(currentAdminIdProvider) ?? '';

    if (action == _Action.complete) {
      final confirmed = await _confirm(
        context,
        title: 'Mark as Complete?',
        message:
            'This will close the event. Make sure all results have been recorded.',
        confirmLabel: 'Complete',
      );
      if (confirmed != true) return;
      try {
        await ref.read(completeGradingEventUseCaseProvider).call(event.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event marked as complete.')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    if (!context.mounted) return;
    if (action == _Action.cancel) {
      final confirmed = await _confirm(
        context,
        title: 'Cancel Event?',
        message:
            'This event will be marked as cancelled. This cannot be undone.',
        confirmLabel: 'Cancel Event',
        isDestructive: true,
      );
      if (confirmed != true) return;
      try {
        await ref
            .read(cancelGradingEventUseCaseProvider)
            .call(gradingEventId: event.id, adminId: adminId);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Event cancelled.')));
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive
                  ? AppColors.error
                  : AppColors.accent,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

enum _Action { complete, cancel }

// ── Event info card ────────────────────────────────────────────────────────

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({required this.event});

  final GradingEvent event;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(event.eventDate);
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StatusBadge(status: event.status),
              ],
            ),
            if (event.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                event.notes!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Students section ───────────────────────────────────────────────────────

class _StudentsSection extends StatelessWidget {
  const _StudentsSection({required this.event, required this.students});

  final GradingEvent event;
  final List<GradingEventStudent> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No students nominated yet.\nTap "Nominate Students" to add them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '${students.length} Student${students.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...students.map((s) => _StudentTile(eventStudent: s, event: event)),
        const SizedBox(height: 80), // FAB clearance
      ],
    );
  }
}

class _StudentTile extends ConsumerWidget {
  const _StudentTile({required this.eventStudent, required this.event});

  final GradingEventStudent eventStudent;
  final GradingEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(eventStudent.studentId));
    final profile = profileAsync.asData?.value;
    final name = profile != null
        ? '${profile.firstName} ${profile.lastName}'
        : 'Loading…';

    final canRecord =
        event.status == GradingEventStatus.upcoming &&
        eventStudent.outcome == null;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canRecord
            ? () => context.pushNamed(
                RouteNames.adminGradingRecordResults,
                pathParameters: {'eventId': event.id},
                extra: (event, eventStudent),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (eventStudent.gradingScore != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Score: ${eventStudent.gradingScore!.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (eventStudent.outcome != null)
                _OutcomeBadge(outcome: eventStudent.outcome!)
              else if (canRecord)
                const Row(
                  children: [
                    Text(
                      'Record result',
                      style: TextStyle(color: AppColors.accent, fontSize: 13),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ],
                )
              else
                const Text(
                  'Pending',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Outcome badge ──────────────────────────────────────────────────────────

class _OutcomeBadge extends StatelessWidget {
  const _OutcomeBadge({required this.outcome});

  final GradingOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (outcome) {
      GradingOutcome.promoted => ('Promoted', AppColors.success),
      GradingOutcome.failed => ('Not promoted', AppColors.error),
      GradingOutcome.absent => ('Absent', AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final GradingEventStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GradingEventStatus.upcoming => ('Upcoming', AppColors.info),
      GradingEventStatus.completed => ('Completed', AppColors.success),
      GradingEventStatus.cancelled => ('Cancelled', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
