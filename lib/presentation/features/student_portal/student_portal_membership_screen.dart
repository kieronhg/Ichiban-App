import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart'
    hide Card, PaymentMethod, BillingDetails;
import 'package:intl/intl.dart';

import '../../../core/providers/student_auth_provider.dart';
import '../../../core/providers/student_portal_providers.dart';
import '../../../core/services/stripe_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/membership.dart';
import 'student_portal_drawer.dart';

final _dateFormat = DateFormat('d MMMM yyyy');

// Plan types eligible for student self-service Stripe subscription.
const _stripeEligiblePlans = {
  MembershipPlanType.monthlyAdult,
  MembershipPlanType.monthlyJunior,
  MembershipPlanType.annualAdult,
  MembershipPlanType.annualJunior,
};

class StudentPortalMembershipScreen extends ConsumerWidget {
  const StudentPortalMembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(studentPortalMembershipProvider);
    final profile = ref.watch(currentStudentProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Membership')),
      drawer: const StudentPortalDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: membershipAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text(
            'Could not load membership. Please try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          data: (membership) {
            if (membership == null) {
              return _NoMembershipCard(
                registrationStatus: profile?.registrationStatus,
                profileId: profile?.id,
                profileEmail: profile?.email,
              );
            }
            return _MembershipCard(
              membership: membership,
              profileId: profile?.id ?? '',
              profileEmail: profile?.email ?? '',
            );
          },
        ),
      ),
    );
  }
}

// ── Active membership card ───────────────────────────────────────────��──────

class _MembershipCard extends ConsumerWidget {
  const _MembershipCard({
    required this.membership,
    required this.profileId,
    required this.profileEmail,
  });

  final Membership membership;
  final String profileId;
  final String profileEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final (label, color) = _statusDisplay(membership.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _planLabel(membership.planType),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusBadge(label: label, color: color),
                  ],
                ),
                const SizedBox(height: 20),
                if (membership.trialStartDate != null)
                  _DetailRow(
                    'Trial started',
                    _dateFormat.format(membership.trialStartDate!),
                  ),
                if (membership.trialEndDate != null)
                  _DetailRow(
                    'Trial ends',
                    _dateFormat.format(membership.trialEndDate!),
                  ),
                if (membership.membershipStartDate != null)
                  _DetailRow(
                    'Member since',
                    _dateFormat.format(membership.membershipStartDate!),
                  ),
                if (membership.subscriptionRenewalDate != null)
                  _DetailRow(
                    'Next renewal',
                    _dateFormat.format(membership.subscriptionRenewalDate!),
                  ),
                if (membership.cancelledAt != null)
                  _DetailRow(
                    'Cancels on',
                    _dateFormat.format(
                      membership.subscriptionRenewalDate ??
                          membership.cancelledAt!,
                    ),
                  ),
                if (membership.gracePeriodEnd != null)
                  _DetailRow(
                    'Grace period ends',
                    _dateFormat.format(membership.gracePeriodEnd!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Grace period warning banner
        if (membership.status == MembershipStatus.gracePeriod)
          _WarningBanner(
            message:
                'Your last payment failed. Please update your payment details '
                'before ${membership.gracePeriodEnd != null ? _dateFormat.format(membership.gracePeriodEnd!) : 'your grace period ends'} '
                'to keep your membership active.',
          ),

        // Pending downgrade notice
        if (membership.pendingDowngradePlanId != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Your downgrade request is awaiting admin approval.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.info,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // Action buttons
        _MembershipActions(
          membership: membership,
          profileId: profileId,
          profileEmail: profileEmail,
        ),
      ],
    );
  }

  static (String label, Color color) _statusDisplay(MembershipStatus s) =>
      switch (s) {
        MembershipStatus.trial => ('Trial', AppColors.warning),
        MembershipStatus.active => ('Active', AppColors.success),
        MembershipStatus.gracePeriod => ('Grace Period', AppColors.warning),
        MembershipStatus.lapsed => ('Lapsed', AppColors.error),
        MembershipStatus.cancelled => ('Cancelled', AppColors.textSecondary),
        MembershipStatus.expired => ('Expired', AppColors.textSecondary),
        MembershipStatus.payt => ('Pay As You Train', AppColors.info),
      };

  static String _planLabel(MembershipPlanType t) => switch (t) {
    MembershipPlanType.monthlyAdult => 'Monthly (Adult)',
    MembershipPlanType.monthlyJunior => 'Monthly (Junior)',
    MembershipPlanType.annualAdult => 'Annual (Adult)',
    MembershipPlanType.annualJunior => 'Annual (Junior)',
    MembershipPlanType.familyMonthly => 'Family Monthly',
    MembershipPlanType.payAsYouTrainAdult => 'Pay As You Train',
    MembershipPlanType.payAsYouTrainJunior => 'Pay As You Train (Junior)',
    MembershipPlanType.trial => 'Free Trial',
  };
}

