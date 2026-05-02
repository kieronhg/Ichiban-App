import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/student_auth_provider.dart';
import '../../../core/providers/student_portal_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/membership.dart';
import 'student_portal_drawer.dart';

final _dateFormat = DateFormat('d MMMM yyyy');

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
              );
            }
            return _MembershipCard(membership: membership);
          },
        ),
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.membership});
  final Membership membership;

  @override
  Widget build(BuildContext context) {
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
                    'Cancelled on',
                    _dateFormat.format(membership.cancelledAt!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'To change your membership plan or cancel, please speak to the dojo team.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  static (String label, Color color) _statusDisplay(MembershipStatus s) =>
      switch (s) {
        MembershipStatus.trial => ('Trial', AppColors.warning),
        MembershipStatus.active => ('Active', AppColors.success),
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

class _NoMembershipCard extends StatelessWidget {
  const _NoMembershipCard({this.registrationStatus});
  final RegistrationStatus? registrationStatus;

  @override
  Widget build(BuildContext context) {
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
                  : 'You do not have an active membership. Please contact the dojo '
                        'team to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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
            width: 120,
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
