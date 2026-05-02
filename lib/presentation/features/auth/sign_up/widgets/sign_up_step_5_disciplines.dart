import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/discipline_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../sign_up_provider.dart';

class SignUpStep5Disciplines extends ConsumerWidget {
  const SignUpStep5Disciplines({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplinesAsync = ref.watch(activeDisciplineListProvider);
    final selectedIds = ref.watch(signUpProvider).selectedDisciplineIds;
    final notifier = ref.read(signUpProvider.notifier);
    final theme = Theme.of(context);

    return disciplinesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          'Could not load disciplines. Please check your connection.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      data: (disciplines) {
        if (disciplines.isEmpty) {
          return Center(
            child: Text(
              'No disciplines are currently available. Please contact the dojo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: disciplines.map((d) {
            final selected = selectedIds.contains(d.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => notifier.toggleDiscipline(d.id),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withAlpha(15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: AppColors.primary)
                      else
                        const Icon(
                          Icons.circle_outlined,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