// ── Action buttons ──────────────────────────────────────────────────────────

class _MembershipActions extends ConsumerWidget {
  const _MembershipActions({
    required this.membership,
    required this.profileId,
    required this.profileEmail,
  });

  final Membership membership;
  final String profileId;
  final String profileEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = membership.status;
    final isStripe = membership.paymentMethod == PaymentMethod.stripe;

    if (status == MembershipStatus.trial ||
        status == MembershipStatus.lapsed ||
        status == MembershipStatus.expired) {
      return _PrimaryButton(
        label: 'Choose a Plan',
        onTap: () => _showPlanSheet(context, ref, isUpgrade: false),
      );
    }

    if (status == MembershipStatus.gracePeriod) {
      return _PrimaryButton(
        label: 'Update Payment Details',
        onTap: () => _showUpdatePaymentDetails(context),
      );
    }

    if (status == MembershipStatus.active && isStripe) {
      final hasPendingDowngrade = membership.pendingDowngradePlanId != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hasPendingDowngrade)
            _PrimaryButton(
              label: 'Upgrade Plan',
              onTap: () => _showPlanSheet(context, ref, isUpgrade: true),
            ),
          if (!hasPendingDowngrade) const SizedBox(height: 8),
          _OutlineButton(
            label: 'Cancel Membership',
            color: AppColors.error,
            onTap: () => _showCancelDialog(context, ref),
          ),
        ],
      );
    }

    // Cash / non-Stripe active memberships — direct to dojo
    if (status == MembershipStatus.active) {
      return _InfoNote(
        'To change or cancel your membership, please speak to the dojo team.',
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _showPlanSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool isUpgrade,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlanSelectionSheet(
        currentPlanType: membership.planType,
        profileId: profileId,
        profileEmail: profileEmail,
        isUpgrade: isUpgrade,
        onPlanSelected: (planKey, isDowngrade) async {
          Navigator.of(context).pop();
          if (isDowngrade) {
            await _requestDowngrade(context, ref, planKey);
          } else {
            await _initiatePayment(context, ref, planKey);
          }
        },
      ),
    );
  }

  Future<void> _initiatePayment(
    BuildContext context,
    WidgetRef ref,
    String planKey,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final String clientSecret;
      if (membership.status == MembershipStatus.trial ||
          membership.status == MembershipStatus.lapsed ||
          membership.status == MembershipStatus.expired) {
        clientSecret = await StripeService.createSubscription(
          profileId: profileId,
          planKey: planKey,
        );
      } else {
        final secret = await StripeService.upgradeSubscription(
          profileId: profileId,
          newPlanKey: planKey,
        );
        if (secret == null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Plan upgraded — no immediate charge required.'),
            ),
          );
          ref.invalidate(studentPortalMembershipProvider);
          return;
        }
        clientSecret = secret;
      }

      final confirmed = await StripeService.presentPaymentSheet(
        clientSecret: clientSecret,
        customerEmail: profileEmail,
      );

      if (confirmed) {
        ref.invalidate(studentPortalMembershipProvider);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Payment confirmed — membership updated.'),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not start payment: ${e.message}')),
      );
    } on StripeException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.error.localizedMessage}')),
      );
    }
  }

  Future<void> _requestDowngrade(
    BuildContext context,
    WidgetRef ref,
    String planKey,
  ) async {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Downgrade request sent'),
        content: const Text(
          'Your request has been sent to the dojo team. '
          'They will review it and apply the change at your next renewal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdatePaymentDetails(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please contact the dojo team to update your payment details.',
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final renewalDate = membership.subscriptionRenewalDate;
    final dateStr = renewalDate != null
        ? _dateFormat.format(renewalDate)
        : 'the end of your current billing period';

    await showDialog<void>(
      context: context,
      builder: (ctx) => _CancelConfirmDialog(
        activeUntil: dateStr,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await _confirmCancel(context, ref);
        },
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await StripeService.cancelSubscriptionAtPeriodEnd(profileId);
      ref.invalidate(studentPortalMembershipProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Membership cancelled — active until renewal date.'),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not cancel membership: ${e.message}')),
      );
    }
  }
}

// ── Cancel confirm dialog ───────────────────────────────────────────────────

class _CancelConfirmDialog extends StatelessWidget {
  const _CancelConfirmDialog({
    required this.activeUntil,
    required this.onConfirm,
  });

  final String activeUntil;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel membership?'),
      content: Text(
        'Your membership will remain active until $activeUntil. '
        'After that it will not renew.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep membership'),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Yes, cancel'),
        ),
      ],
    );
  }
}

// ── Plan selection bottom sheet ─────────────────────────────────────────────

class _PlanSelectionSheet extends ConsumerWidget {
  const _PlanSelectionSheet({
    required this.currentPlanType,
    required this.profileId,
    required this.profileEmail,
    required this.isUpgrade,
    required this.onPlanSelected,
  });

