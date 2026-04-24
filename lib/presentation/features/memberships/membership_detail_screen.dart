import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/membership_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/membership_history.dart';
import '../../../domain/entities/profile.dart';

class MembershipDetailScreen extends ConsumerWidget {
  const MembershipDetailScreen({super.key, required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the membership live so changes from renew/cancel reflect immediately.
    final membershipAsync = ref.watch(membershipProvider(membership.id));
    final live = membershipAsync.asData?.value ?? membership;

    final allProfiles = [
      ...ref
              .watch(profilesByTypeProvider(ProfileType.adultStudent))
              .asData
              ?.value ??
          <Profile>[],
      ...ref
              .watch(profilesByTypeProvider(ProfileType.juniorStudent))
              .asData
              ?.value ??
          <Profile>[],
      ...ref
              .watch(profilesByTypeProvider(ProfileType.parentGuardian))
              .asData
              ?.value ??
          <Profile>[],
    ];
    final profileMap = {for (final p in allProfiles) p.id: p};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profileMap[live.primaryHolderId]?.let(
                (p) => '${p.firstName} ${p.lastName}',
              ) ??
              'Membership',
        ),
        actions: [
          PopupMenuButton<_Action>(
            onSelected: (action) =>
                _handleAction(context, ref, live, action, profileMap),
            itemBuilder: (_) => [
              if (live.status == MembershipStatus.active ||
                  live.status == MembershipStatus.lapsed)
                const PopupMenuItem(value: _Action.renew, child: Text('Renew')),
              const PopupMenuItem(
                value: _Action.convert,
                child: Text('Convert Plan'),
              ),
              const PopupMenuItem(
                value: _Action.override,
                child: Text('Manual Status Override'),
              ),
              if (live.status != MembershipStatus.cancelled)
                const PopupMenuItem(
                  value: _Action.cancel,
                  child: Text(
                    'Cancel Membership',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Plan summary ──────────────────────────────────────────────────
          _PlanSummaryCard(membership: live),
          const SizedBox(height: 16),

          // ── Members ───────────────────────────────────────────────────────
          _MembersCard(
            membership: live,
            profileMap: profileMap,
            onAddMember: live.isFamily && live.isActive
                ? () => _addMember(context, ref, live, allProfiles, profileMap)
                : null,
          ),
          const SizedBox(height: 16),

          // ── Payment history ───────────────────────────────────────────────
          _PaymentHistoryCard(membershipId: live.id),
          const SizedBox(height: 16),

          // ── Membership history ────────────────────────────────────────────
          _MembershipHistoryCard(membershipId: live.id),
          const SizedBox(height: 16),

          // ── Notes ─────────────────────────────────────────────────────────
          _NotesCard(membership: live),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    Membership live,
    _Action action,
    Map<String, Profile> profileMap,
  ) async {
    switch (action) {
      case _Action.renew:
        if (!context.mounted) return;
        context.pushNamed(
          RouteNames.adminMembershipsRenew,
          pathParameters: {'membershipId': live.id},
          extra: live,
        );

      case _Action.convert:
        if (!context.mounted) return;
        context.pushNamed(
          RouteNames.adminMembershipsConvert,
          pathParameters: {'membershipId': live.id},
          extra: live,
        );

      case _Action.cancel:
        await _cancelMembership(context, ref, live, profileMap);

      case _Action.override:
        await _overrideStatus(context, ref, live);
    }
  }

  Future<void> _cancelMembership(
    BuildContext context,
    WidgetRef ref,
    Membership live,
    Map<String, Profile> profileMap,
  ) async {
    final primaryName =
        profileMap[live.primaryHolderId]?.let(
          (p) => '${p.firstName} ${p.lastName}',
        ) ??
        'this member';

    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Membership?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancel $primaryName\'s ${_planLabel(live.planType)} membership? '
              'This cannot be undone. Their discipline enrolments will not be affected.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional — e.g. refund details)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Membership'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final adminId = ref.read(currentAdminIdProvider) ?? '';
      await ref
          .read(cancelMembershipUseCaseProvider)
          .call(
            membership: live,
            adminId: adminId,
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Membership cancelled.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _overrideStatus(
    BuildContext context,
    WidgetRef ref,
    Membership live,
  ) async {
    MembershipStatus? selectedStatus = live.status;
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Manual Status Override'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MembershipStatus>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'New status',
                  border: OutlineInputBorder(),
                ),
                items: MembershipStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(_statusLabel(s)),
                      ),
                    )
                    .toList(),
                onChanged: (s) => setState(() => selectedStatus = s),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (required)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selectedStatus == null) return;
    if (!context.mounted) return;

    try {
      final adminId = ref.read(currentAdminIdProvider) ?? '';
      await ref
          .read(overrideMembershipStatusUseCaseProvider)
          .call(
            membership: live,
            newStatus: selectedStatus!,
            adminId: adminId,
            notes: notesCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Status updated.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _addMember(
    BuildContext context,
    WidgetRef ref,
    Membership live,
    List<Profile> allProfiles,
    Map<String, Profile> profileMap,
  ) async {
    final eligible = allProfiles
        .where((p) => !live.memberProfileIds.contains(p.id))
        .toList();

    Profile? selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Member'),
          content: SizedBox(
            width: double.maxFinite,
            child: DropdownButtonFormField<Profile>(
              initialValue: selected,
              decoration: const InputDecoration(
                labelText: 'Select member',
                border: OutlineInputBorder(),
              ),
              items: eligible
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.firstName} ${p.lastName}'),
                    ),
                  )
                  .toList(),
              onChanged: (p) => setState(() => selected = p),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selected != null
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selected == null) return;
    if (!context.mounted) return;

    // Show tier change notice if adding takes count from 3→4.
    final newCount = live.memberProfileIds.length + 1;
    if (newCount == 4 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selected!.firstName} added. Pricing tier will update to £66.00/month at next renewal.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    try {
      final adminId = ref.read(currentAdminIdProvider) ?? '';
      await ref
          .read(addFamilyMemberUseCaseProvider)
          .call(membership: live, profile: selected!, adminId: adminId);
      if (context.mounted && newCount != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selected!.firstName} added to family plan.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

enum _Action { renew, convert, cancel, override }

// ── Plan summary card ──────────────────────────────────────────────────────

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    final renewalStr = membership.subscriptionRenewalDate != null
        ? dateFormat.format(membership.subscriptionRenewalDate!)
        : membership.isPayAsYouTrain
        ? 'No renewal — Pay As You Train'
        : membership.isTrial
        ? 'Trial ends ${dateFormat.format(membership.trialEndDate!)}'
        : '—';

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _planLabel(membership.planType),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusBadge(status: membership.status),
              ],
            ),
            const SizedBox(height: 8),
            if (!membership.isPayAsYouTrain)
              _DetailRow(
                Icons.payments_outlined,
                '£${membership.monthlyAmount.toStringAsFixed(2)}${_frequency(membership.planType)}',
              ),
            _DetailRow(Icons.calendar_today_outlined, renewalStr),
            if (membership.paymentMethod != PaymentMethod.none)
              _DetailRow(
                Icons.credit_card_outlined,
                _paymentLabel(membership.paymentMethod),
              ),
          ],
        ),
      ),
    );
  }

  String _frequency(MembershipPlanType p) => switch (p) {
    MembershipPlanType.annualAdult ||
    MembershipPlanType.annualJunior => '/year',
    MembershipPlanType.payAsYouTrainAdult ||
    MembershipPlanType.payAsYouTrainJunior => '/session',
    _ => '/month',
  };

  String _paymentLabel(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.bankTransfer => 'Bank Transfer',
    PaymentMethod.stripe => 'Stripe',
    PaymentMethod.none => 'None',
  };
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Members card ───────────────────────────────────────────────────────────

