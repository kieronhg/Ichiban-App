import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/student_auth_provider.dart';
import '../../../core/providers/student_portal_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';

class StudentPortalDrawer extends ConsumerWidget {
  const StudentPortalDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentStudentProfileProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isParent = profile?.isParentGuardian ?? false;

    void go(String route) {
      Navigator.of(context).pop();
      context.go(route);
    }

    final initials = _initials(profile?.firstName, profile?.lastName);
    final displayName = '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'
        .trim();
    final roleLabel = _roleLabel(profile);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName.isNotEmpty ? displayName : 'Student',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    route: RouteNames.studentPortalHome,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.studentPortalHome),
                  ),
                  _NavItem(
                    icon: Icons.military_tech_outlined,
                    label: 'Grades',
                    route: RouteNames.studentPortalGrades,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.studentPortalGrades),
                  ),
                  _NavItem(
                    icon: Icons.card_membership_outlined,
                    label: 'Membership',
                    route: RouteNames.studentPortalMembership,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.studentPortalMembership),
                  ),
                  _NavItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Schedule',
                    route: RouteNames.studentPortalSchedule,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.studentPortalSchedule),
                  ),
                  _NavItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    route: RouteNames.studentPortalNotifications,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.studentPortalNotifications),
                    badgeCount: ref.watch(unreadNotificationsCountProvider),
                  ),
                  if (isParent)
                    _NavItem(
                      icon: Icons.family_restroom_outlined,
                      label: 'Family',
                      route: RouteNames.studentPortalFamily,
                      currentLocation: currentLocation,
                      onTap: () => go(RouteNames.studentPortalFamily),
                    ),
                  const Divider(height: 24),
                  _NavItem(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Account',
                    route: RouteNames.studentPortalAccount,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.studentPortalAccount),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_outlined,
                color: AppColors.error,
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                ref.read(studentAuthProvider.notifier).signOut();
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go(RouteNames.entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? first, String? last) {
    final f = (first ?? '').isNotEmpty ? first![0].toUpperCase() : '';
    final l = (last ?? '').isNotEmpty ? last![0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }

  String _roleLabel(dynamic profile) {
    if (profile == null) return 'Student';
    if (profile.isParentGuardian) return 'Parent / Guardian';
    if (profile.isJunior) return 'Junior Student';
    return 'Student';
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentLocation,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentLocation;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final isActive = currentLocation == route;
    return ListTile(
      leading: badgeCount > 0
          ? Badge(
              label: Text('$badgeCount'),
              child: Icon(
                icon,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
              ),
            )
          : Icon(
              icon,
              color: isActive ? AppColors.accent : AppColors.textSecondary,
            ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? AppColors.accent : null,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive
          ? AppColors.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}
