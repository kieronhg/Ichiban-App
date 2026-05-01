import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dashboard/admin_drawer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../domain/entities/discipline.dart';

class DisciplineListScreen extends ConsumerWidget {
  const DisciplineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplinesAsync = ref.watch(disciplineListProvider);

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const Text('Disciplines')),
      body: disciplinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (disciplines) {
          if (disciplines.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_martial_arts_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No disciplines yet.\nTap + to add the first one.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Active first, then inactive — stable alphabetical within each group
          final sorted = [...disciplines]
            ..sort((a, b) {
              if (a.isActive != b.isActive) {
                return a.isActive ? -1 : 1;
              }
              return a.name.compareTo(b.name);
            });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, i) => _DisciplineTile(
              discipline: sorted[i],
              onTap: () => context.pushNamed(
                'adminDisciplineDetail',
                pathParameters: {'disciplineId': sorted[i].id},
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('adminDisciplineCreate'),
        icon: const Icon(Icons.add),
        label: const Text('New Discipline'),
      ),
    );
  }
}

class _DisciplineTile extends StatelessWidget {
  const _DisciplineTile({required this.discipline, required this.onTap});

  final Discipline discipline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: discipline.isActive
            ? AppColors.primary
            : AppColors.surfaceVariant,
        child: Text(
          discipline.name[0],
          style: TextStyle(
            color: discipline.isActive
                ? AppColors.textOnPrimary
                : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        discipline.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: discipline.isActive
              ? AppColors.textPrimary
              : AppColors.textSecondary,
        ),
      ),
      subtitle: discipline.description != null
          ? Text(
              discipline.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!discipline.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Inactive',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }
}
