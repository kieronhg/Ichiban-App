import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/membership_providers.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/membership.dart';

class ConvertMembershipPlanScreen extends ConsumerStatefulWidget {
  const ConvertMembershipPlanScreen({super.key, required this.membership});

  final Membership membership;

  @override
  ConsumerState<ConvertMembershipPlanScreen> createState() =>
      _ConvertMembershipPlanScreenState();
}

class _ConvertMembershipPlanScreenState
    extends ConsumerState<ConvertMembershipPlanScreen> {
  final _pageController = PageController();
  int _step = 0;
  MembershipPlanType? _newPlanType;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isSaving = false;

  bool get _isPayt =>
      _newPlanType == MembershipPlanType.payAsYouTrainAdult ||
      _newPlanType == MembershipPlanType.payAsYouTrainJunior;

  bool get _isTrial => _newPlanType == MembershipPlanType.trial;

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
    if (_newPlanType == null) return;
    setState(() => _isSaving = true);
    try {
      final adminId = ref.read(currentAdminIdProvider) ?? '';
      await ref
          .read(convertMembershipPlanUseCaseProvider)
          .call(
            oldMembership: widget.membership,
            newPlanType: _newPlanType!,
            paymentMethod: _isTrial || _isPayt
                ? PaymentMethod.none
                : _paymentMethod,
            adminId: adminId,
            familyPricingTier: _newPlanType == MembershipPlanType.familyMonthly
                ? Membership.deriveFamilyTier(
                    widget.membership.memberProfileIds.length,
                  )
                : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan converted successfully.')),
        );
        // Pop twice: back past detail screen to list (detail will be stale).
        context.pop();
        if (context.mounted) context.pop();
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
        title: const Text('Convert Plan'),
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
                _Step1SelectPlan(
                  currentPlanType: widget.membership.planType,
                  selected: _newPlanType,
                  onSelected: (p) => setState(() => _newPlanType = p),
                ),
                _Step2PaymentMethod(
                  newPlanType: _newPlanType,
                  selected: _paymentMethod,
                  onChanged: (m) => setState(() => _paymentMethod = m),
                ),
                _Step3Confirm(
                  oldPlanType: widget.membership.planType,
                  newPlanType: _newPlanType,
                  paymentMethod: _isTrial || _isPayt
                      ? PaymentMethod.none
                      : _paymentMethod,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _step < 2
                  ? FilledButton(
                      onPressed: _newPlanType != null || _step > 0
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
                          : const Text('Confirm Conversion'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Plan selector ──────────────────────────────────────────────────

class _Step1SelectPlan extends StatelessWidget {
  const _Step1SelectPlan({
    required this.currentPlanType,
    required this.selected,
    required this.onSelected,
  });

  final MembershipPlanType currentPlanType;
  final MembershipPlanType? selected;
  final ValueChanged<MembershipPlanType> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Select new plan type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'The current plan will be cancelled and a new one created.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        for (final plan in MembershipPlanType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlanOption(
              planType: plan,
              isCurrent: plan == currentPlanType,
              isSelected: plan == selected,
              onTap: plan == currentPlanType ? null : () => onSelected(plan),
            ),
          ),
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.planType,
    required this.isCurrent,
    required this.isSelected,
    required this.onTap,
  });

  final MembershipPlanType planType;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.surfaceVariant
              : isSelected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? AppColors.textSecondary.withValues(alpha: 0.3)
                : isSelected
                ? AppColors.accent
                : AppColors.surfaceVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _planLabel(planType),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isCurrent
                      ? AppColors.textSecondary
                      : isSelected
                      ? AppColors.accent
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

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

// ── Step 2: Payment method ─────────────────────────────────────────────────

class _Step2PaymentMethod extends StatelessWidget {
  const _Step2PaymentMethod({
    required this.newPlanType,
    required this.selected,
    required this.onChanged,
  });

  final MembershipPlanType? newPlanType;
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  bool get _isPayt =>
      newPlanType == MembershipPlanType.payAsYouTrainAdult ||
      newPlanType == MembershipPlanType.payAsYouTrainJunior;

  bool get _isTrial => newPlanType == MembershipPlanType.trial;

  @override
  Widget build(BuildContext context) {
    if (_isTrial || _isPayt) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: _InfoBox(
          _isTrial
              ? 'Converting to a free trial — no payment required.'
              : 'Converting to Pay As You Train — payment is recorded per session.',
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
    required this.oldPlanType,
    required this.newPlanType,
    required this.paymentMethod,
  });

  final MembershipPlanType oldPlanType;
  final MembershipPlanType? newPlanType;
  final PaymentMethod paymentMethod;

  @override
  Widget build(BuildContext context) {
    final method = switch (paymentMethod) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.card => 'Card',
      PaymentMethod.bankTransfer => 'Bank Transfer',
      PaymentMethod.none => 'No payment',
      _ => '—',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Confirm plan conversion',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'The current membership will be cancelled and a new one created immediately.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                _ConfirmRow('From', _planLabel(oldPlanType)),
                _ConfirmRow('To', _planLabel(newPlanType)),
                _ConfirmRow('Payment', method),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _planLabel(MembershipPlanType? p) => switch (p) {
    MembershipPlanType.trial => 'Free Trial',
    MembershipPlanType.monthlyAdult => 'Monthly Adult',
    MembershipPlanType.monthlyJunior => 'Monthly Junior',
    MembershipPlanType.annualAdult => 'Annual Adult',
    MembershipPlanType.annualJunior => 'Annual Junior',
    MembershipPlanType.familyMonthly => 'Family Monthly',
    MembershipPlanType.payAsYouTrainAdult => 'Pay As You Train (Adult)',
    MembershipPlanType.payAsYouTrainJunior => 'Pay As You Train (Junior)',
    null => '—',
  };
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow(this.label, this.value);

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

// ── Info box ───────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