  final MembershipPlanType currentPlanType;
  final String profileId;
  final String profileEmail;
  final bool isUpgrade;
  final void Function(String planKey, bool isDowngrade) onPlanSelected;

  static const _planOrder = [
    MembershipPlanType.monthlyJunior,
    MembershipPlanType.monthlyAdult,
    MembershipPlanType.annualJunior,
    MembershipPlanType.annualAdult,
    MembershipPlanType.familyMonthly,
  ];

  static String _planLabel(MembershipPlanType t) => switch (t) {
    MembershipPlanType.monthlyAdult => 'Monthly Adult',
    MembershipPlanType.monthlyJunior => 'Monthly Junior',
    MembershipPlanType.annualAdult => 'Annual Adult',
    MembershipPlanType.annualJunior => 'Annual Junior',
    MembershipPlanType.familyMonthly => 'Family Monthly',
    MembershipPlanType.payAsYouTrainAdult => 'Pay As You Train (Adult)',
    MembershipPlanType.payAsYouTrainJunior => 'Pay As You Train (Junior)',
    MembershipPlanType.trial => 'Free Trial',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricingAsync = ref.watch(membershipPricingAllProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isUpgrade ? 'Upgrade your plan' : 'Choose a plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'All plans include full access to your enrolled disciplines.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pricingAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => const Center(
                  child: Text('Could not load plans. Please try again.'),
                ),
                data: (pricingList) {
                  final pricingMap = {for (final p in pricingList) p.key: p};
                  return ListView.separated(
                    controller: controller,
                    itemCount: _planOrder.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final planType = _planOrder[i];
                      if (!_stripeEligiblePlans.contains(planType)) {
                        return const SizedBox.shrink();
                      }
                      final pricing = pricingMap[planType.name];
                      final isCurrent = planType == currentPlanType;
                      final priceStr = pricing != null
                          ? '£${pricing.amount.toStringAsFixed(2)}/mo'
                          : '—';

                      return _PlanTile(
                        label: _planLabel(planType),
                        priceStr: priceStr,
                        isCurrent: isCurrent,
                        onTap: isCurrent
                            ? null
                            : () {
                                final planIndex = _planOrder.indexOf(planType);
                                final currentIndex = _planOrder.indexOf(
                                  currentPlanType,
                                );
                                final isDowngrade =
                                    planIndex < currentIndex && isUpgrade;
                                onPlanSelected(planType.name, isDowngrade);
                              },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Plan tile ───────────────────────────────────────────────────────────────

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.label,
    required this.priceStr,
    required this.isCurrent,
    required this.onTap,
  });

  final String label;
  final String priceStr;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.surfaceVariant,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onTap == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              priceStr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Current',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── No membership card ──────────────────────────────────────────────────────

class _NoMembershipCard extends ConsumerWidget {
  const _NoMembershipCard({
    this.registrationStatus,
    this.profileId,
    this.profileEmail,
  });

  final RegistrationStatus? registrationStatus;
  final String? profileId;
  final String? profileEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPending =
        registrationStatus == RegistrationStatus.pendingVerification;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.card_membership_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'Account pending' : 'No active membership',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Your account is awaiting activation. The dojo team will set '
                        'up your membership once you have verified your email.'
                  : 'You do not have an active membership.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isPending && profileId != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _showPlanSheet(context, ref),
                  child: const Text('Choose a Plan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showPlanSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlanSelectionSheet(
        currentPlanType: MembershipPlanType.trial,
        profileId: profileId!,
        profileEmail: profileEmail ?? '',
        isUpgrade: false,
        onPlanSelected: (planKey, _) async {
          Navigator.of(context).pop();
          final messenger = ScaffoldMessenger.of(context);
          try {
            final clientSecret = await StripeService.createSubscription(
              profileId: profileId!,
              planKey: planKey,
            );
            final confirmed = await StripeService.presentPaymentSheet(
              clientSecret: clientSecret,
              customerEmail: profileEmail ?? '',
            );
            if (confirmed) {
              ref.invalidate(studentPortalMembershipProvider);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Payment confirmed — membership activated.'),
                ),
              );
            }
          } on FirebaseFunctionsException catch (e) {
            messenger.showSnackBar(
              SnackBar(content: Text('Could not start payment: ${e.message}')),
            );
          } on StripeException catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Payment failed: ${e.error.localizedMessage}'),
              ),
            );
          }
        },
      ),
    );
  }
}

// ── Warning banner ──────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info note ───────────────────────────────────────────────────────────────

class _InfoNote extends StatelessWidget {
  const _InfoNote(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Button helpers ──────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onTap, child: Text(label)),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label),
      ),
    );
  }
}

// ── Status badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Detail row ──────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
