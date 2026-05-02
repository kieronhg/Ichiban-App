import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/payments_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/cash_payment.dart';
import '../../../domain/entities/enums.dart';

/// Detailed view of a single CashPayment audit record.
/// Super admins see an Edit button.
class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({super.key, required this.payment});

  final CashPayment payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final profileAsync = ref.watch(profileProvider(payment.profileId));
    final profileName =
        profileAsync.asData?.value?.fullName ?? payment.profileId;

    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Detail'),
        actions: [
          if (isSuperAdmin)
            TextButton(
              onPressed: () => _showEditDialog(context, ref),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Type badge ────────────────────────────────────────────
          _TypeBadge(type: payment.paymentType),
          const SizedBox(height: 16),

          // ── Amount ───────────────────────────────────────────────
          Center(
            child: Text(
              '£${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 24),

          // ── Details card ─────────────────────────────────────────
          _DetailCard(
            children: [
              _Row('Member', profileName),
              _Row('Payment type', _typeLabel(payment.paymentType)),
              _Row('Payment method', _methodLabel(payment.paymentMethod)),
              _Row('Recorded at', dateFormat.format(payment.recordedAt)),
              _Row('Recorded by', payment.recordedByAdminId),
              if (payment.membershipId != null)
                _Row('Membership ID', payment.membershipId!),
              if (payment.paytSessionId != null)
                _Row('PAYT session ID', payment.paytSessionId!),
              if (payment.notes != null && payment.notes!.isNotEmpty)
                _Row('Notes', payment.notes!),
            ],
          ),

          // ── Edit history (super admin) ────────────────────────────
          if (payment.editedByAdminId != null) ...[
            const SizedBox(height: 12),
            _DetailCard(
              title: 'Edit History',
              children: [
                _Row('Edited by', payment.editedByAdminId!),
                if (payment.editedAt != null)
                  _Row('Edited at', dateFormat.format(payment.editedAt!)),
              ],
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditPaymentSheet(payment: payment),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(editPaymentUseCaseProvider)
          .call(
            id: payment.id,
            amount: result.amount,
            paymentMethod: result.paymentMethod,
            paymentType: result.paymentType,
            notes: result.notes,
            editedByAdminId: ref.read(currentAdminIdProvider) ?? '',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment updated.')));
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

// ── Edit result ──────────────────────────────────────────────────────────────

class _EditResult {
  const _EditResult({
    required this.amount,
    required this.paymentMethod,
    required this.paymentType,
    this.notes,
  });

  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentType paymentType;
  final String? notes;
}

// ── Edit sheet ───────────────────────────────────────────────────────────────

class _EditPaymentSheet extends StatefulWidget {
  const _EditPaymentSheet({required this.payment});

  final CashPayment payment;

  @override
  State<_EditPaymentSheet> createState() => _EditPaymentSheetState();
}

class _EditPaymentSheetState extends State<_EditPaymentSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late PaymentMethod _method;
  late PaymentType _type;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.payment.amount.toStringAsFixed(2),
    );
    _notesCtrl = TextEditingController(text: widget.payment.notes ?? '');
    _method = widget.payment.paymentMethod;
    _type = widget.payment.paymentType;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Payment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount (£)',
                prefixText: '£',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items:
                  [
                        PaymentMethod.cash,
                        PaymentMethod.card,
                        PaymentMethod.bankTransfer,
                        PaymentMethod.stripe,
                      ]
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(_methodLabel(m)),
                        ),
                      )
                      .toList(),
              onChanged: (m) {
                if (m != null) setState(() => _method = m);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Payment type'),
              items: PaymentType.values
                  .map(
                    (t) =>
                        DropdownMenuItem(value: t, child: Text(_typeLabel(t))),
                  )
                  .toList(),
              onChanged: (t) {
                if (t != null) setState(() => _type = t);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _submit, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text);
    final notes = _notesCtrl.text.trim().isEmpty
        ? null
        : _notesCtrl.text.trim();
    Navigator.pop(
      context,
      _EditResult(
        amount: amount,
        paymentMethod: _method,
        paymentType: _type,
        notes: notes,
      ),
    );
  }

  static String _methodLabel(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.bankTransfer => 'Bank transfer',
    PaymentMethod.stripe => 'Stripe',
    PaymentMethod.writtenOff => 'Written off',
    PaymentMethod.none => '—',
  };

  static String _typeLabel(PaymentType t) => switch (t) {
    PaymentType.membership => 'Membership',
    PaymentType.payt => 'PAYT',
    PaymentType.other => 'Other',
  };
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final PaymentType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      PaymentType.membership => ('Membership', AppColors.info),
      PaymentType.payt => ('PAYT', AppColors.accent),
      PaymentType.other => ('Other', AppColors.textSecondary),
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Divider(height: 1),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
