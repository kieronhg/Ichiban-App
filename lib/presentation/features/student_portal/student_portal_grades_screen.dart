import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/student_portal_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/rank.dart';
import 'student_portal_drawer.dart';

class StudentPortalGradesScreen extends ConsumerWidget {
  const StudentPortalGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(studentPortalEnrollmentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Grades')),
      drawer: const StudentPortalDrawer(),
      body: enrollmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Could not load grades. Please try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        data: (enrollments) {
          final active = enrollments.where((e) => e.isActive).toList();
          if (active.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.military_tech_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No disciplines yet',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will be enrolled in disciplines by the dojo team.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: active.length,
            separatorBuilder: (_, i) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _EnrollmentCard(enrollment: active[i]),
          );
        },
      ),
    );
  }
}

class _EnrollmentCard extends ConsumerWidget {
  const _EnrollmentCard({required this.enrollment});
  final Enrollment enrollment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(
      disciplineProvider(enrollment.disciplineId),
    );
    final ranksAsync = ref.watch(rankListProvider(enrollment.disciplineId));
    final theme = Theme.of(context);

    final disciplineName = disciplineAsync.asData?.value?.name ?? '…';

    Rank? currentRank;
    if (ranksAsync.asData != null && enrollment.currentRankId.isNotEmpty) {
      currentRank = ranksAsync.asData!.value
          .where((r) => r.id == enrollment.currentRankId)
          .firstOrNull;
    }

    final Color beltColour = _parseBeltColour(currentRank?.colourHex);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: beltColour.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_martial_arts_outlined,
                color: beltColour,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disciplineName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentRank != null ? currentRank.name : 'Ungraded',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (currentRank?.colourHex != null)
              Container(
                width: 16,
                height: 32,
                decoration: BoxDecoration(
                  color: beltColour,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _parseBeltColour(String? hex) {
    if (hex == null) return AppColors.textSecondary;
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppColors.textSecondary;
    }
  }
}
