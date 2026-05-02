import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event.dart';
import '../../../domain/entities/rank.dart';

class DisciplineDetailScreen extends ConsumerWidget {
  const DisciplineDetailScreen({super.key, required this.disciplineId});

  final String disciplineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(disciplineProvider(disciplineId));

    return disciplineAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (discipline) {
        if (discipline == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Discipline not found.')),
          );
        }
        return _DisciplineDetailView(discipline: discipline);
      },
    );
  }
}

class _DisciplineDetailView extends ConsumerStatefulWidget {
  const _DisciplineDetailView({required this.discipline});

  final Discipline discipline;

  @override
  ConsumerState<_DisciplineDetailView> createState() =>
      _DisciplineDetailViewState();
}

class _DisciplineDetailViewState extends ConsumerState<_DisciplineDetailView> {
  bool _reordering = false;

  Future<void> _reorder(List<Rank> ranks, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() => _reordering = true);
    try {
      final reordered = [...ranks];
      final moved = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, moved);
      await ref
          .read(reorderRanksUseCaseProvider)
          .call(widget.discipline.id, reordered.map((r) => r.id).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reorder failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Rank rank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Rank'),
        content: Text(
          'Delete "${rank.name}"? This cannot be undone.\n\n'
          'This will fail if any student currently holds this rank.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(deleteRankUseCaseProvider)
            .call(widget.discipline.id, rank.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ranksAsync = ref.watch(rankListProvider(widget.discipline.id));
    final discipline = widget.discipline;

    return Scaffold(
      appBar: AppBar(
        title: Text(discipline.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit discipline',
            onPressed: () => context.pushNamed(
              'adminDisciplineEdit',
              pathParameters: {'disciplineId': discipline.id},
              extra: discipline,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Discipline info ────────────────────────────────────────
            if (!discipline.isActive)
              _InfoBanner(
                color: AppColors.error,
                icon: Icons.block,
                message: 'This discipline is inactive.',
              ),
            if (discipline.description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  discipline.description!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),

            // ── Rank list header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Rank Ladder',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(drag to reorder)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_reordering) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, indent: 16),

            // ── Rank list ──────────────────────────────────────────────
            ranksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (ranks) {
                if (ranks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.military_tech_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No ranks yet.\nTap + to add the first rank.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // shrinkWrap so the rank list sizes to its content inside
                // the outer SingleChildScrollView
                return ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ranks.length,
                  onReorder: (oldIndex, newIndex) =>
                      _reorder(ranks, oldIndex, newIndex),
                  itemBuilder: (context, i) => _RankTile(
                    key: ValueKey(ranks[i].id),
                    rank: ranks[i],
                    onEdit: () => context.pushNamed(
                      'adminRankEdit',
                      pathParameters: {
                        'disciplineId': discipline.id,
                        'rankId': ranks[i].id,
                      },
                      extra: ranks[i],
                    ),
                    onDelete: () => _confirmDelete(context, ranks[i]),
                  ),
                );
              },
            ),

            // ── Grading Events section ─────────────────────────────────
            _GradingEventsSection(discipline: discipline),

            // ── Enrolled Students section ──────────────────────────────
            _EnrolledStudentsSection(discipline: discipline),

            const SizedBox(height: 96), // space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final ranks = ref.read(rankListProvider(discipline.id)).value ?? [];
          context.pushNamed(
            'adminRankCreate',
            pathParameters: {'disciplineId': discipline.id},
            extra: ranks.length, // next displayOrder
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Rank'),
      ),
    );
  }
}

// ── Rank tile ──────────────────────────────────────────────────────────────

class _RankTile extends StatelessWidget {
  const _RankTile({
    super.key,
    required this.rank,
    required this.onEdit,
    required this.onDelete,
  });

  final Rank rank;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _BeltSwatch(colourHex: rank.colourHex),
      title: Text(
        rank.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          _RankTypeChip(rank.rankType),
          if (rank.monCount != null) ...[
            const SizedBox(width: 6),
            _MonCountBadge(rank.monCount!),
          ],
          if (rank.minAttendanceForGrading != null) ...[
            const SizedBox(width: 6),
            Text(
              '${rank.minAttendanceForGrading} sessions min',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<_RankAction>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (action) {
              if (action == _RankAction.edit) onEdit();
              if (action == _RankAction.delete) onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _RankAction.edit,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: _RankAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          // Drag handle (built into ReorderableListView)
          const Icon(Icons.drag_handle, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

enum _RankAction { edit, delete }

// ── Belt colour swatch ─────────────────────────────────────────────────────

class _BeltSwatch extends StatelessWidget {
  const _BeltSwatch({required this.colourHex});

  final String? colourHex;

  @override
  Widget build(BuildContext context) {
    final colour = _parseHex(colourHex);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colour ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
      child: colour == null
          ? const Icon(
              Icons.format_color_reset,
              size: 16,
              color: AppColors.textSecondary,
            )
          : null,
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length != 6) return null;
    final value = int.tryParse('FF$clean', radix: 16);
    return value != null ? Color(value) : null;
  }
}

// ── Rank-type chip ─────────────────────────────────────────────────────────

class _RankTypeChip extends StatelessWidget {
  const _RankTypeChip(this.type);

  final RankType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _colour(type).withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label(type),
        style: TextStyle(
          color: _colour(type),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _label(RankType t) => switch (t) {
    RankType.kyu => 'Kyu',
    RankType.dan => 'Dan',
    RankType.mon => 'Mon',
    RankType.ungraded => 'Ungraded',
  };

  Color _colour(RankType t) => switch (t) {
    RankType.kyu => AppColors.info,
    RankType.dan => AppColors.primary,
    RankType.mon => AppColors.success,
    RankType.ungraded => AppColors.textSecondary,
  };
}

// ── Mon count badge ────────────────────────────────────────────────────────

class _MonCountBadge extends StatelessWidget {
  const _MonCountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (_) => const Icon(Icons.circle, size: 6, color: AppColors.accent),
      ),
    );
  }
}

// ── Grading Events section ────────────────────────────────────────────────

class _GradingEventsSection extends ConsumerWidget {
  const _GradingEventsSection({required this.discipline});

  final Discipline discipline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(
      gradingEventsForDisciplineProvider(discipline.id),
    );

    final events = eventsAsync.asData?.value ?? <GradingEvent>[];
    final upcoming = events
        .where((e) => e.status == GradingEventStatus.upcoming)
        .toList();
    final past = events
        .where((e) => e.status != GradingEventStatus.upcoming)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Grading Events',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.pushNamed(
                  'adminGradingCreate',
                  extra: discipline.id,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Event'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16),
        if (eventsAsync is AsyncLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              'No grading events yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else ...[
          if (upcoming.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'UPCOMING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            ...upcoming.map((e) => _GradingEventRow(event: e)),
          ],
          if (past.isNotEmpty)
            ExpansionTile(
              title: Text(
                '${past.length} past event${past.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 14),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: EdgeInsets.zero,
              children: past.map((e) => _GradingEventRow(event: e)).toList(),
            ),
        ],
      ],
    );
  }
}

class _GradingEventRow extends StatelessWidget {
  const _GradingEventRow({required this.event});

  final GradingEvent event;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy').format(event.eventDate);
    final (statusLabel, statusColor) = switch (event.status) {
      GradingEventStatus.upcoming => ('Upcoming', AppColors.info),
      GradingEventStatus.completed => ('Completed', AppColors.success),
      GradingEventStatus.cancelled => ('Cancelled', AppColors.textSecondary),
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        event.title ?? dateStr,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: event.title != null
          ? Text(dateStr, style: const TextStyle(fontSize: 12))
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          statusLabel,
          style: TextStyle(
            color: statusColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () => context.pushNamed(
        'adminGradingDetail',
        pathParameters: {'eventId': event.id},
        extra: event,
      ),
    );
  }
}

// ── Enrolled Students section ─────────────────────────────────────────────

class _EnrolledStudentsSection extends ConsumerWidget {
  const _EnrolledStudentsSection({required this.discipline});

  final Discipline discipline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(
      enrollmentsForDisciplineProvider(discipline.id),
    );
    final ranks =
        ref.watch(rankListProvider(discipline.id)).asData?.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Enrolled Students',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.pushNamed(
                  'adminDisciplineBulkEnrol',
                  pathParameters: {'disciplineId': discipline.id},
                ),
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Bulk Enrol via CSV'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16),
        enrollmentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading students: $e'),
          ),
          data: (enrollments) {
            if (enrollments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No students currently enrolled.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return Column(
              children: enrollments
                  .map((e) => _EnrolledStudentRow(enrollment: e, ranks: ranks))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EnrolledStudentRow extends ConsumerWidget {
  const _EnrolledStudentRow({required this.enrollment, required this.ranks});

  final Enrollment enrollment;
  final List<Rank> ranks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(enrollment.studentId));
    final currentRank = ranks
        .where((r) => r.id == enrollment.currentRankId)
        .firstOrNull;

    final studentName = profileAsync.when(
      loading: () => '…',
      error: (_, _) => enrollment.studentId,
      data: (p) => p?.fullName ?? enrollment.studentId,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Belt swatch
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  _parseHex(currentRank?.colourHex) ??
                  AppColors.textSecondary.withAlpha(60),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textSecondary.withAlpha(60),
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  currentRank?.name ?? enrollment.currentRankId,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Since ${DateFormat('d MMM yyyy').format(enrollment.enrollmentDate)}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length != 6) return null;
    final value = int.tryParse('FF$clean', radix: 16);
    return value != null ? Color(value) : null;
  }
}

// ── Info banner ────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
