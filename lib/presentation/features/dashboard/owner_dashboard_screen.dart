import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/dashboard_providers.dart';
import '../../../core/providers/kiosk_mode_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_drawer.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(currentAdminUserProvider);
    // Derive a first name from the email local part as a friendly fallback
    final emailLocal = adminUser?.email.split('@').first ?? '';
    final firstName = emailLocal.isNotEmpty
        ? emailLocal[0].toUpperCase() + emailLocal.substring(1)
        : 'there';
    final greeting = _greeting(firstName);

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: Text(greeting),
        actions: [
          IconButton(
            icon: const Icon(Icons.tablet_mac_outlined),
            tooltip: 'Activate Kiosk Mode',
            onPressed: () => _showActivateKioskDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activityFeedProvider);
          ref.invalidate(sessionsThisWeekProvider);
          ref.invalidate(upcomingGradingProvider);
          ref.invalidate(membershipGrowthChartProvider);
          ref.invalidate(attendanceTrendChartProvider);
          ref.invalidate(gradingPassRateChartProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DateLabel(date: DateTime.now()),
            const SizedBox(height: 10),

            // ── At-a-glance stat cards ─────────────────────────────────────
            const _StatCardRow(),

            const SizedBox(height: 16),

            // ── Main content: activity feed + right sidebar ────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 600) {
                  return _WideLayout();
                }
                return const _NarrowLayout();
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _greeting(String firstName) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return '$salutation, $firstName';
  }

  Future<void> _showActivateKioskDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isLoading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Activate Kiosk Mode'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kiosk mode locks the app to the student check-in screen. '
                      'Set a 4-digit exit PIN so staff can return to the admin dashboard.',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: pinController,
                      decoration: const InputDecoration(
                        labelText: 'Exit PIN (4 digits)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      validator: (v) {
                        if (v == null || v.length != 4) {
                          return 'PIN must be exactly 4 digits';
                        }
                        if (!RegExp(r'^\d{4}$').hasMatch(v)) {
                          return 'PIN must contain only digits';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isLoading = true);
                          ref
                              .read(kioskModeProvider.notifier)
                              .activate(pinController.text);
                          Navigator.of(dialogContext).pop();
                          context.go(RouteNames.studentSelect);
                        },
                  child: const Text('Activate'),
                ),
              ],
            );
          },
        );
      },
    );

    pinController.dispose();
  }
}

// ── Date label ───────────────────────────────────────────────────────────────

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label = 'At a glance · ${DateFormat('EEEE d MMMM').format(date)}';
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.ink3,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── Stat card row ─────────────────────────────────────────────────────────────

class _StatCardRow extends ConsumerWidget {
  const _StatCardRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(memberMetricsProvider);
    final sessionsAsync = ref.watch(sessionsThisWeekProvider);
    final sessions = sessionsAsync.asData?.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 500;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Active members',
                  value: '${metrics.activeCount}',
                  subtitle: metrics.adultCount > 0 || metrics.juniorCount > 0
                      ? '${metrics.adultCount} adults · ${metrics.juniorCount} juniors'
                      : null,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Trials expiring',
                  value: '${metrics.trialCount}',
                  subtitle: 'Within 7 days',
                  accentColor: metrics.trialCount > 0 ? AppColors.ochre : null,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Memberships lapsed',
                  value: '${metrics.lapsedCount}',
                  subtitle: metrics.lapsedCount > 0
                      ? 'Action needed'
                      : 'All clear',
                  accentColor: metrics.lapsedCount > 0 ? AppColors.error : null,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Sessions this week',
                  value: sessions != null ? '${sessions.sessionCount}' : '—',
                  subtitle: sessions != null
                      ? '${sessions.checkInCount} check-ins'
                      : null,
                  onTap: () {},
                ),
              ),
            ],
          );
        }
        // 2×2 grid on narrow screens
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Active members',
                    value: '${metrics.activeCount}',
                    subtitle: metrics.adultCount > 0 || metrics.juniorCount > 0
                        ? '${metrics.adultCount} adults · ${metrics.juniorCount} juniors'
                        : null,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Trials expiring',
                    value: '${metrics.trialCount}',
                    subtitle: 'Within 7 days',
                    accentColor: metrics.trialCount > 0
                        ? AppColors.ochre
                        : null,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Memberships lapsed',
                    value: '${metrics.lapsedCount}',
                    subtitle: metrics.lapsedCount > 0
                        ? 'Action needed'
                        : 'All clear',
                    accentColor: metrics.lapsedCount > 0
                        ? AppColors.error
                        : null,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Sessions this week',
                    value: sessions != null ? '${sessions.sessionCount}' : '—',
                    subtitle: sessions != null
                        ? '${sessions.checkInCount} check-ins'
                        : null,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.subtitle,
    this.accentColor,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper0,
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: accentColor ?? Colors.transparent,
              width: accentColor != null ? 3 : 0,
            ),
            top: const BorderSide(color: AppColors.hairline),
            right: const BorderSide(color: AppColors.hairline),
            bottom: const BorderSide(color: AppColors.hairline),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w500,
                color: AppColors.ink3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 36,
                height: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 11, color: AppColors.ink3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Wide layout (≥600px) ──────────────────────────────────────────────────────