class _MembersCard extends ConsumerWidget {
  const _MembersCard({
    required this.membership,
    required this.profileMap,
    this.onAddMember,
  });

  final Membership membership;
  final Map<String, Profile> profileMap;
  final VoidCallback? onAddMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Members',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (onAddMember != null)
                  TextButton.icon(
                    onPressed: onAddMember,
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Add Member'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final profileId in membership.memberProfileIds)
              _MemberRow(
                profile: profileMap[profileId],
                isPrimary: profileId == membership.primaryHolderId,
                canRemove:
                    membership.isFamily &&
                    membership.isActive &&
                    membership.memberProfileIds.length > 1 &&
                    profileId != membership.primaryHolderId,
                onRemove: () =>
                    _removeMember(context, ref, profileMap[profileId]),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    Profile? profile,
  ) async {
    if (profile == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text(
          'Remove ${profile.firstName} ${profile.lastName} from this family plan? '
          'Their discipline enrolments will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final adminId = ref.read(currentAdminIdProvider) ?? '';
      await ref
          .read(removeFamilyMemberUseCaseProvider)
          .call(membership: membership, profile: profile, adminId: adminId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.profile,
    required this.isPrimary,
    required this.canRemove,
    required this.onRemove,
  });

  final Profile? profile;
  final bool isPrimary;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = profile != null
        ? '${profile!.firstName} ${profile!.lastName}'
        : 'Unknown';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.surfaceVariant,
        child: Icon(Icons.person, size: 18, color: AppColors.textSecondary),
      ),
      title: Text(name, style: const TextStyle(fontSize: 14)),
      subtitle: isPrimary
          ? const Text(
              'Primary holder',
              style: TextStyle(fontSize: 12, color: AppColors.accent),
            )
          : null,
      trailing: canRemove
          ? IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: onRemove,
            )
          : null,
    );
  }
}

