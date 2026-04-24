import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/payments_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/profile.dart';

/// Admin form for recording a standalone (non-PAYT, non-membership) payment —
/// e.g. merchandise, exam fees, or any ad-hoc cash/card transaction.
class RecordPaymentScreen extends ConsumerStatefulWidget {
  /// Optional: pre-selected profile ID (e.g. navigated from a profile page).
  const RecordPaymentScreen({super.key, this.preselectedProfileId});

  final String? preselectedProfileId;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Profile? _selectedProfile;
  PaymentMethod _method = PaymentMethod.cash;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    // Pre-select profile if provided
    if (widget.preselectedProfileId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final profiles = ref.read(profileListProvider).asData?.value ?? [];
        final match = profiles
            .where((p) => p.id == widget.preselectedProfileId)
            .firstOrNull;
        if (match != null) setState(() => _selectedProfile = match);
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);
    final profiles = profilesAsync.asData?.value ?? [];
    // Sort active profiles first, then alphabetically
    final sortedProfiles = [...profiles]
      ..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        return a.fullName.compareTo(b.fullName);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Profile search/select ─────────────────────────────
            DropdownButtonFormField<Profile>(
              initialValue: _selectedProfile,
              decoration: const InputDecoration(
                labelText: 'Member',
                hintText: 'Select a member',
              ),
              isExpanded: true,
              items: sortedProfiles
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (p) => setState(() => _selectedProfile = p),
              validator: (p) => p == null ? 'Select a member' : null,
            ),
            const SizedBox(height: 16),

            // ── Amount ───────────────────────────────────────────
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount',
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
            const SizedBox(height: 16),

            // ── Payment method ────────────────────────────────────
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items:
                  [
                        PaymentMethod.cash,
                        PaymentMethod.card,
                        PaymentMethod.bankTransfer,
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
            const SizedBox(height: 16),

            // ── Notes ─────────────────────────────────────────────
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Merchandise — club hoodie',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            // ── Submit ────────────────────────────────────────────
            FilledButton(
              onPressed: _isBusy ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isBusy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    try {
      final amount = double.parse(_amountCtrl.text);
      final notes = _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim();

      await ref
          .read(recordStandalonePaymentUseCaseProvider)
          .call(
            profileId: _selectedProfile!.id,
            amount: amount,
            paymentMethod: _method,
            recordedByAdminId: 'admin', // TODO(auth-session): use real admin ID
            notes: notes,
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment recorded.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  static String _methodLabel(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.bankTransfer => 'Bank transfer',
    PaymentMethod.stripe => 'Stripe',
    PaymentMethod.writtenOff => 'Written off',
    PaymentMethod.none => '—',
  };
}
