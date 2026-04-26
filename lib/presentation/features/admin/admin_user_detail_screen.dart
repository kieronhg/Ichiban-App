import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_user.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/enums.dart';

class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(adminUserProvider(uid));
    final currentAdmin = ref.watch(currentAdminUserProvider);
    final isOwner = ref.watch(isOwnerProvider);

    return Scaffold(
      appBar: AppBar(
        title: adminAsync.asData?.value != null
            ? Text(adminAsync.asData!.value!.fullName)
            : const Text('Team Member'),
        actions: [
          if (isOwner)
            adminAsync.asData?.value != null
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: () => context.pushNamed(
                      'adminTeamEdit',
                      pathParameters: {'uid': uid},
                      extra: adminAsync.asData!.value!,
                    ),
                  )
                : const SizedBox.shrink(),
        ],
      ),
      body: adminAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (admin) {
          if (admin == null) {
            return const Center(child: Text('Admin user not found.'));
          }
          final isSelf = currentAdmin?.firebaseUid == admin.firebaseUid;
          return _DetailBody(
            admin: admin,
            currentAdmin: currentAdmin,
            isOwner: isOwner,
            isSelf: isSelf,
          );
        },
      ),
    );
  }
}

// ── Detail body ────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.admin,
    required this.currentAdmin,
    required this.isOwner,
    required this.isSelf,
  });

  final AdminUser admin;
  final AdminUser? currentAdmin;
  final bool isOwner;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplinesAsync = ref.watch(disciplineListProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Profile card ───────────────────────────────────────────────
        _ProfileCard(admin: admin),
        const SizedBox(height: 20),

        // ── Info rows ──────────────────────────────────────────────────
        _InfoRow(label: 'Email', value: admin.email),
        _InfoRow(
          label: 'Status',
          value: admin.isActive ? 'Active' : 'Deactivated',
          valueColor: admin.isActive ? AppColors.success : AppColors.error,
        ),
        if (admin.lastLoginAt != null)
          _InfoRow(label: 'Last login', value: _formatDate(admin.lastLoginAt!)),
        _InfoRow(label: 'Member since', value: _formatDate(admin.createdAt)),

        // ── Disciplines (coaches only) ─────────────────────────────────
        if (admin.isCoach && admin.assignedDisciplineIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          disciplinesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (disciplines) {
              final assigned = disciplines
                  .where((d) => admin.assignedDisciplineIds.contains(d.id))
                  .toList();
              if (assigned.isEmpty) return const SizedBox.shrink();
              return _InfoRow(
                label: 'Disciplines',
                value: assigned.map((d) => d.name).join(', '),
              );
            },
          ),
        ],

        // ── Owner-only actions (cannot act on yourself) ────────────────
        if (isOwner && !isSelf) ...[
          const SizedBox(height: 28),
          Text(
            'Actions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Deactivate / Reactivate
          if (admin.isActive)
            _ActionTile(
              icon: Icons.block_outlined,
              label: 'Deactivate Account',
              color: AppColors.error,
              onTap: () => _confirmDeactivate(context, ref),
            )
          else
            _ActionTile(
              icon: Icons.check_circle_outline,
              label: 'Reactivate Account',
              color: AppColors.success,
              onTap: () => _reactivate(context, ref),
            ),

          // Promote to owner (coaches only)
          if (admin.isCoach)
            _ActionTile(
              icon: Icons.star_outline,
              label: 'Promote to Owner',
              onTap: () => _confirmPromote(context, ref),
            ),

          // Demote to coach (owners only — but not the person themselves)
          if (admin.isOwner)
            disciplinesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (disciplines) => _ActionTile(
                icon: Icons.arrow_downward_outlined,
                label: 'Demote to Coach',
                color: AppColors.warning,
                onTap: () => _showDemoteSheet(context, ref, disciplines),
              ),
            ),

          // Delete
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Delete Account',
            color: AppColors.error,
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ],
    );
  }

  // ── Action helpers ─────────────────────────────────────────────────────

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: 'Deactivate ${admin.firstName}?',
      message:
          '${admin.fullName} will no longer be able to sign in. '
          'This can be reversed.',
      confirmLabel: 'Deactivate',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await _run(context, ref, () async {
      await ref
          .read(deactivateAdminUserUseCaseProvider)
          .call(
            uid: admin.firebaseUid,
            deactivatedByAdminId: ref
                .read(currentAdminUserProvider)!
                .firebaseUid,
          );
    });
  }

  Future<void> _reactivate(BuildContext context, WidgetRef ref) async {
    await _run(context, ref, () async {
      await ref
          .read(reactivateAdminUserUseCaseProvider)
          .call(uid: admin.firebaseUid);
    });
  }

  Future<void> _confirmPromote(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: 'Promote ${admin.firstName} to Owner?',
      message:
          '${admin.fullName} will have full access to all features, '
          'including managing other admins.',
      confirmLabel: 'Promote',
    );
    if (!confirmed || !context.mounted) return;
    await _run(context, ref, () async {
      await ref
          .read(promoteToOwnerUseCaseProvider)
          .call(uid: admin.firebaseUid);
    });
  }

  void _showDemoteSheet(
    BuildContext context,
    WidgetRef ref,
    List<Discipline> disciplines,
  ) {
    final active = disciplines.where((d) => d.isActive).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DemoteSheet(
        admin: admin,
        disciplines: active,
        onDemote: (disciplineIds) async {
          if (!context.mounted) return;
          Navigator.pop(context);
          await _run(context, ref, () async {
            await ref
                .read(demoteToCoachUseCaseProvider)
                .call(
                  uid: admin.firebaseUid,
                  requestingAdminUid: ref
                      .read(currentAdminUserProvider)!
                      .firebaseUid,
                  assignedDisciplineIds: disciplineIds,
                );
          });
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: 'Delete ${admin.firstName}\'s Account?',
      message:
          'This will permanently remove the Firestore document. '
          'The Firebase Auth account must be removed separately.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await _run(context, ref, () async {
      await ref
          .read(deleteAdminUserUseCaseProvider)
          .call(
            uid: admin.firebaseUid,
            deletedByAdminId: ref.read(currentAdminUserProvider)!.firebaseUid,
          );
      if (context.mounted) context.pop();
    });
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Done.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst(RegExp(r'^.*?: ?'), '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: AppColors.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ── Profile card ───────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.admin});

  final AdminUser admin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: admin.isActive
                ? AppColors.primary
                : AppColors.surfaceVariant,
            child: Text(
              '${admin.firstName[0]}${admin.lastName[0]}',
              style: TextStyle(
                color: admin.isActive
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.fullName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _RoleBadge(role: admin.role),
                    if (!admin.isActive) ...[
                      const SizedBox(width: 6),
                      _StatusBadge(isActive: admin.isActive),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isOwner ? AppColors.accent : AppColors.info,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withAlpha(77)),
      ),
      child: const Text(
        'Deactivated',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
      ),
    );
  }
}

// ── Info row ───────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action tile ────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c),
      title: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w500),
      ),
      contentPadding: EdgeInsets.zero,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}

// ── Demote bottom sheet ────────────────────────────────────────────────────

class _DemoteSheet extends StatefulWidget {
  const _DemoteSheet({
    required this.admin,
    required this.disciplines,
    required this.onDemote,
  });

  final AdminUser admin;
  final List<Discipline> disciplines;
  final void Function(List<String>) onDemote;

  @override
  State<_DemoteSheet> createState() => _DemoteSheetState();
}

class _DemoteSheetState extends State<_DemoteSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demote to Coach',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Assign disciplines for ${widget.admin.firstName}:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...widget.disciplines.map(
            (d) => CheckboxListTile(
              value: _selected.contains(d.id),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(d.id);
                } else {
                  _selected.remove(d.id);
                }
              }),
              title: Text(d.name),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => widget.onDemote(_selected.toList()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Demotion'),
            ),
          ),
        ],
      ),
    );
  }
}
