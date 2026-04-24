import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/payments_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/cash_payment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/profile.dart';
import '../../../core/router/route_names.dart';

/// All-up payment audit log for admins.
/// Filter chips narrow by PaymentType. Tapping a row navigates to detail.
/// FAB records a standalone payment.
class PaymentsListScreen extends ConsumerStatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  ConsumerState<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends ConsumerState<PaymentsListScreen> {
  PaymentType? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(allCashPaymentsProvider);
    final profilesAsync = ref.watch(profileListProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);

    final profileLookup = <String, Profile>{
      for (final p in profilesAsync.asData?.value ?? []) p.id: p,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.bar_chart_outlined),
              tooltip: 'Financial Report',
              onPressed: () =>
                  context.pushNamed(RouteNames.adminPaymentsReport),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.adminPaymentsRecord),
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
      body: Column(
        children: [
          // ── Filter chips ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onSelected: () => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Membership',
                    selected: _filter == PaymentType.membership,
                    onSelected: () =>
                        setState(() => _filter = PaymentType.membership),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'PAYT',
                    selected: _filter == PaymentType.payt,
                    onSelected: () =>
                        setState(() => _filter = PaymentType.payt),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Other',
                    selected: _filter == PaymentType.other,
                    onSelected: () =>
                        setState(() => _filter = PaymentType.other),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // ── Payment list ───────────────────────────────────────────
          Expanded(
            child: paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (payments) {
                final filtered = _filter == null
                    ? payments
                    : payments.where((p) => p.paymentType == _filter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No payments found.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 16),
                  itemBuilder: (_, i) {
                    final payment = filtered[i];
                    final profile = profileLookup[payment.profileId];
                    return _PaymentRow(
                      payment: payment,
                      profileName: profile?.fullName,
                      onTap: () => context.pushNamed(
                        RouteNames.adminPaymentsDetail,
                        pathParameters: {'paymentId': payment.id},
                        extra: payment,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.accent.withAlpha(30),
      checkmarkColor: AppColors.accent,
      labelStyle: TextStyle(
        color: selected ? AppColors.accent : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

// ── Payment row ──────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.profileName,
    required this.onTap,
  });

  final CashPayment payment;
  final String? profileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy').format(payment.recordedAt);

    final typeLabel = switch (payment.paymentType) {
      PaymentType.membership => 'Membership',
      PaymentType.payt => 'PAYT',
      PaymentType.other => 'Other',
    };

    final methodLabel = switch (payment.paymentMethod) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.card => 'Card',
      PaymentMethod.bankTransfer => 'Bank transfer',
      PaymentMethod.stripe => 'Stripe',
      PaymentMethod.writtenOff => 'Written off',
      PaymentMethod.none => '—',
    };

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        profileName ?? payment.profileId,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '$dateLabel · $typeLabel · $methodLabel',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        '£${payment.amount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }
}
