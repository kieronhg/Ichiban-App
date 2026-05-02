import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/student_auth_provider.dart';
import '../../../core/providers/student_portal_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/notification_log.dart';
import '../../../domain/entities/rank.dart';
import 'student_portal_drawer.dart';

final _dateFormat = DateFormat('d MMMM yyyy');
final _timeFormat = DateFormat('d MMM · HH:mm');

class StudentPortalHomeScreen extends ConsumerWidget {
  const StudentPortalHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentStudentProfileProvider);
    final membershipAsync = ref.watch(studentPortalMembershipProvider);
    final enrollmentsAsync = ref.watch(studentPortalEnrollmentsProvider);
    final notificationsAsync = ref.watch(studentPortalNotificationsProvider);
    final theme = Theme.of(context);

    final firstName = profile?.firstName ?? 'Student';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Home')),
      drawer: const StudentPortalDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentPortalMembershipProvider);
          ref.invalidate(studentPortalEnrollmentsProvider);
          ref.invalidate(studentPortalNotificationsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome back, $firstName',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _greeting(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Membership',
                onTap: () => context.go(RouteNames.studentPortalMembership),
              ),
              const SizedBox(height: 8),
              membershipAsync.when(
                loading: () => const _LoadingCard(),
                error: (err, _) =>
                    const _ErrorCard('Could not load membership.'),
                data: (membership) =>
                    _MembershipSummaryCard(membership: membership),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'My Disciplines',
                onTap: () => context.go(RouteNames.studentPortalGrades),
              ),
              const SizedBox(height: 8),
              enrollmentsAsync.when(
                loading: () => const _LoadingCard(),
                error: (err, _) =>
                    const _ErrorCard('Could not load disciplines.'),
                data: (enrollments) {
                  final active = enrollments.where((e) => e.isActive).toList();
                  if (active.isEmpty) {
                    return _EmptyCard(
                      icon: Icons.sports_martial_arts_outlined,
                      message: 'You are not enrolled in any disciplines yet.',
                    );
                  }
                  return Column(
                    children: [
                      for (final e in active)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _EnrollmentSummaryTile(enrollment: e),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Recent Notifications',
                onTap: () => context.go(RouteNames.studentPortalNotifications),
              ),
              const SizedBox(height: 8),
              notificationsAsync.when(
                loading: () => const _LoadingCard(),
                error: (err, _) =>
                    const _ErrorCard('Could not load notifications.'),
                data: (notifications) {
                  final push = notifications
                      .where((n) => n.title != null || n.body != null)
                      .take(3)
                      .toList();
                  if (push.isEmpty) {
                    return _EmptyCard(
                      icon: Icons.notifications_none_outlined,
                      message: 'No notifications yet.',
                    );
                  }
                  return Column(
                    children: [
                      for (final n in push)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _NotificationSummaryTile(log: n),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    return 'Good evening.';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'See all',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MembershipSummaryCard extends StatelessWidget {
  const _MembershipSummaryCard({required this.membership});
  final Membership? membership;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (membership == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.card_membership_outlined,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                'No active membership',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final (label, color) = _statusDisplay(membership!.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _planLabel(membership!.planType),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (membership!.subscriptionRenewalDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Renews ${_dateFormat.format(membership!.subscriptionRenewalDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
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
            ),
          ],
        ),
      ),
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

class _EnrollmentSummaryTile extends ConsumerWidget {
  const _EnrollmentSummaryTile({required this.enrollment});
  final Enrollment enrollment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(
      disciplineProvider(enrollment.disciplineId),
    );
    final ranksAsync = ref.watch(rankListProvider(enrollment.disciplineId));
    final theme = Theme.of(context);

    final disciplineName = disciplineAsync.asData?.value?.name ?? '…';

    Rank? currentRank;
    if (ranksAsync.asData != null && enrollment.currentRankId.isNotEmpty) {
      currentRank = ranksAsync.asData!.value
          .where((r) => r.id == enrollment.currentRankId)
          .firstOrNull;
    }

    final beltColour = _parseBeltColour(currentRank?.colourHex);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: beltColour.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_martial_arts_outlined,
                color: beltColour,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disciplineName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    currentRank != null ? currentRank.name : 'Ungraded',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (currentRank?.colourHex != null)
              Container(
                width: 12,
                height: 24,
                decoration: BoxDecoration(
                  color: beltColour,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _parseBeltColour(String? hex) {
    if (hex == null) return AppColors.textSecondary;
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppColors.textSecondary;
    }
  }
}

class _NotificationSummaryTile extends StatelessWidget {
  const _NotificationSummaryTile({required this.log});
  final NotificationLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = log.isRead != true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnread ? AppColors.accent : Colors.transparent,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (log.title != null)
                    Text(
                      log.title!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: isUnread
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  if (log.body != null)
                    Text(
                      log.body!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeFormat.format(log.sentAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
