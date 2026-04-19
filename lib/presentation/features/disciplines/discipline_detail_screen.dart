import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/rank.dart';

class DisciplineDetailScreen extends ConsumerWidget {
  const DisciplineDetailScreen({super.key, required this.disciplineId});

  final String disciplineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(disciplineProvider(disciplineId));

    return disciplineAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
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

class _DisciplineDetailViewState
    extends ConsumerState<_DisciplineDetailView> {
  bool _reordering = false;

  Future<void> _reorder(List<Rank> ranks, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() => _reordering = true);
    try {
      final reordered = [...ranks];
      final moved = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, moved);
      await ref.read(reorderRanksUseCaseProvider).call(
            widget.discipline.id,
            reordered.map((r) => r.id).toList(),
          );
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

  Future<void> _confirmDelete(
      BuildContext context, Rank rank) async {
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
    final ranksAsync =
        ref.watch(rankListProvider(widget.discipline.id));
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Discipline info ──────────────────────────────────────────
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
                    color: AppColors.textSecondary, fontSize: 14),
              ),
            ),

          // ── Rank list header ─────────────────────────────────────────
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
                      fontSize: 12, color: AppColors.textSecondary),
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

          // ── Rank list ────────────────────────────────────────────────
          Expanded(
            child: ranksAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (ranks) {
                if (ranks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.military_tech_outlined,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'No ranks yet.\nTap + to add the first rank.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
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
          ),
        ],
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
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                  title: Text('Delete', style: TextStyle(color: AppColors.error)),
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
          ? const Icon(Icons.format_color_reset,
              size: 16, color: AppColors.textSecondary)
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
          Text(message,
              style:
                  TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