// ── Payment history card ───────────────────────────────────────────────────

class _PaymentHistoryCard extends ConsumerWidget {
  const _PaymentHistoryCard({required this.membershipId});

  final String membershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(
      cashPaymentsForMembershipProvider(membershipId),
    );

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment History',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (payments) {
                if (payments.isEmpty) {
                  return const Text(
                    'No payments recorded.',
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                }
                return Column(
                  children: payments
                      .map(
                        (p) => _PaymentRow(
                          amount: p.amount,
                          method: p.paymentMethod,
                          date: p.recordedAt,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.amount,
    required this.method,
    required this.date,
  });

  final double amount;
  final PaymentMethod method;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy').format(date);
    final methodStr = switch (method) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.card => 'Card',
      PaymentMethod.bankTransfer => 'Bank Transfer',
      PaymentMethod.stripe => 'Stripe',
      PaymentMethod.none => '—',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '£${amount.toStringAsFixed(2)} · $methodStr',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Membership history card ────────────────────────────────────────────────

class _MembershipHistoryCard extends ConsumerWidget {
  const _MembershipHistoryCard({required this.membershipId});

  final String membershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(membershipHistoryProvider(membershipId));

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Membership History',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (records) {
                if (records.isEmpty) {
                  return const Text(
                    'No history records.',
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                }
                return Column(
                  children: records.map((r) => _HistoryRow(record: r)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record});

  final MembershipHistory record;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy, HH:mm').format(record.changedAt);
    final label = switch (record.changeType) {
      MembershipChangeType.created => 'Created',
      MembershipChangeType.renewed => 'Renewed',
      MembershipChangeType.lapsed => 'Lapsed',
      MembershipChangeType.cancelled => 'Cancelled',
      MembershipChangeType.reactivated => 'Reactivated',
      MembershipChangeType.planChanged => 'Plan changed',
      MembershipChangeType.statusOverride => 'Status override',
    };
    final source = record.triggeredByCloudFunction
        ? 'Automated'
        : record.changedByAdminId != null
        ? 'Admin'
        : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                source,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (record.notes != null) ...[
            const SizedBox(height: 2),
            Text(
              record.notes!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const Divider(height: 12),
        ],
      ),
    );
  }
}

// ── Notes card ─────────────────────────────────────────────────────────────

class _NotesCard extends ConsumerStatefulWidget {
  const _NotesCard({required this.membership});

  final Membership membership;

  @override
  ConsumerState<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<_NotesCard> {
  late final TextEditingController _ctrl;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.membership.notes ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Notes',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (!_editing)
                  TextButton(
                    onPressed: () => setState(() => _editing = true),
                    child: const Text('Edit'),
                  )
                else
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_editing)
              TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Admin notes, refund details…',
                  filled: true,
                  fillColor: AppColors.background,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              )
            else
              Text(
                _ctrl.text.isEmpty ? 'No notes.' : _ctrl.text,
                style: TextStyle(
                  color: _ctrl.text.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.membership.copyWith(notes: _ctrl.text.trim());
      await ref.read(membershipRepositoryProvider).update(updated);
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Status badge ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MembershipStatus.trial => ('Trial', AppColors.info),
      MembershipStatus.active => ('Active', AppColors.success),
      MembershipStatus.lapsed => ('Lapsed', AppColors.warning),
      MembershipStatus.cancelled => ('Cancelled', AppColors.textSecondary),
      MembershipStatus.expired => ('Expired', AppColors.error),
      MembershipStatus.payt => ('PAYT', AppColors.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

String _planLabel(MembershipPlanType p) => switch (p) {
  MembershipPlanType.trial => 'Free Trial',
  MembershipPlanType.monthlyAdult => 'Monthly Adult',
  MembershipPlanType.monthlyJunior => 'Monthly Junior',
  MembershipPlanType.annualAdult => 'Annual Adult',
  MembershipPlanType.annualJunior => 'Annual Junior',
  MembershipPlanType.familyMonthly => 'Family Monthly',
  MembershipPlanType.payAsYouTrainAdult => 'Pay As You Train (Adult)',
  MembershipPlanType.payAsYouTrainJunior => 'Pay As You Train (Junior)',
};

String _statusLabel(MembershipStatus s) => switch (s) {
  MembershipStatus.trial => 'Trial',
  MembershipStatus.active => 'Active',
  MembershipStatus.lapsed => 'Lapsed',
  MembershipStatus.cancelled => 'Cancelled',
  MembershipStatus.expired => 'Expired',
  MembershipStatus.payt => 'PAYT',
};

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
