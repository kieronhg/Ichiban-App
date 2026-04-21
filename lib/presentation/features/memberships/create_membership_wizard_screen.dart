import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/membership_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/profile.dart';

class CreateMembershipWizardScreen extends ConsumerStatefulWidget {
  const CreateMembershipWizardScreen({super.key, this.preselectedProfileId});

  /// When set, the member assignment step pre-populates with this profile.
  final String? preselectedProfileId;

  @override
  ConsumerState<CreateMembershipWizardScreen> createState() =>
      _CreateMembershipWizardScreenState();
}

class _CreateMembershipWizardScreenState
    extends ConsumerState<CreateMembershipWizardScreen> {
  final _pageController = PageController();
  int _step = 0;
  bool _isSaving = false;

  // Step 1: plan type
  MembershipPlanType? _planType;

  // Step 2: members
  String? _primaryHolderId;
  final List<String> _memberProfileIds = [];

  // Step 3: payment
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  // Search
  String _profileSearch = '';

  @override
  void initState() {
    super.initState();
    if (widget.preselectedProfileId != null) {
      _primaryHolderId = widget.preselectedProfileId;
      _memberProfileIds.add(widget.preselectedProfileId!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isPayt =>
      _planType == MembershipPlanType.payAsYouTrainAdult ||
      _planType == MembershipPlanType.payAsYouTrainJunior;

  bool get _isTrial => _planType == MembershipPlanType.trial;

  bool get _isFamily => _planType == MembershipPlanType.familyMonthly;

  FamilyPricingTier? get _familyTier =>
      _isFamily ? Membership.deriveFamilyTier(_memberProfileIds.length) : null;

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  bool _canAdvanceStep1() => _planType != null;

  bool _canAdvanceStep2() {
    if (_isFamily) {
      return _memberProfileIds.isNotEmpty && _primaryHolderId != null;
    }
    return _primaryHolderId != null && _memberProfileIds.isNotEmpty;
  }

  Future<void> _submit() async {
    if (_planType == null || _primaryHolderId == null) return;

    setState(() => _isSaving = true);
    try {
      final adminId = ref.read(currentAdminIdProvider) ?? '';
      await ref
          .read(createMembershipUseCaseProvider)
          .call(
            planType: _planType!,
            primaryHolderId: _primaryHolderId!,
            memberProfileIds: List.from(_memberProfileIds),
            paymentMethod: _isTrial || _isPayt
                ? PaymentMethod.none
                : _paymentMethod,
            adminId: adminId,
            familyPricingTier: _familyTier,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Membership created.')));
        context.pop();
      }
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle()),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goTo(_step - 1),
              )
            : null,
      ),
      body: Column(
        children: [
          // ── Progress indicator ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LinearProgressIndicator(
              value: (_step + 1) / 4,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1PlanType(
                  selected: _planType,
                  onSelected: (p) => setState(() {
                    _planType = p;
                    // Reset members if plan type changes.
                    if (widget.preselectedProfileId == null) {
                      _primaryHolderId = null;
                      _memberProfileIds.clear();
                    }
                  }),
                ),
                _Step2Members(
                  planType: _planType,
                  primaryHolderId: _primaryHolderId,
                  memberProfileIds: _memberProfileIds,
                  profileSearch: _profileSearch,
                  onSearchChanged: (s) => setState(() => _profileSearch = s),
                  onPrimarySelected: (id) => setState(() {
                    _primaryHolderId = id;
                    if (!_memberProfileIds.contains(id)) {
                      _memberProfileIds.insert(0, id);
                    }
                  }),
                  onMemberAdded: (id) => setState(() {
                    if (!_memberProfileIds.contains(id)) {
                      _memberProfileIds.add(id);
                    }
                  }),
                  onMemberRemoved: (id) => setState(() {
                    _memberProfileIds.remove(id);
                    if (_primaryHolderId == id) _primaryHolderId = null;
                  }),
                  onPrimaryChanged: (id) =>
                      setState(() => _primaryHolderId = id),
                ),
                _Step3Payment(
                  planType: _planType,
                  selected: _paymentMethod,
                  onChanged: (m) => setState(() => _paymentMethod = m),
                ),
                _Step4Review(
                  planType: _planType,
                  primaryHolderId: _primaryHolderId,
                  memberProfileIds: _memberProfileIds,
                  paymentMethod: _isTrial || _isPayt
                      ? PaymentMethod.none
                      : _paymentMethod,
                  familyTier: _familyTier,
                ),
              ],
            ),
          ),
          // ── Bottom navigation ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _step < 3
                  ? FilledButton(
                      onPressed: _canAdvanceCurrentStep()
                          ? () => _goTo(_step + 1)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Continue'),
                    )
                  : FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnAccent,
                              ),
                            )
                          : const Text('Confirm & Create'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canAdvanceCurrentStep() {
    return switch (_step) {
      0 => _canAdvanceStep1(),
      1 => _canAdvanceStep2(),
      _ => true,
    };
  }

  String _stepTitle() => switch (_step) {
    0 => 'Select Plan',
    1 => 'Assign Members',
    2 => 'Payment Method',
    _ => 'Review & Confirm',
  };
}

