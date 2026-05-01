import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'student_nav_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../core/providers/student_session_provider.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/grading_record.dart';
import '../../../domain/entities/rank.dart';

/// Student-facing screen showing current ranks and promotion history
/// across all enrolled disciplines.
class StudentGradesScreen extends ConsumerWidget {
  const StudentGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(studentSessionProvider);
    final studentId = session.profileId ?? '';

    final enrollmentsAsync = ref.watch(
      allEnrollmentsForStudentProvider(studentId),
    );
    final gradingRecordsAsync = ref.watch(
      gradingRecordsForStudentProvider(studentId),
    );

    return Scaffold(
      bottomNavigationBar: const StudentNavBar(currentIndex: 2),
      appBar: AppBar(title: const Text('My Grades')),
      body: enrollmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (enrollments) {
          final active = enrollments.where((e) => e.isActive).toList();
          final records =
              gradingRecordsAsync.asData?.value ?? <GradingRecord>[];

          if (active.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.military_tech_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You are not enrolled in any disciplines yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group records by discipline
          final byDiscipline = <String, List<GradingRecord>>{};
          for (final r in records) {
            byDiscipline.putIfAbsent(r.disciplineId, () => []).add(r);
          }
          for (final list in byDiscipline.values) {
            list.sort((a, b) => b.gradingDate.compareTo(a.gradingDate));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: active.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final enrollment = active[i];
              final disciplineRecords =
                  byDiscipline[enrollment.disciplineId] ?? [];
              return _DisciplineGradeCard(
                enrollment: enrollment,
                records: disciplineRecords,
              );
            },
          );
        },
      ),
    );
  }
}

// ── Discipline grade card ──────────────────────────────────────────────────

class _DisciplineGradeCard extends ConsumerWidget {
  const _DisciplineGradeCard({required this.enrollment, required this.records});

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Promotion history ──────────────────────────────────────────
          if (records.isNotEmpty) ...[
            const Divider(height: 1),
            _PromotionHistory(records: records, ranks: ranks),
          ] else ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                'No promotions yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PromotionHistory extends StatelessWidget {
  const _PromotionHistory({required this.records, required this.ranks});

  final List<GradingRecord> records;
  final List<Rank> ranks;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        '${records.length} promotion${records.length == 1 ? '' : 's'}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: records.length <= 3,
      children: records.map((r) {
        final toRank = ranks
            .where((rk) => rk.id == r.rankAchievedId)
            .firstOrNull;
        final dateStr = DateFormat('d MMM yyyy').format(r.gradingDate);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 14,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toRank?.name ?? r.rankAchievedId,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (r.gradingScore != null)
                      Text(
                        'Score: ${r.gradingScore!.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Belt icon ──────────────────────────────────────────────────────────────

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
