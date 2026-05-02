import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../sign_up_provider.dart';

class SignUpStep6GdprConsent extends ConsumerWidget {
  const SignUpStep6GdprConsent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consented = ref.watch(
      signUpProvider.select((s) => s.dataProcessingConsent),
    );
    final notifier = ref.read(signUpProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'We collect and process your personal data to manage your '
            'membership, communicate with you about classes and events, and '
            'keep our records compliant with applicable law.\n\n'
            'Your data will not be sold to third parties. You may request '
            'access to your data or ask for it to be deleted at any time by '
            'contacting the dojo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => notifier.setDataProcessingConsent(!consented),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: consented
                  ? AppColors.primary.withAlpha(12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: consented ? AppColors.primary : AppColors.surfaceVariant,
                width: consented ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: consented,
                  onChanged: (v) =>
                      notifier.setDataProcessingConsent(v ?? false),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'I agree to my personal data being processed as described above.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
