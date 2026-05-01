import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/payments_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/cash_payment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/payt_session.dart';
import '../../../domain/entities/profile.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

enum _DateRange { thisMonth, lastMonth, quarter, thisYear }

String _dateRangeLabel(_DateRange r) => switch (r) {
  _DateRange.thisMonth => 'This month',
  _DateRange.lastMonth => 'Last month',
  _DateRange.quarter => 'Quarter',
  _DateRange.thisYear => 'This year',
};

String _methodLabel(PaymentMethod m) => switch (m) {
  PaymentMethod.cash => 'Cash',
  PaymentMethod.card => 'Card',
  PaymentMethod.bankTransfer => 'Bank transfer',
  PaymentMethod.stripe => 'Stripe',
  PaymentMethod.writtenOff => 'Written off',
  PaymentMethod.none => '—',
};

String _typeLabel(PaymentType t) => switch (t) {
  PaymentType.membership => 'Membership',
  PaymentType.payt => 'PAYT',
  PaymentType.other => 'Other',
};

String _escapeCsv(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

// ── Screen ───────────────────────────────────────────────────────────────────

class FinancialReportScreen extends ConsumerStatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  ConsumerState<FinancialReportScreen> createState() =>
      _FinancialReportScreenState();
}

class _FinancialReportScreenState extends ConsumerState<FinancialReportScreen> {
  _DateRange _range = _DateRange.thisMonth;
  PaymentMethod? _methodFilter;

