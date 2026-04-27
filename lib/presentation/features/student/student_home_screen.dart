import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/student_session_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';

/// Landing screen shown to a student after PIN authentication.
///
/// Wraps the entire body in a [GestureDetector] so any tap or drag resets
/// the inactivity-timeout clock. When the [StudentSessionNotifier] timer fires
/// and sets [isAuthenticated] to false, the router redirect automatically
/// sends the student back to the select screen — no explicit navigation needed.
class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  void _updateActivity() =>
      ref.read(studentSessionProvider.notifier).updateActivity();

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studentSessionProvider);
    final profileAsync = session.profileId != null
        ? ref.watch(profileProvider(session.profileId!))
        : null;

    final firstName = profileAsync?.asData?.value?.firstName ?? 'Student';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _updateActivity,
      onPanDown: (_) => _updateActivity(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Student Portal'),
          actions: [
            if (session.profileId != null)
              _StudentBellButton(profileId: session.profileId!),
            TextButton.icon(
              onPressed: () {
                ref.read(studentSessionProvider.notifier).signOut();
                context.go(RouteNames.entry);
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
                // ── Welcome card ──────────────────────────────────────
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
                          child: const Icon(
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

                // ── Check In button ───────────────────────────────────
                FilledButton.icon(
                  onPressed: () {
                    _updateActivity();
                    context.pushNamed('studentCheckin');
                  },
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

                const SizedBox(height: 12),

                // ── My Grades button ──────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () {
                    _updateActivity();
                    context.pushNamed('studentGrades');
                  },
                  icon: const Icon(Icons.military_tech_outlined, size: 22),
                  label: const Text('My Grades'),
                  style: OutlinedButton.styleFrom(
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
      ),
    );
  }
}

// ── Bell button for student AppBar ─────────────────────────────────────────

class _StudentBellButton extends ConsumerWidget {
  const _StudentBellButton({required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications =
        ref.watch(studentNotificationsProvider(profileId)).asData?.value ?? [];
    final unread = notifications.where((n) => n.isRead != true).length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => context.pushNamed('studentNotifications'),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
