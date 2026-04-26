import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/payments_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/cash_payment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/payt_session.dart';

/// Super-admin only: financial summary screen with CSV export.
///
/// Shows total collected by payment type and method, plus pending PAYT
/// outstanding. The full payment log can be exported as CSV.
class FinancialReportScreen extends ConsumerWidget {
  const FinancialReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashAsync = ref.watch(allCashPaymentsProvider);
    final paytAsync = ref.watch(allPaytSessionsProvider);

    final isLoading = cashAsync is AsyncLoading || paytAsync is AsyncLoading;
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Financial Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cashPayments = cashAsync.asData?.value ?? [];
    final paytSessions = paytAsync.asData?.value ?? [];

    final totals = _buildTotals(cashPayments);
    final pendingBalance = paytSessions
        .where((s) => s.isPending)
        .fold(0.0, (sum, s) => sum + s.amount);
    final pendingCount = paytSessions.where((s) => s.isPending).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context, cashPayments, paytSessions),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Total collected ───────────────────────────────────────
          _SummaryCard(
            title: 'Total Collected',
            value:
                '£${cashPayments.fold(0.0, (s, p) => s + p.amount).toStringAsFixed(2)}',
            subtitle: '${cashPayments.length} payment records',
            color: AppColors.success,
          ),
          const SizedBox(height: 12),

          // ── Outstanding balance ───────────────────────────────────
          _SummaryCard(
            title: 'Outstanding (PAYT)',
            value: '£${pendingBalance.toStringAsFixed(2)}',
            subtitle:
                '$pendingCount unpaid session'
                '${pendingCount == 1 ? '' : 's'}',
            color: AppColors.warning,
          ),
          const SizedBox(height: 20),

          // ── Breakdown by payment type ────────────────────────────��
          Text(
            'BY PAYMENT TYPE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...PaymentType.values.map((type) {
            final t = totals.byType[type] ?? _Total.zero;
            return _BreakdownRow(
              label: _typeLabel(type),
              amount: t.amount,
              count: t.count,
            );
          }),
          const SizedBox(height: 20),

          // ── Breakdown by payment method ───────────────────────────
          Text(
            'BY PAYMENT METHOD',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...totals.byMethod.entries
              .where((e) => e.value.count > 0)
              .map(
                (e) => _BreakdownRow(
                  label: _methodLabel(e.key),
                  amount: e.value.amount,
                  count: e.value.count,
                ),
              ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  _Totals _buildTotals(List<CashPayment> payments) {
    final byType = <PaymentType, _Total>{};
    final byMethod = <PaymentMethod, _Total>{};

    for (final p in payments) {
      byType[p.paymentType] = (byType[p.paymentType] ?? _Total.zero).add(
        p.amount,
      );
      byMethod[p.paymentMethod] = (byMethod[p.paymentMethod] ?? _Total.zero)
          .add(p.amount);
    }

    return _Totals(byType: byType, byMethod: byMethod);
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<CashPayment> cashPayments,
    List<PaytSession> paytSessions,
  ) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Build CSV rows
    final rows = <String>[];
    rows.add(
      'Date,Type,Amount,Method,Profile ID,Membership ID,PAYT Session ID,Notes',
    );

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

    // Pending PAYT sessions (not yet in CashPayments)
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
        'ichiban_payments_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

    await SharePlus.instance.share(ShareParams(text: csv, subject: fileName));
  }

  static String _escapeCsv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _typeLabel(PaymentType t) => switch (t) {
    PaymentType.membership => 'Membership',
    PaymentType.payt => 'PAYT',
    PaymentType.other => 'Other',
  };

  static String _methodLabel(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.bankTransfer => 'Bank transfer',
    PaymentMethod.stripe => 'Stripe',
    PaymentMethod.writtenOff => 'Written off',
    PaymentMethod.none => '—',
  };
}

// ── Data models ──────────────────────────────────────────────────────────────

class _Total {
  const _Total({required this.amount, required this.count});
  static const zero = _Total(amount: 0, count: 0);

  final double amount;
  final int count;

  _Total add(double value) => _Total(amount: amount + value, count: count + 1);
}

class _Totals {
  const _Totals({required this.byType, required this.byMethod});

  final Map<PaymentType, _Total> byType;
  final Map<PaymentMethod, _Total> byMethod;
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(color: color.withAlpha(180), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.count,
  });

  final String label;
  final double amount;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            '$count record${count == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              '£${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
