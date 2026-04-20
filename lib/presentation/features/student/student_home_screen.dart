import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/student_session_provider.dart';

/// Landing screen shown to a student after PIN authentication.
///
/// Displays a welcome card and a "Check In" button. Signing out clears
/// the student session and returns to the profile-select screen.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(studentSessionProvider);
    final profileAsync = session.profileId != null
        ? ref.watch(profileProvider(session.profileId!))
        : null;

    final firstName = profileAsync?.asData?.value?.firstName ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Student Portal'),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(studentSessionProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout_outlined, size: 18),
            label: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Welcome card ────────────────────────────────────────
              Card(
                elevation: 0,
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.sports_martial_arts,
                          color: AppColors.textOnPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hi, $firstName 👋',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to train today?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Check In button ─────────────────────────────────────
              FilledButton.icon(
                onPressed: () => context.pushNamed('studentCheckin'),
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: const Text('Check In to a Class'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
