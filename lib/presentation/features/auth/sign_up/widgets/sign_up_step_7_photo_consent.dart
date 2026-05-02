import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../sign_up_provider.dart';

class SignUpStep7PhotoConsent extends ConsumerWidget {
  const SignUpStep7PhotoConsent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consented = ref.watch(
      signUpProvider.select((s) => s.photoVideoConsent),
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
            'We occasionally take photos and videos at training sessions and '
            'events for use on our website and social media channels.\n\n'
            'You can change this preference at any time by contacting the dojo '
            'or updating your profile in the app.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => notifier.setPhotoVideoConsent(!consented),
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
                  onChanged: (v) => notifier.setPhotoVideoConsent(v ?? false),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'I consent to photos and videos being taken and used for '
                    'dojo promotional purposes.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This is optional — you can still register without consenting.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
