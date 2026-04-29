import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(isOwnerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (isOwner) ...[
            _SettingsTile(
              icon: Icons.business_outlined,
              title: 'General',
              subtitle: 'Dojo name, email, privacy policy',
              onTap: () => context.pushNamed('adminSettingsGeneral'),
            ),
            _SettingsTile(
              icon: Icons.payments_outlined,
              title: 'Membership & Pricing',
              subtitle: 'Monthly, annual, family, PAYT rates',
              onTap: () => context.pushNamed('adminSettingsPricing'),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notification Timings',
              subtitle: 'Renewal reminders, DBS alerts, trial expiry',
              onTap: () => context.pushNamed('adminSettingsNotifications'),
            ),
            _SettingsTile(
              icon: Icons.security_outlined,
              title: 'GDPR & Data',
              subtitle: 'Data retention, anonymisation, bulk export',
              onTap: () => context.pushNamed('adminSettingsGdpr'),
            ),
            _SettingsTile(
              icon: Icons.email_outlined,
              title: 'Email Templates',
              subtitle: 'View and edit notification email templates',
              onTap: () => context.pushNamed('adminSettingsEmailTemplates'),
            ),
          ],
          _SettingsTile(
            icon: Icons.group_outlined,
            title: 'Manage Team',
            subtitle: isOwner
                ? 'Coach accounts, roles and disciplines'
                : 'View your account details',
            onTap: () => context.pushNamed('adminTeam'),
          ),
          if (isOwner) ...[
            _SettingsTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Setup Wizard',
              subtitle: 'Re-run initial dojo configuration',
              onTap: () => context.go(RouteNames.adminSetup),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Danger Zone',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _SettingsTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Danger Zone',
              subtitle: 'Clear notification logs',
              iconColor: AppColors.error,
              onTap: () => context.pushNamed('adminSettingsDangerZone'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
