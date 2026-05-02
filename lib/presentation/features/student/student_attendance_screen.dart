import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'student_nav_bar.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/student_session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/entities/enums.dart';

class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = ref.watch(studentSessionProvider).profileId ?? '';
    final recordsAsync = ref.watch(
      attendanceHistoryForStudentProvider(studentId),
    );

    return Scaffold(
      bottomNavigationBar: const StudentNavBar(currentIndex: 1),
      appBar: AppBar(title: const Text('My Attendance')),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No attendance records yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          final sorted = [...records]
            ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

          final grouped = _groupByDate(sorted);
          final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: dates.length,
            itemBuilder: (context, i) {
              final date = dates[i];
              return _DayGroup(date: date, records: grouped[date]!);
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<AttendanceRecord>> _groupByDate(
    List<AttendanceRecord> records,
  ) {
    final map = <DateTime, List<AttendanceRecord>>{};
    for (final r in records) {
      final day = DateTime.utc(
        r.sessionDate.year,
        r.sessionDate.month,
        r.sessionDate.day,
      );
      map.putIfAbsent(day, () => []).add(r);
    }
    return map;
  }
}

// ── Day group ─────────────────────────────────────────────────────────────────

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.date, required this.records});

  final DateTime date;
  final List<AttendanceRecord> records;

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
        ...records.map((r) => _RecordTile(record: r)),
      ],
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

// ── Record tile ───────────────────────────────────────────────────────────────

class _RecordTile extends ConsumerWidget {
  const _RecordTile({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(disciplineProvider(record.disciplineId));
    final disciplineName =
        disciplineAsync.asData?.value?.name ?? record.disciplineId;
    final isSelf = record.checkInMethod == CheckInMethod.self;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.surfaceVariant),
      ),
      child: ListTile(
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
        trailing: Chip(
          avatar: Icon(
            isSelf ? Icons.person_outline : Icons.sports_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
          label: Text(
            isSelf ? 'Self' : 'Coach',
            style: const TextStyle(fontSize: 12),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