  DateTimeRange _bounds() {
    final now = DateTime.now();
    return switch (_range) {
      _DateRange.thisMonth => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: now,
      ),
      _DateRange.lastMonth => DateTimeRange(
        start: DateTime(now.year, now.month - 1),
        end: DateTime(now.year, now.month).subtract(const Duration(seconds: 1)),
      ),
      _DateRange.quarter => DateTimeRange(
        start: DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1),
        end: now,
      ),
      _DateRange.thisYear => DateTimeRange(start: DateTime(now.year), end: now),
    };
  }

  String _periodLabel() {
    final now = DateTime.now();
    return switch (_range) {
      _DateRange.thisMonth => DateFormat('MMMM yyyy').format(now),
      _DateRange.lastMonth => DateFormat(
        'MMMM yyyy',
      ).format(DateTime(now.year, now.month - 1)),
      _DateRange.quarter => 'Q${((now.month - 1) ~/ 3) + 1} ${now.year}',
      _DateRange.thisYear => '${now.year}',
    };
  }

  List<CashPayment> _filterPayments(List<CashPayment> all) {
    final range = _bounds();
    return all.where((p) {
      if (p.recordedAt.isBefore(range.start) ||
          p.recordedAt.isAfter(range.end)) {
        return false;
      }
      if (_methodFilter != null && p.paymentMethod != _methodFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cashAsync = ref.watch(allCashPaymentsProvider);
    final paytAsync = ref.watch(allPaytSessionsProvider);
    final profilesAsync = ref.watch(profileListProvider);

    if (cashAsync is AsyncLoading || paytAsync is AsyncLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Financial Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final allPayments = cashAsync.asData?.value ?? [];
    final allSessions = paytAsync.asData?.value ?? [];
    final profiles = profilesAsync.asData?.value ?? [];
    final profileMap = {for (final p in profiles) p.id: p};

    final payments = _filterPayments(allPayments);
    final membershipPayments = payments
        .where((p) => p.paymentType == PaymentType.membership)
        .toList();
    final paytPayments = payments
        .where((p) => p.paymentType == PaymentType.payt)
        .toList();

    final totalCollected = payments.fold(0.0, (s, p) => s + p.amount);
    final membershipTotal = membershipPayments.fold(
      0.0,
      (s, p) => s + p.amount,
    );
    final paytTotal = paytPayments.fold(0.0, (s, p) => s + p.amount);

    final allPending = allSessions.where((s) => s.isPending).toList();
    final allWrittenOff = allSessions.where((s) => s.isWrittenOff).toList();
    final pendingBalance = allPending.fold(0.0, (s, p) => s + p.amount);
    final writtenOffTotal = allWrittenOff.fold(0.0, (s, p) => s + p.amount);

    final methodTotals = <PaymentMethod, double>{};
    for (final p in payments) {
      if (p.paymentMethod != PaymentMethod.writtenOff &&
          p.paymentMethod != PaymentMethod.none) {
        methodTotals[p.paymentMethod] =
            (methodTotals[p.paymentMethod] ?? 0) + p.amount;
      }
    }

    final outstanding = [...allPending]
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Report'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Export CSV'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () => _exportCsv(allPayments, allSessions),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FilterBar(
            selectedRange: _range,
            selectedMethod: _methodFilter,
            onRangeChanged: (r) => setState(() => _range = r),
            onMethodChanged: (m) => setState(() => _methodFilter = m),
          ),
          const SizedBox(height: 14),
          Text(
            _periodLabel(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 116,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _SummaryCard(
                  label: 'Total collected',
                  amount: totalCollected,
                  subtitle: '${payments.length} payments',
                  isDark: true,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: 'Memberships',
                  amount: membershipTotal,
                  subtitle: '${membershipPayments.length} payments',
                  accentColor: AppColors.info,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: 'PAYT',
                  amount: paytTotal,
                  subtitle: '${paytPayments.length} payments',
                  accentColor: AppColors.success,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: 'Pending',
                  amount: pendingBalance,
                  subtitle: '${allPending.length} sessions',
                  accentColor: AppColors.warning,
                  borderColor: AppColors.warning,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: 'Written off',
                  amount: writtenOffTotal,
                  subtitle: '${allWrittenOff.length} sessions',
                  accentColor: AppColors.textSecondary,
                  borderColor: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MonthlyRevenueChart(
            allPayments: allPayments,
            allSessions: allSessions,
          ),
          const SizedBox(height: 16),
          if (methodTotals.isNotEmpty) ...[
            _MethodMixChart(
              methodTotals: methodTotals,
              totalCollected: totalCollected,
            ),
            const SizedBox(height: 16),
          ],
          if (payments.isNotEmpty) ...[
            _PlanTypeBreakdown(payments: payments),
            const SizedBox(height: 16),
          ],
          if (outstanding.isNotEmpty)
            _OutstandingSection(
              sessions: outstanding.take(7).toList(),
              profileMap: profileMap,
              onMarkPaid: (profileId) {
                final route = RouteNames.adminPaymentsBulkResolve.replaceFirst(
                  ':profileId',
                  profileId,
                );
                context.push(route);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _exportCsv(
    List<CashPayment> cashPayments,
    List<PaytSession> paytSessions,
  ) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();
    final rows = <String>[
      'Date,Type,Amount,Method,Profile ID,Membership ID,PAYT Session ID,Notes',
    ];

    for (final p in cashPayments) {
      rows.add(
        [
          dateFormat.format(p.recordedAt),
          _typeLabel(p.paymentType),
          p.amount.toStringAsFixed(2),
          _methodLabel(p.paymentMethod),
          p.profileId,
          p.membershipId ?? '',
          p.paytSessionId ?? '',
          _escapeCsv(p.notes ?? ''),
        ].join(','),
      );
    }

    for (final s in paytSessions.where((s) => s.isPending)) {
      rows.add(
        [
          DateFormat('yyyy-MM-dd').format(s.sessionDate),
          'PAYT (pending)',
          s.amount.toStringAsFixed(2),
          '—',
          s.profileId,
          '',
          s.id,
          _escapeCsv(s.notes ?? ''),
        ].join(','),
      );
    }

    final csv = rows.join('\n');
    final fileName =
        'ichiban-payments-${DateFormat('yyyy-MM').format(now)}.csv';

    await SharePlus.instance.share(ShareParams(text: csv, subject: fileName));
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedRange,
    required this.selectedMethod,
    required this.onRangeChanged,
    required this.onMethodChanged,
  });

  final _DateRange selectedRange;
  final PaymentMethod? selectedMethod;
  final ValueChanged<_DateRange> onRangeChanged;
  final ValueChanged<PaymentMethod?> onMethodChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ChipDropdown(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_DateRange>(
              value: selectedRange,
              isDense: true,
              style: _dropdownStyle(context),
              onChanged: (v) {
                if (v != null) onRangeChanged(v);
              },
              items: _DateRange.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(_dateRangeLabel(r)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        _ChipDropdown(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PaymentMethod?>(
              value: selectedMethod,
              isDense: true,
              style: _dropdownStyle(context),
              onChanged: onMethodChanged,
              items: [
                const DropdownMenuItem<PaymentMethod?>(
                  value: null,
                  child: Text('All methods'),
                ),
                ...PaymentMethod.values
                    .where((m) => m != PaymentMethod.none)
                    .map(
                      (m) => DropdownMenuItem<PaymentMethod?>(
                        value: m,
                        child: Text(_methodLabel(m)),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _dropdownStyle(BuildContext context) =>
      (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
        color: AppColors.textPrimary,
        fontSize: 12,
      );
}

class _ChipDropdown extends StatelessWidget {
  const _ChipDropdown({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: child,
    );
  }
}

// ── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.subtitle,
    this.accentColor,
    this.borderColor,
    this.isDark = false,
  });

  final String label;
  final double amount;
  final String subtitle;
  final Color? accentColor;
  final Color? borderColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final effective = accentColor ?? AppColors.textPrimary;
    final bg = isDark ? AppColors.primary : AppColors.surface;
    final border = borderColor != null
        ? Border.all(color: borderColor!)
        : Border.all(color: AppColors.surfaceVariant);

    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: isDark
                  ? Colors.white.withAlpha(153)
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '£${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : effective,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? Colors.white.withAlpha(127)
                  : effective.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Monthly revenue chart ─────────────────────────────────────────────────────

class _MonthlyRevenueChart extends StatelessWidget {
  const _MonthlyRevenueChart({
    required this.allPayments,
    required this.allSessions,
  });

  final List<CashPayment> allPayments;
  final List<PaytSession> allSessions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final memData = List<double>.filled(12, 0);
    final paytData = List<double>.filled(12, 0);

    for (final p in allPayments) {
      final monthsAgo =
          (now.year - p.recordedAt.year) * 12 +
          (now.month - p.recordedAt.month);
      if (monthsAgo >= 0 && monthsAgo < 12) {
        final idx = 11 - monthsAgo;
        if (p.paymentType == PaymentType.membership) {
          memData[idx] += p.amount;
        } else {
          paytData[idx] += p.amount;
        }
      }
    }

    for (final s in allSessions.where((s) => s.isPaid)) {
      final dt = s.paidAt ?? s.sessionDate;
      final monthsAgo = (now.year - dt.year) * 12 + (now.month - dt.month);
      if (monthsAgo >= 0 && monthsAgo < 12) {
        paytData[11 - monthsAgo] += s.amount;
      }
    }

    double maxY = 0;
    for (int i = 0; i < 12; i++) {
      final total = memData[i] + paytData[i];
      if (total > maxY) maxY = total;
    }
    final ceil = maxY < 1 ? 100.0 : (maxY * 1.25).ceilToDouble();

    final labels = List.generate(12, (i) {
      return DateFormat('MMM').format(DateTime(now.year, now.month - 11 + i));
    });

    final groups = List.generate(12, (i) {
      final mem = memData[i];
      final payt = paytData[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: mem + payt,
            width: i == 11 ? 16 : 13,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            rodStackItems: [
              BarChartRodStackItem(0, payt, AppColors.success.withAlpha(200)),
              BarChartRodStackItem(payt, payt + mem, AppColors.primary),
            ],
            color: AppColors.primary,
          ),
        ],
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly revenue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Last 12 months · membership + PAYT',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _LegendItem(color: AppColors.primary, label: 'Membership'),
                    const SizedBox(width: 12),
                    _LegendItem(color: AppColors.success, label: 'PAYT'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: groups,
                  maxY: ceil,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ceil / 4,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.surfaceVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= 12) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: 9,
                                color: i == 11
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                                fontWeight: i == 11
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primary,
                      getTooltipItem: (group, p1, rod, p2) {
                        final i = group.x;
                        final total = memData[i] + paytData[i];
                        return BarTooltipItem(
                          '${labels[i]}\n£${total.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Method mix donut ──────────────────────────────────────────────────────────

class _MethodMixChart extends StatelessWidget {
  const _MethodMixChart({
    required this.methodTotals,
    required this.totalCollected,
  });

  final Map<PaymentMethod, double> methodTotals;
  final double totalCollected;

  static const _colors = {
    PaymentMethod.cash: AppColors.success,
    PaymentMethod.card: AppColors.info,
    PaymentMethod.bankTransfer: AppColors.textSecondary,
    PaymentMethod.stripe: AppColors.accent,
  };

  @override
  Widget build(BuildContext context) {
    final nonZero = methodTotals.entries.where((e) => e.value > 0).toList();
    if (nonZero.isEmpty) return const SizedBox.shrink();

    final sections = nonZero
        .map(
          (e) => PieChartSectionData(
            value: e.value,
            color: _colors[e.key] ?? AppColors.textSecondary,
            radius: 52,
            showTitle: false,
          ),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Method mix',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '£${totalCollected.toStringAsFixed(2)} collected',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 148,
                  height: 148,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '£${totalCollected.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'total',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: nonZero.map((e) {
                      final pct = totalCollected > 0
                          ? (e.value / totalCollected * 100).round()
                          : 0;
                      final color = _colors[e.key] ?? AppColors.textSecondary;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _methodLabel(e.key),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '£${e.value.toStringAsFixed(0)} · $pct%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan type breakdown ───────────────────────────────────────────────────────

class _PlanTypeBreakdown extends StatelessWidget {
  const _PlanTypeBreakdown({required this.payments});

  final List<CashPayment> payments;

  static const _typeColors = {
    PaymentType.membership: AppColors.primary,
    PaymentType.payt: AppColors.success,
    PaymentType.other: AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    final byType = <PaymentType, double>{};
    for (final p in payments) {
      if (p.paymentMethod != PaymentMethod.writtenOff) {
        byType[p.paymentType] = (byType[p.paymentType] ?? 0) + p.amount;
      }
    }
    if (byType.isEmpty) return const SizedBox.shrink();

    final maxAmount = byType.values.fold(0.0, (m, v) => v > m ? v : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Breakdown by type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...byType.entries.map((e) {
              final frac = maxAmount > 0 ? e.value / maxAmount : 0.0;
              final color = _typeColors[e.key] ?? AppColors.textSecondary;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        _typeLabel(e.key),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: frac.clamp(0.0, 1.0),
                          minHeight: 20,
                          backgroundColor: AppColors.surfaceVariant,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 68,
                      child: Text(
                        '£${e.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Outstanding section ───────────────────────────────────────────────────────

class _OutstandingSection extends StatelessWidget {
  const _OutstandingSection({
    required this.sessions,
    required this.profileMap,
    required this.onMarkPaid,
  });

  final List<PaytSession> sessions;
  final Map<String, Profile> profileMap;
  final ValueChanged<String> onMarkPaid;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outstanding · needs attention',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${sessions.length} oldest pending PAYT session'
                  '${sessions.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            ...sessions.map((s) {
              final profile = profileMap[s.profileId];
              final name = profile != null
                  ? '${profile.firstName} ${profile.lastName}'.trim()
                  : 'Member';
              final daysAgo = DateTime.now().difference(s.sessionDate).inDays;
              final ageColor = daysAgo > 14
                  ? AppColors.error
                  : daysAgo > 7
                  ? AppColors.warning
                  : AppColors.textSecondary;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PAYT · ${DateFormat('d MMM').format(s.sessionDate)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _PaytBadge(),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${daysAgo}d',
                            style: TextStyle(
                              fontSize: 11,
                              color: ageColor,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 52,
                          child: Text(
                            '£${s.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => onMarkPaid(s.profileId),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('Mark paid'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PaytBadge extends StatelessWidget {
  const _PaytBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(30),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'PAYT',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.success,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Legend item ───────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
