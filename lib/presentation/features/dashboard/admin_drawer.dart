import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(isOwnerProvider);
    final adminUser = ref.watch(currentAdminUserProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    void go(String route) {
      Navigator.of(context).pop();
      context.go(route);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      _initials(adminUser?.firstName, adminUser?.lastName),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${adminUser?.firstName ?? ''} ${adminUser?.lastName ?? ''}'
                        .trim(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    isOwner ? 'Owner' : 'Coach',
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
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: RouteNames.adminDashboard,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.adminDashboard),
                  ),
                  if (isOwner)
                    _NavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: RouteNames.adminProfiles,
                      currentLocation: currentLocation,
                      onTap: () => go(RouteNames.adminProfiles),
                    ),
                  if (isOwner)
                    _NavItem(
                      icon: Icons.sports_martial_arts_outlined,
                      label: 'Disciplines',
                      route: RouteNames.adminDisciplines,
                      currentLocation: currentLocation,
                      onTap: () => go(RouteNames.adminDisciplines),
                    ),
                  _NavItem(
                    icon: Icons.fitness_center_outlined,
                    label: 'Attendance',
                    route: RouteNames.adminAttendance,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.adminAttendance),
                  ),
                  if (isOwner)
                    _NavItem(
                      icon: Icons.card_membership_outlined,
                      label: 'Memberships',
                      route: RouteNames.adminMemberships,
                      currentLocation: currentLocation,
                      onTap: () => go(RouteNames.adminMemberships),
                    ),
                  _NavItem(
                    icon: Icons.payments_outlined,
                    label: 'Payments',
                    route: RouteNames.adminPayments,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.adminPayments),
                  ),
                  _NavItem(
                    icon: Icons.military_tech_outlined,
                    label: 'Grading',
                    route: RouteNames.adminGrading,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.adminGrading),
                  ),
                  _NavItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    route: RouteNames.adminNotifications,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.adminNotifications),
                  ),
                  if (!isOwner)
                    _NavItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'My Profile',
                      route: RouteNames.adminMyProfile,
                      currentLocation: currentLocation,
                      onTap: () => go(RouteNames.adminMyProfile),
                    ),
                  const Divider(height: 24),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    route: RouteNames.adminSettings,
                    currentLocation: currentLocation,
                    onTap: () => go(RouteNames.adminSettings),
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
                await ref.read(signOutProvider)();
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
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentLocation,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentLocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive =
        currentLocation == route ||
        (route != RouteNames.adminDashboard &&
            currentLocation.startsWith(route));
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? AppColors.primary : null,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}