class _WideLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _ActivityPanel()),
        const SizedBox(width: 14),
        Expanded(child: _Sidebar()),
      ],
    );
  }
}

// ── Narrow layout (<600px) ────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_Sidebar(), const SizedBox(height: 14), _ActivityPanel()],
    );
  }
}

// ── Activity panel ────────────────────────────────────────────────────────────

class _ActivityPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(activityFeedProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper0,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'LAST 10 ACTIONS',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
              TextButton(onPressed: () {}, child: const Text('View all →')),
            ],
          ),
          const SizedBox(height: 8),
          feedAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Could not load activity'),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: AppColors.ink3),
                  ),
                );
              }
              return Column(
                children: items
                    .map((item) => _ActivityRow(item: item))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              _formatTime(item.timestamp),
              style: const TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 10,
                color: AppColors.ink3,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: _dotColor(item.icon),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 13)),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return DateFormat('HH:mm').format(dt);
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM').format(dt);
  }

  Color _dotColor(IconData icon) {
    if (icon == Icons.payments_outlined) return AppColors.tea;
    if (icon == Icons.military_tech_outlined) return AppColors.crimson;
    if (icon == Icons.campaign_outlined) return AppColors.indigo;
    if (icon == Icons.card_membership_outlined) return AppColors.ochre;
    return AppColors.ink3;
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _AttentionPanel(),
        const SizedBox(height: 12),
        _QuickActionsPanel(),
        const SizedBox(height: 12),
        _UpcomingGradingPanel(),
      ],
    );
  }
}

// ── Attention panel ───────────────────────────────────────────────────────────

class _AttentionPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(ownerAlertFlagsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper0,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ATTENTION',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: 10),
          ...alerts.asMap().entries.map((entry) {
            final isLast = entry.key == alerts.length - 1;
            final alert = entry.value;
            final isError = alert.severity == AlertSeverity.error;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isError ? AppColors.crimson : AppColors.ochre,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isError ? '!' : '!',
                        style: const TextStyle(
                          color: AppColors.paper0,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alert.message,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Quick actions panel ───────────────────────────────────────────────────────

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper0,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  label: 'Members',
                  action: 'Add',
                  onTap: () => context.pushNamed('adminProfileCreate'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionTile(
                  label: 'Payment',
                  action: 'Record',
                  onTap: () => context.pushNamed('adminPaymentsRecord'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionTile(
                  label: 'Attendance',
                  action: 'Mark',
                  onTap: () => context.pushNamed('adminAttendanceCreate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.action,
    required this.onTap,
  });

  final String label;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.paper2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                color: AppColors.ink3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upcoming grading panel ────────────────────────────────────────────────────

class _UpcomingGradingPanel extends ConsumerWidget {
  const _UpcomingGradingPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradingAsync = ref.watch(upcomingGradingProvider);

    return gradingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (event) {
        if (event == null) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: AppColors.paper0,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.hairline),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UPCOMING GRADING',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEE dd MMM').format(event.eventDate),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (event.title != null) ...[
                const SizedBox(height: 2),
                Text(
                  event.title!,
                  style: const TextStyle(fontSize: 13, color: AppColors.ink3),
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.pushNamed(
                  'adminGradingDetail',
                  pathParameters: {'eventId': event.id},
                ),
                child: const Text('Review shortlist →'),
              ),
            ],
          ),
        );
      },
    );
  }
}
