import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../dashboard/admin_drawer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event.dart';

class GradingListScreen extends ConsumerStatefulWidget {
  const GradingListScreen({super.key, this.preFilterDisciplineId});

  /// When non-null, the list is pre-filtered to show only this discipline's events.
  final String? preFilterDisciplineId;

  @override
  ConsumerState<GradingListScreen> createState() => _GradingListScreenState();
}

class _GradingListScreenState extends ConsumerState<GradingListScreen> {
  GradingEventStatus? _statusFilter; // null = all
  late String? _disciplineFilter;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _disciplineFilter = widget.preFilterDisciplineId;
  }

  /// For coaches, lock the filter to their first assigned discipline on first
  /// build so they never see events from other disciplines.
  void _initFilter(bool isOwner, List<String> assignedIds) {
    if (_initialized || widget.preFilterDisciplineId != null) {
      _initialized = true;
      return;
    }
    _initialized = true;
    if (!isOwner && assignedIds.isNotEmpty) {
      _disciplineFilter = assignedIds.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = ref.watch(isOwnerProvider);
    final assignedIds = ref.watch(assignedDisciplineIdsProvider);
    _initFilter(isOwner, assignedIds);

    final eventsAsync = _disciplineFilter != null
        ? ref.watch(gradingEventsForDisciplineProvider(_disciplineFilter!))
        : ref.watch(gradingEventListProvider);
    final accessibleAsync = ref.watch(accessibleDisciplineListProvider);

    final disciplineMap = {
      for (final d in accessibleAsync.asData?.value ?? <dynamic>[])
        d.id as String: d.name as String,
    };

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const Text('Grading Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.adminGradingCreate),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
      body: Column(
        children: [
          // ── Discipline filter ──────────────────────────────────────────
          accessibleAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (disciplines) {
              // Only show the filter dropdown when there are multiple
              // disciplines to choose from, or the user is an owner.
              if (!isOwner && disciplines.length <= 1) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: DropdownButtonFormField<String?>(
                  key: ValueKey(_disciplineFilter),
                  initialValue: _disciplineFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Discipline',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    if (isOwner)
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Disciplines'),
                      ),
                    ...disciplines.map(
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _disciplineFilter = v),
                ),
              );
            },
          ),
          // ── Status filter chips ─────────────────────────────────────────
          _StatusFilterBar(
            selected: _statusFilter,
            onChanged: (s) => setState(() => _statusFilter = s),
          ),
          // ── Event list ──────────────────────────────────────────────────
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (events) {
                final filtered = _statusFilter == null
                    ? events
                    : events.where((e) => e.status == _statusFilter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_martial_arts,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusFilter == null
                              ? 'No grading events yet'
                              : 'No ${_statusFilter!.name} events',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final event = filtered[i];
                    return _GradingEventTile(
                      event: event,
                      disciplineName: disciplineMap[event.disciplineId] ?? '—',
                      onTap: () => context.pushNamed(
                        RouteNames.adminGradingDetail,
                        pathParameters: {'eventId': event.id},
                        extra: event,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status filter bar ──────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onChanged});

  final GradingEventStatus? selected;
  final ValueChanged<GradingEventStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Upcoming',
            selected: selected == GradingEventStatus.upcoming,
            onTap: () => onChanged(GradingEventStatus.upcoming),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Completed',
            selected: selected == GradingEventStatus.completed,
            onTap: () => onChanged(GradingEventStatus.completed),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Cancelled',
            selected: selected == GradingEventStatus.cancelled,
            onTap: () => onChanged(GradingEventStatus.cancelled),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textOnAccent : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Event tile ─────────────────────────────────────────────────────────────

class _GradingEventTile extends StatelessWidget {
  const _GradingEventTile({
    required this.event,
    required this.disciplineName,
    required this.onTap,
  });

  final GradingEvent event;
  final String disciplineName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE d MMM yyyy').format(event.eventDate);
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title ?? disciplineName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (event.title != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          disciplineName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(status: event.status),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
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