// ── Step 1: Plan type selector ─────────────────────────────────────────────

class _Step1PlanType extends StatelessWidget {
  const _Step1PlanType({required this.selected, required this.onSelected});

  final MembershipPlanType? selected;
  final ValueChanged<MembershipPlanType> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Choose a membership plan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        for (final plan in _planCards)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlanCard(
              title: plan.$1,
              subtitle: plan.$2,
              price: plan.$3,
              planType: plan.$4,
              isSelected: selected == plan.$4,
              onTap: () => onSelected(plan.$4),
            ),
          ),
      ],
    );
  }

  static const List<(String, String, String, MembershipPlanType)> _planCards = [
    (
      'Free Trial',
      'Full access for 14 days. No payment required.',
      'Free',
      MembershipPlanType.trial,
    ),
    (
      'Monthly Adult',
      'Monthly rolling subscription for adult members.',
      '£33.00/month',
      MembershipPlanType.monthlyAdult,
    ),
    (
      'Monthly Junior',
      'Monthly rolling subscription for junior members.',
      '£25.00/month',
      MembershipPlanType.monthlyJunior,
    ),
    (
      'Annual Adult',
      'Annual subscription for adult members. Best value.',
      '£330.00/year',
      MembershipPlanType.annualAdult,
    ),
    (
      'Annual Junior',
      'Annual subscription for junior members. Best value.',
      '£242.00/year',
      MembershipPlanType.annualJunior,
    ),
    (
      'Family Monthly',
      'Up to 3 members: £55.00/month · 4+ members: £66.00/month.',
      'From £55.00/month',
      MembershipPlanType.familyMonthly,
    ),
    (
      'Pay As You Train (Adult)',
      'No subscription. Payment recorded per session attended.',
      '£10.00/session',
      MembershipPlanType.payAsYouTrainAdult,
    ),
    (
      'Pay As You Train (Junior)',
      'No subscription. Payment recorded per session attended.',
      '£7.00/session',
      MembershipPlanType.payAsYouTrainJunior,
    ),
  ];
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.planType,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final MembershipPlanType planType;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.surfaceVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Member assignment ──────────────────────────────────────────────

class _Step2Members extends ConsumerWidget {
  const _Step2Members({
    required this.planType,
    required this.primaryHolderId,
    required this.memberProfileIds,
    required this.profileSearch,
    required this.onSearchChanged,
    required this.onPrimarySelected,
    required this.onMemberAdded,
    required this.onMemberRemoved,
    required this.onPrimaryChanged,
  });

  final MembershipPlanType? planType;
  final String? primaryHolderId;
  final List<String> memberProfileIds;
  final String profileSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onPrimarySelected;
  final ValueChanged<String> onMemberAdded;
  final ValueChanged<String> onMemberRemoved;
  final ValueChanged<String> onPrimaryChanged;

