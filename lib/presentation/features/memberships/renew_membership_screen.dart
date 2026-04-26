import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/membership_providers.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/membership.dart';

class RenewMembershipScreen extends ConsumerStatefulWidget {
  const RenewMembershipScreen({super.key, required this.membership});

  final Membership membership;

  @override
  ConsumerState<RenewMembershipScreen> createState() =>
      _RenewMembershipScreenState();
}

class _RenewMembershipScreenState extends ConsumerState<RenewMembershipScreen> {
  final _pageController = PageController();
  int _step = 0;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isSaving = false;

  bool get _isAnnual =>
      widget.membership.planType == MembershipPlanType.annualAdult ||
      widget.membership.planType == MembershipPlanType.annualJunior;

  DateTime get _newRenewalDate {
    final base = widget.membership.subscriptionRenewalDate ?? DateTime.now();
    return _isAnnual
        ? DateTime(base.year + 1, base.month, base.day)
        : DateTime(base.year, base.month + 1, base.day);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      final adminId = ref.read(currentAdminIdProvider) ?? '';
      await ref
          .read(renewMembershipUseCaseProvider)
          .call(
            membership: widget.membership,
            paymentMethod: _paymentMethod,
            adminId: adminId,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Membership renewed.')));
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
        title: const Text('Renew Membership'),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goTo(_step - 1),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LinearProgressIndicator(
              value: (_step + 1) / 3,
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
                _Step1Details(
                  membership: widget.membership,
                  newRenewalDate: _newRenewalDate,
                ),
                _Step2Payment(
                  selected: _paymentMethod,
                  onChanged: (m) => setState(() => _paymentMethod = m),
                ),
                _Step3Confirm(
                  membership: widget.membership,
                  newRenewalDate: _newRenewalDate,
                  paymentMethod: _paymentMethod,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _step < 2
                  ? FilledButton(
                      onPressed: () => _goTo(_step + 1),
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
                          : const Text('Confirm Renewal'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Renewal details ────────────────────────────────────────────────

class _Step1Details extends ConsumerWidget {
  const _Step1Details({required this.membership, required this.newRenewalDate});

  final Membership membership;
  final DateTime newRenewalDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricingAsync = ref.watch(membershipPricingMapProvider);
    final dateFormat = DateFormat('d MMM yyyy');

    return pricingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading pricing: $e')),
      data: (prices) {
        final key = _pricingKey();
        final newAmount = prices[key] ?? membership.monthlyAmount;
        final priceChanged = newAmount != membership.monthlyAmount;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Renewal details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Price change callout
            if (priceChanged)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Price has changed from £${membership.monthlyAmount.toStringAsFixed(2)} to £${newAmount.toStringAsFixed(2)}.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Row('Plan', _planLabel(membership.planType)),
                    _Row('New renewal date', dateFormat.format(newRenewalDate)),
                    _Row(
                      'Amount',
                      '£${newAmount.toStringAsFixed(2)}${_frequency()}',
                    ),
                    if (membership.isFamily)
                      _Row(
                        'Family tier',
                        membership.memberProfileIds.length >= 4
                            ? '4+ members (£66.00/month)'
                            : 'Up to 3 members (£55.00/month)',
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _pricingKey() {
    final tier = membership.isFamily
        ? Membership.deriveFamilyTier(membership.memberProfileIds.length)
        : null;
    return switch (membership.planType) {
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

  String _frequency() => switch (membership.planType) {
    MembershipPlanType.annualAdult ||
    MembershipPlanType.annualJunior => '/year',
    _ => '/month',
  };

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
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Payment method ─────────────────────────────────────────────────

class _Step2Payment extends StatelessWidget {
  const _Step2Payment({required this.selected, required this.onChanged});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
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
          Card(
            elevation: 0,
            color: selected == method
                ? AppColors.accent.withValues(alpha: 0.08)
                : AppColors.surface,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected == method
                    ? AppColors.accent
                    : AppColors.surfaceVariant,
                width: selected == method ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: Icon(
                _icon(method),
                color: selected == method
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              title: Text(
                _label(method),
                style: TextStyle(
                  color: selected == method
                      ? AppColors.accent
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                selected == method ? Icons.check_circle : Icons.circle_outlined,
                color: selected == method
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              onTap: () => onChanged(method),
            ),
          ),
      ],
    );
  }

  IconData _icon(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.card => Icons.credit_card_outlined,
    PaymentMethod.bankTransfer => Icons.account_balance_outlined,
    _ => Icons.more_horiz,
  };

  String _label(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.bankTransfer => 'Bank Transfer',
    _ => '—',
  };
}

// ── Step 3: Confirm ────────────────────────────────────────────────────────

class _Step3Confirm extends StatelessWidget {
  const _Step3Confirm({
    required this.membership,
    required this.newRenewalDate,
    required this.paymentMethod,
  });

  final Membership membership;
  final DateTime newRenewalDate;
  final PaymentMethod paymentMethod;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy').format(newRenewalDate);
    final method = switch (paymentMethod) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.card => 'Card',
      PaymentMethod.bankTransfer => 'Bank Transfer',
      _ => '—',
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Confirm renewal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Row('New renewal date', dateStr),
                _Row('Payment method', method),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
