import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../domain/entities/attendance_session.dart';

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  ConsumerState<AttendanceListScreen> createState() =>
      _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen> {
  String? _selectedDisciplineId; // null = all disciplines (owners only)
  bool _initialized = false;

  /// For coaches, lock the filter to their first assigned discipline on first
  /// build, so they never accidentally see sessions from other disciplines.
  void _initFilter(bool isOwner, List<String> assignedIds) {
    if (_initialized) return;
    _initialized = true;
    if (!isOwner && assignedIds.isNotEmpty) {
      _selectedDisciplineId = assignedIds.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = ref.watch(isOwnerProvider);
    final assignedIds = ref.watch(assignedDisciplineIdsProvider);
    _initFilter(isOwner, assignedIds);

    final sessionsAsync = ref.watch(
      attendanceSessionListProvider(_selectedDisciplineId),
    );
    final disciplinesAsync = ref.watch(accessibleDisciplineListProvider);
    final pendingQueueAsync = ref.watch(pendingQueuedCheckInsProvider);
    final pendingCount = pendingQueueAsync.asData?.value.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => context.pushNamed('adminAttendanceQueued'),
                icon: Badge(
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.people_outline),
                ),
                label: const Text('Queued'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Discipline filter ──────────────────────────────────────────
          disciplinesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (disciplines) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DropdownButtonFormField<String?>(
                // Keep the widget in sync when the filter is initialised
                // programmatically (e.g. after the coach's disciplines load).
                key: ValueKey(_selectedDisciplineId),
                initialValue: _selectedDisciplineId,
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
                  // "All" is only available to owners.
                  if (isOwner)
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Disciplines'),
                    ),
                  ...disciplines.map(
                    (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedDisciplineId = v),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Session list ───────────────────────────────────────────────
          Expanded(
            child: sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 56,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No sessions yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to create one.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Build discipline name lookup from the cached stream
                final disciplineNames = <String, String>{
                  for (final d in disciplinesAsync.asData?.value ?? [])
                    d.id: d.name,
                };

                // Group sessions by date
                final grouped = _groupByDate(sessions);
                final dates = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: dates.length,
                  itemBuilder: (context, i) {
                    final date = dates[i];
                    final daySessions = grouped[date]!;
                    return _DayGroup(
                      date: date,
                      sessions: daySessions,
                      disciplineNames: disciplineNames,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('adminAttendanceCreate'),
        icon: const Icon(Icons.add),
        label: const Text('Create Session'),
      ),
    );
  }

  Map<DateTime, List<AttendanceSession>> _groupByDate(
    List<AttendanceSession> sessions,
  ) {
    final map = <DateTime, List<AttendanceSession>>{};
    for (final s in sessions) {
      final day = DateTime.utc(
        s.sessionDate.year,
        s.sessionDate.month,
        s.sessionDate.day,
      );
      map.putIfAbsent(day, () => []).add(s);
    }
    return map;
  }
}

// ── Day group ────────────────────────────────────────────────────────────────

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.date,
    required this.sessions,
    required this.disciplineNames,
  });

  final DateTime date;
  final List<AttendanceSession> sessions;
  final Map<String, String> disciplineNames;

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(date);
    final label = isToday
        ? 'Today — ${DateFormat('d MMM yyyy').format(date)}'
        : DateFormat('EEEE, d MMM yyyy').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isToday ? AppColors.accent : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...sessions.map(
          (s) => _SessionTile(
            session: s,
            disciplineName: disciplineNames[s.disciplineId] ?? s.disciplineId,
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

// ── Session tile ─────────────────────────────────────────────────────────────

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session, required this.disciplineName});

  final AttendanceSession session;
  final String disciplineName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(
      attendanceRecordsForSessionProvider(session.id),
    );
    final recordCount = recordsAsync.asData?.value.length ?? 0;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.surfaceVariant),
      ),
      child: ListTile(
        onTap: () => context.pushNamed(
          'adminAttendanceDetail',
          pathParameters: {'sessionId': session.id},
          extra: session,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(
            Icons.sports_martial_arts,
            color: AppColors.textOnPrimary,
            size: 20,
          ),
        ),
        title: Text(
          disciplineName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          session.startTime.isNotEmpty
              ? '${session.startTime} – ${session.endTime}'
              : 'No time set',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: Chip(
          label: Text(
            '$recordCount present',
            style: const TextStyle(fontSize: 12),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
