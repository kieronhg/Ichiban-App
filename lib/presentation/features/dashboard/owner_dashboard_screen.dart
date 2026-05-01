import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/dashboard_providers.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_drawer.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(memberMetricsProvider);
    final financial = ref.watch(financialMetricsProvider);
    final alerts = ref.watch(ownerAlertFlagsProvider);

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Quick actions',
            onSelected: (route) => context.pushNamed(route),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'createProfile', child: Text('Add member')),
              PopupMenuItem(
                value: 'recordPayment',
                child: Text('Record payment'),
              ),
              PopupMenuItem(
                value: 'createAttendanceSession',
                child: Text('Create session'),
              ),
              PopupMenuItem(
                value: 'sendAnnouncement',
                child: Text('Send announcement'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activityFeedProvider);
          ref.invalidate(membershipGrowthChartProvider);
          ref.invalidate(attendanceTrendChartProvider);
          ref.invalidate(gradingPassRateChartProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Alert flags ───────────────────────────────────────────────
            if (alerts.isNotEmpty) ...[
              _AlertsCard(alerts: alerts),
              const SizedBox(height: 16),
            ],

            // ── Member metrics ────────────────────────────────────────────
            _SectionLabel(label: 'Members'),
            const SizedBox(height: 8),
            _MetricsGrid(
              children: [
                _MetricTile(
                  label: 'Active',
                  value: '${metrics.activeCount}',
                  icon: Icons.people_outline,
                  color: AppColors.success,
                ),
                _MetricTile(
                  label: 'Trial',
                  value: '${metrics.trialCount}',
                  icon: Icons.timer_outlined,
                  color: AppColors.info,
                ),
                _MetricTile(
                  label: 'Lapsed',
                  value: '${metrics.lapsedCount}',
                  icon: Icons.person_off_outlined,
                  color: AppColors.error,
                ),
                _MetricTile(
                  label: 'New this month',
                  value: '${metrics.newThisMonth}',
                  icon: Icons.person_add_outlined,
                  color: AppColors.accent,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Financial metrics ─────────────────────────────────────────
            _SectionLabel(label: 'Finances'),
            const SizedBox(height: 8),
            _MetricsGrid(
              children: [
                _MetricTile(
                  label: 'PAYT outstanding',
                  value: '£${financial.paytOutstanding.toStringAsFixed(2)}',
                  icon: Icons.warning_amber_outlined,
                  color: AppColors.warning,
                ),
                _MetricTile(
                  label: 'Cash this month',
                  value:
                      '£${financial.cashReceivedThisMonth.toStringAsFixed(2)}',
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Charts ────────────────────────────────────────────────────
            _SectionLabel(label: 'Trends'),
            const SizedBox(height: 8),
            const _MembershipGrowthChart(),
            const SizedBox(height: 16),
            const _AttendanceTrendChart(),
            const SizedBox(height: 16),
            const _GradingPassRateChart(),

            const SizedBox(height: 20),

            // ── Activity feed ─────────────────────────────────────────────
            _SectionLabel(label: 'Recent activity'),
            const SizedBox(height: 8),
            const _ActivityFeed(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Alerts card ──────────────────────────────────────────────────────────────

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});

  final List<DashboardAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.error.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  '${alerts.length} alert${alerts.length == 1 ? '' : 's'} require attention',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alerts.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      a.severity == AlertSeverity.error
                          ? Icons.error_outline
                          : Icons.warning_amber_outlined,
                      size: 16,
                      color: a.severity == AlertSeverity.error
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.message,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Metrics grid ─────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Membership growth chart ───────────────────────────────────────────────────

class _MembershipGrowthChart extends ConsumerWidget {
  const _MembershipGrowthChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(membershipGrowthChartProvider);
    return _ChartCard(
      title: 'Membership growth (6 months)',
      child: dataAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => const Center(child: Text('Could not load chart')),
        data: (points) {
          if (points.isEmpty) {
            return const Center(child: Text('No data yet'));
          }
          final maxY =
              points
                  .map((p) => p.y)
                  .reduce((a, b) => a > b ? a : b)
                  .ceilToDouble() +
              2;
          return LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final now = DateTime.now();
                      final month = DateTime(
                        now.year,
                        now.month - (5 - v.toInt()),
                      );
                      return Text(
                        DateFormat('MMM').format(month),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: points
                      .map((p) => FlSpot(p.x.toDouble(), p.y))
                      .toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Attendance trend chart ────────────────────────────────────────────────────

class _AttendanceTrendChart extends ConsumerWidget {
  const _AttendanceTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(attendanceTrendChartProvider);
    return _ChartCard(
      title: 'Attendance (last 4 weeks)',
      child: dataAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => const Center(child: Text('Could not load chart')),
        data: (points) {
          if (points.isEmpty) {
            return const Center(child: Text('No sessions yet'));
          }
          final maxY =
              points
                  .map((p) => p.y)
                  .reduce((a, b) => a > b ? a : b)
                  .ceilToDouble() +
              2;
          final now = DateTime.now();
          return BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final weekStart = now.subtract(
                        Duration(days: 28 - (v.toInt() * 7)),
                      );
                      return Text(
                        'W${DateFormat('d/M').format(weekStart)}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: points
                  .map(
                    (p) => BarChartGroupData(
                      x: p.x,
                      barRods: [
                        BarChartRodData(
                          toY: p.y,
                          color: AppColors.accent,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

// ── Grading pass rate chart ───────────────────────────────────────────────────

class _GradingPassRateChart extends ConsumerWidget {
  const _GradingPassRateChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(gradingPassRateChartProvider);
    return _ChartCard(
      title: 'Grading outcomes (90 days)',
      child: dataAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => const Center(child: Text('Could not load chart')),
        data: (points) {
          if (points.isEmpty) {
            return const Center(child: Text('No grading results recorded yet'));
          }
          final labels = ['Promoted', 'Failed', 'Absent'];
          final colors = [
            AppColors.success,
            AppColors.error,
            AppColors.warning,
          ];
          return Row(
            children: [
              Expanded(
                child: BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Text(
                            labels[v.toInt()],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barGroups: points
                        .map(
                          (p) => BarChartGroupData(
                            x: p.x,
                            barRods: [
                              BarChartRodData(
                                toY: p.y,
                                color: colors[p.x],
                                width: 28,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Chart card wrapper ────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 160, child: child),
          ],
        ),
      ),
    );
  }
}

// ── Activity feed ─────────────────────────────────────────────────────────────

class _ActivityFeed extends ConsumerWidget {
  const _ActivityFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(activityFeedProvider);
    return feedAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => const Center(child: Text('Could not load activity')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No recent activity',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.surfaceVariant),
          ),
          child: Column(
            children: items.map((item) => _ActivityTile(item: item)).toList(),
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(item.icon, size: 20, color: AppColors.primary),
      title: Text(item.title, style: const TextStyle(fontSize: 13)),
      subtitle: item.subtitle != null
          ? Text(item.subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: Text(
        _formatTimestamp(item.timestamp),
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}