  bool get _isFamily => planType == MembershipPlanType.familyMonthly;
  bool get _isPayt =>
      planType == MembershipPlanType.payAsYouTrainAdult ||
      planType == MembershipPlanType.payAsYouTrainJunior;
  bool get _isTrial => planType == MembershipPlanType.trial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProfiles = [
      ...ref
              .watch(profilesByTypeProvider(ProfileType.adultStudent))
              .asData
              ?.value ??
          [],
      ...ref
              .watch(profilesByTypeProvider(ProfileType.juniorStudent))
              .asData
              ?.value ??
          [],
      ...ref
              .watch(profilesByTypeProvider(ProfileType.parentGuardian))
              .asData
              ?.value ??
          [],
    ];

    final searchLower = profileSearch.toLowerCase();
    final filtered = searchLower.isEmpty
        ? allProfiles
        : allProfiles
              .where(
                (p) => '${p.firstName} ${p.lastName}'.toLowerCase().contains(
                  searchLower,
                ),
              )
              .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // PAYT notice
        if (_isPayt)
          _InfoBox(
            'Pay As You Train — payment is recorded per session, not here. '
            'Select the member this PAYT membership belongs to.',
          ),
        // Trial notice
        if (_isTrial)
          _InfoBox(
            'Trial memberships are available to new members only. '
            'Please verify eligibility before continuing.',
          ),
        // Family tier indicator
        if (_isFamily) ...[
          _FamilyTierIndicator(count: memberProfileIds.length),
          const SizedBox(height: 12),
          Text(
            'Selected members (${memberProfileIds.length})',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          for (final id in memberProfileIds)
            _SelectedMemberRow(
              profile: allProfiles.where((p) => p.id == id).firstOrNull,
              isPrimary: id == primaryHolderId,
              onRemove: memberProfileIds.length > 1
                  ? () => onMemberRemoved(id)
                  : null,
              onSetPrimary: () => onPrimaryChanged(id),
            ),
          const SizedBox(height: 16),
        ],
        // Search field
        TextField(
          decoration: InputDecoration(
            hintText: 'Search profiles…',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        // Profile list
        for (final profile in filtered)
          if (!memberProfileIds.contains(profile.id) || _isFamily)
            _ProfileSearchRow(
              profile: profile,
              isSelected: memberProfileIds.contains(profile.id),
              isPrimary: profile.id == primaryHolderId,
              isFamily: _isFamily,
              onTap: () {
                if (_isFamily) {
                  onMemberAdded(profile.id);
                  if (primaryHolderId == null) {
                    onPrimarySelected(profile.id);
                  }
                } else {
                  onPrimarySelected(profile.id);
                }
              },
            ),
      ],
    );
  }
}

