import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../dashboard/admin_drawer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/membership_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/membership.dart';

class MembershipListScreen extends ConsumerStatefulWidget {
  const MembershipListScreen({super.key});

  @override
  ConsumerState<MembershipListScreen> createState() =>
      _MembershipListScreenState();
}

class _MembershipListScreenState extends ConsumerState<MembershipListScreen> {
  MembershipStatus? _statusFilter;
  MembershipPlanType? _planFilter;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final membershipsAsync = ref.watch(membershipListProvider);
    final allProfilesAsync = ref.watch(
      profilesByTypeProvider(ProfileType.adultStudent),
    );
    final juniorProfilesAsync = ref.watch(
      profilesByTypeProvider(ProfileType.juniorStudent),
    );
    final parentProfilesAsync = ref.watch(
      profilesByTypeProvider(ProfileType.parentGuardian),
    );

    final profileMap = <String, String>{
      for (final p in [
        ...allProfilesAsync.asData?.value ?? [],
        ...juniorProfilesAsync.asData?.value ?? [],
        ...parentProfilesAsync.asData?.value ?? [],
      ])
        p.id: '${p.firstName} ${p.lastName}',
    };

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const Text('Memberships')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.adminMembershipsCreate),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.add),
        label: const Text('Create Membership'),
      ),
      body: Column(
        children: [
          // ── Search ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by member name…',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          // ── Filter chips ──────────────────────────────────────────────────
          _FilterBar(
            statusFilter: _statusFilter,
            planFilter: _planFilter,
            onStatusChanged: (s) => setState(() => _statusFilter = s),
            onPlanChanged: (p) => setState(() => _planFilter = p),
          ),
          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: membershipsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (memberships) {
                final filtered = memberships.where((m) {
                  if (_statusFilter != null && m.status != _statusFilter) {
                    return false;
                  }
                  if (_planFilter != null && m.planType != _planFilter) {
                    return false;
                  }
                  if (_search.isNotEmpty) {
                    final primaryName =
                        profileMap[m.primaryHolderId]?.toLowerCase() ?? '';
                    final memberNames = m.memberProfileIds
                        .map((id) => profileMap[id]?.toLowerCase() ?? '')
                        .join(' ');
                    if (!primaryName.contains(_search) &&
                        !memberNames.contains(_search)) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.card_membership_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusFilter == null && _planFilter == null
                              ? 'No memberships yet'
                              : 'No memberships match the current filters',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final m = filtered[i];
                    return _MembershipTile(
                      membership: m,
                      profileMap: profileMap,
                      onTap: () => context.pushNamed(
                        RouteNames.adminMembershipsDetail,
                        pathParameters: {'membershipId': m.id},
                        extra: m,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ─────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.statusFilter,
    required this.planFilter,
    required this.onStatusChanged,
    required this.onPlanChanged,
  });

  final MembershipStatus? statusFilter;
  final MembershipPlanType? planFilter;
  final ValueChanged<MembershipStatus?> onStatusChanged;
  final ValueChanged<MembershipPlanType?> onPlanChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _Chip(
                label: 'All',
                selected: statusFilter == null,
                onTap: () => onStatusChanged(null),
              ),
              const SizedBox(width: 8),
              for (final s in MembershipStatus.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Chip(
                    label: _statusLabel(s),
                    selected: statusFilter == s,
                    onTap: () => onStatusChanged(statusFilter == s ? null : s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  String _statusLabel(MembershipStatus s) => switch (s) {
    MembershipStatus.trial => 'Trial',
    MembershipStatus.active => 'Active',
    MembershipStatus.lapsed => 'Lapsed',
    MembershipStatus.cancelled => 'Cancelled',
    MembershipStatus.expired => 'Expired',
    MembershipStatus.payt => 'PAYT',
  };
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textOnAccent : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Membership tile ────────────────────────────────────────────────────────

class _MembershipTile extends StatelessWidget {
  const _MembershipTile({
    required this.membership,
    required this.profileMap,
    required this.onTap,
  });

  final Membership membership;
  final Map<String, String> profileMap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryName =
        profileMap[membership.primaryHolderId] ?? membership.primaryHolderId;
    final memberNames = membership.memberProfileIds
        .map((id) => profileMap[id] ?? id)
        .join(', ');

    final renewalStr = membership.subscriptionRenewalDate != null
        ? DateFormat('d MMM yyyy').format(membership.subscriptionRenewalDate!)
        : membership.isPayAsYouTrain
        ? 'PAYT'
        : '—';

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (membership.isFamily &&
                        membership.memberProfileIds.length > 1) ...[
                      const SizedBox(height: 2),
                      Text(
                        memberNames,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _PlanBadge(planType: membership.planType),
                        const SizedBox(width: 8),
                        Text(
                          '£${membership.monthlyAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (renewalStr.isNotEmpty)
                          Text(
                            renewalStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: membership.status),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Plan badge ─────────────────────────────────────────────────────────────

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.planType});

  final MembershipPlanType planType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        _planLabel(planType),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  String _planLabel(MembershipPlanType p) => switch (p) {
    MembershipPlanType.trial => 'Trial',
    MembershipPlanType.monthlyAdult => 'Monthly Adult',
    MembershipPlanType.monthlyJunior => 'Monthly Junior',
    MembershipPlanType.annualAdult => 'Annual Adult',
    MembershipPlanType.annualJunior => 'Annual Junior',
    MembershipPlanType.familyMonthly => 'Family Monthly',
    MembershipPlanType.payAsYouTrainAdult => 'PAYT Adult',
    MembershipPlanType.payAsYouTrainJunior => 'PAYT Junior',
  };
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
