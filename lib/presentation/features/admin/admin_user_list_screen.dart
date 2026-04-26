import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/admin_session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_user.dart';
import '../../../domain/entities/enums.dart';

class AdminUserListScreen extends ConsumerWidget {
  const AdminUserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(adminUserListProvider);
    final isOwner = ref.watch(isOwnerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Team')),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed('adminTeamInvite'),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Invite Coach'),
            )
          : null,
      body: adminsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (admins) {
          if (admins.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No team members yet.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Owners first, then coaches — alphabetical within each group.
          final sorted = [...admins]
            ..sort((a, b) {
              if (a.role != b.role) {
                return a.isOwner ? -1 : 1;
              }
              return a.lastName.compareTo(b.lastName);
            });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            separatorBuilder: (context, _) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _AdminTile(
              admin: sorted[i],
              onTap: () => context.pushNamed(
                'adminTeamDetail',
                pathParameters: {'uid': sorted[i].firebaseUid},
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── List tile ──────────────────────────────────────────────────────────────

class _AdminTile extends StatelessWidget {
  const _AdminTile({required this.admin, required this.onTap});

  final AdminUser admin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: admin.isActive
            ? AppColors.primary
            : AppColors.surfaceVariant,
        child: Text(
          '${admin.firstName[0]}${admin.lastName[0]}',
          style: TextStyle(
            color: admin.isActive
                ? AppColors.textOnPrimary
                : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            admin.fullName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: admin.isActive ? null : AppColors.textSecondary,
              decoration: admin.isActive ? null : TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
          _RoleBadge(role: admin.role),
        ],
      ),
      subtitle: Text(
        admin.isActive ? admin.email : '${admin.email}  •  Deactivated',
        style: TextStyle(
          color: admin.isActive
              ? AppColors.textSecondary
              : AppColors.error.withAlpha(180),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final AdminRole role;

  @override
  Widget build(BuildContext context) {
    final isOwner = role == AdminRole.owner;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOwner
            ? AppColors.accent.withAlpha(26)
            : AppColors.info.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOwner
              ? AppColors.accent.withAlpha(77)
              : AppColors.info.withAlpha(77),
        ),
      ),
      child: Text(
        isOwner ? 'Owner' : 'Coach',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOwner ? AppColors.accent : AppColors.info,
        ),
      ),
    );
  }
}