class _FamilyTierIndicator extends StatelessWidget {
  const _FamilyTierIndicator({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tier = count >= 4 ? '£66.00/month' : '£55.00/month';
    final nextTier = count < 4
        ? '${4 - count} more member${4 - count == 1 ? '' : 's'} for £66.00/month tier'
        : null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count member${count == 1 ? '' : 's'} · $tier',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.info,
              fontSize: 14,
            ),
          ),
          if (nextTier != null) ...[
            const SizedBox(height: 2),
            Text(
              nextTier,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedMemberRow extends StatelessWidget {
  const _SelectedMemberRow({
    required this.profile,
    required this.isPrimary,
    required this.onRemove,
    required this.onSetPrimary,
  });

  final Profile? profile;
  final bool isPrimary;
  final VoidCallback? onRemove;
  final VoidCallback onSetPrimary;

  @override
  Widget build(BuildContext context) {
    final name = profile != null
        ? '${profile!.firstName} ${profile!.lastName}'
        : 'Unknown';
    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        dense: true,
        title: Text(name, style: const TextStyle(fontSize: 14)),
        subtitle: isPrimary
            ? const Text(
                'Primary holder',
                style: TextStyle(fontSize: 12, color: AppColors.accent),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPrimary)
              TextButton(
                onPressed: onSetPrimary,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(60, 30),
                ),
                child: const Text(
                  'Set primary',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppColors.error,
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSearchRow extends StatelessWidget {
  const _ProfileSearchRow({
    required this.profile,
    required this.isSelected,
    required this.isPrimary,
    required this.isFamily,
    required this.onTap,
  });

  final Profile profile;
  final bool isSelected;
  final bool isPrimary;
  final bool isFamily;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text('${profile.firstName} ${profile.lastName}'),
      subtitle: Text(
        profile.profileTypes
            .map(
              (t) => switch (t) {
                ProfileType.adultStudent => 'Adult',
                ProfileType.juniorStudent => 'Junior',
                ProfileType.coach => 'Coach',
                ProfileType.parentGuardian => 'Parent/Guardian',
              },
            )
            .join(', '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isSelected && !isFamily
          ? const Icon(Icons.check_circle, color: AppColors.accent)
          : isSelected && isFamily
          ? const Icon(Icons.check, color: AppColors.success, size: 20)
          : const Icon(
              Icons.add_circle_outline,
              color: AppColors.textSecondary,
            ),
      onTap: isSelected && !isFamily ? null : onTap,
    );
  }
}

// ── Step 3: Payment method ─────────────────────────────────────────────────

class _Step3Payment extends StatelessWidget {
  const _Step3Payment({
    required this.planType,
    required this.selected,
    required this.onChanged,
  });

  final MembershipPlanType? planType;
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  bool get _isPayt =>
      planType == MembershipPlanType.payAsYouTrainAdult ||
      planType == MembershipPlanType.payAsYouTrainJunior;

  bool get _isTrial => planType == MembershipPlanType.trial;

  @override
  Widget build(BuildContext context) {
    if (_isTrial) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: _InfoBox(
          'Free trial — no payment required at this stage. '
          'A payment method will be selected when the member converts to a paid plan.',
        ),
      );
    }

    if (_isPayt) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: _InfoBox(
          'Pay As You Train — payment is recorded per session when the member checks in. '
          'No payment method is set at the membership level.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'How was payment made?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        for (final method in [
          PaymentMethod.cash,
          PaymentMethod.card,
          PaymentMethod.bankTransfer,
        ])
          _PaymentMethodTile(
            method: method,
            isSelected: selected == method,
            onTap: () => onChanged(method),
          ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (method) {
      PaymentMethod.cash => ('Cash', Icons.payments_outlined),
      PaymentMethod.card => ('Card', Icons.credit_card_outlined),
      PaymentMethod.bankTransfer => (
        'Bank Transfer',
        Icons.account_balance_outlined,
      ),
      _ => ('Other', Icons.more_horiz),
    };

    return Card(
      elevation: 0,
      color: isSelected
          ? AppColors.accent.withValues(alpha: 0.08)
          : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.accent : AppColors.surfaceVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ── Step 4: Review ─────────────────────────────────────────────────────────

class _Step4Review extends ConsumerWidget {
  const _Step4Review({
    required this.planType,
    required this.primaryHolderId,
    required this.memberProfileIds,
    required this.paymentMethod,
    required this.familyTier,
  });

  final MembershipPlanType? planType;
  final String? primaryHolderId;
  final List<String> memberProfileIds;
  final PaymentMethod paymentMethod;
  final FamilyPricingTier? familyTier;

  bool get _isPayt =>
      planType == MembershipPlanType.payAsYouTrainAdult ||
      planType == MembershipPlanType.payAsYouTrainJunior;
  bool get _isTrial => planType == MembershipPlanType.trial;
  bool get _isAnnual =>
      planType == MembershipPlanType.annualAdult ||
      planType == MembershipPlanType.annualJunior;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProfiles = [
      ...ref
              .watch(profilesByTypeProvider(ProfileType.adultStudent))
              .asData
              ?.value ??
          [],
      ...ref
              .watch(profilesByTypeProvider(ProfileType.juniorStudent))
              .asData
              ?.value ??
          [],
      ...ref
              .watch(profilesByTypeProvider(ProfileType.parentGuardian))
              .asData
              ?.value ??
          [],
    ];
    final profileMap = {for (final p in allProfiles) p.id: p};

    final pricingAsync = ref.watch(membershipPricingMapProvider);

    final now = DateTime.now();
    DateTime? renewalDate;
    if (!_isTrial && !_isPayt) {
      renewalDate = _isAnnual
          ? DateTime(now.year + 1, now.month, now.day)
          : DateTime(now.year, now.month + 1, now.day);
    }

    final dateFormat = DateFormat('d MMM yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Review your selection',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        _ReviewCard(
          title: 'Plan',
          children: [
            _ReviewRow('Type', _planLabel(planType)),
            if (!_isPayt && !_isTrial)
              pricingAsync.when(
                data: (prices) {
                  final key = _pricingKey(planType, familyTier);
                  final amount = prices[key] ?? 0.0;
                  return _ReviewRow(
                    'Amount',
                    '£${amount.toStringAsFixed(2)}${_isAnnual ? '/year' : '/month'}',
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            if (_isTrial) ...[
              _ReviewRow('Start date', dateFormat.format(now)),
              _ReviewRow(
                'Trial ends',
                dateFormat.format(now.add(const Duration(days: 14))),
              ),
            ],
            if (renewalDate != null)
              _ReviewRow('First renewal date', dateFormat.format(renewalDate)),
            if (_isPayt) const _ReviewRow('Billing', 'Per session'),
          ],
        ),

        const SizedBox(height: 12),

        _ReviewCard(
          title: 'Members',
          children: [
            for (final id in memberProfileIds)
              _ReviewRow(
                id == primaryHolderId ? 'Primary holder' : 'Member',
                profileMap[id] != null
                    ? '${profileMap[id]!.firstName} ${profileMap[id]!.lastName}'
                    : id,
              ),
          ],
        ),

        if (!_isTrial && !_isPayt) ...[
          const SizedBox(height: 12),
          _ReviewCard(
            title: 'Payment',
            children: [_ReviewRow('Method', _paymentLabel(paymentMethod))],
          ),
        ],
      ],
    );
  }

  String _planLabel(MembershipPlanType? p) => switch (p) {
    MembershipPlanType.trial => 'Free Trial (14 days)',
    MembershipPlanType.monthlyAdult => 'Monthly Adult',
    MembershipPlanType.monthlyJunior => 'Monthly Junior',
    MembershipPlanType.annualAdult => 'Annual Adult',
    MembershipPlanType.annualJunior => 'Annual Junior',
    MembershipPlanType.familyMonthly => 'Family Monthly',
    MembershipPlanType.payAsYouTrainAdult => 'Pay As You Train (Adult)',
    MembershipPlanType.payAsYouTrainJunior => 'Pay As You Train (Junior)',
    null => '—',
  };

  String _paymentLabel(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.bankTransfer => 'Bank Transfer',
    PaymentMethod.stripe => 'Stripe',
    PaymentMethod.none => 'None',
  };

  String _pricingKey(MembershipPlanType? planType, FamilyPricingTier? tier) {
    return switch (planType) {
      MembershipPlanType.monthlyAdult => 'monthlyAdult',
      MembershipPlanType.monthlyJunior => 'monthlyJunior',
      MembershipPlanType.annualAdult => 'annualAdult',
      MembershipPlanType.annualJunior => 'annualJunior',
      MembershipPlanType.familyMonthly =>
        tier == FamilyPricingTier.fourOrMore
            ? 'familyMonthlyFourOrMore'
            : 'familyMonthlyUpToThree',
      _ => '',
    };
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared ─────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
