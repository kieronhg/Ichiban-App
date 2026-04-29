import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/payments_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/payt_session.dart';

/// Shows all pending PAYT sessions for a profile and lets the admin resolve
/// (or write off) any selection in one step.
class BulkResolveScreen extends ConsumerStatefulWidget {
  const BulkResolveScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<BulkResolveScreen> createState() => _BulkResolveScreenState();
}

class _BulkResolveScreenState extends ConsumerState<BulkResolveScreen> {
  final _selectedIds = <String>{};
  PaymentMethod _method = PaymentMethod.cash;
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(
      pendingPaytSessionsForProfileProvider(widget.profileId),
    );
    final profileAsync = ref.watch(profileProvider(widget.profileId));
    final profileName =
        profileAsync.asData?.value?.fullName ?? widget.profileId;

    return Scaffold(
      appBar: AppBar(title: Text('Resolve PAYT — $profileName')),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text('No pending sessions for this member.'),
            );
          }

          final selectedSessions = sessions
              .where((s) => _selectedIds.contains(s.id))
              .toList();
          final totalSelected = selectedSessions.fold(
            0.0,
            (sum, s) => sum + s.amount,
          );

          return Column(
            children: [
              // ── Session list ─────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectedIds.length == sessions.length,
                            tristate: true,
                            onChanged: (_) {
                              setState(() {
                                if (_selectedIds.length == sessions.length) {
                                  _selectedIds.clear();
                                } else {
                                  _selectedIds.addAll(
                                    sessions.map((s) => s.id),
                                  );
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Select all (${sessions.length})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...sessions.map(
                      (s) => _SessionCheckTile(
                        session: s,
                        selected: _selectedIds.contains(s.id),
                        onToggle: () => setState(() {
                          if (_selectedIds.contains(s.id)) {
                            _selectedIds.remove(s.id);
                          } else {
                            _selectedIds.add(s.id);
                          }
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Resolve panel ────────────────────────────────────
              if (_selectedIds.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_selectedIds.length} session'
                            '${_selectedIds.length == 1 ? '' : 's'} selected',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            '£${totalSelected.toStringAsFixed(2)} total',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<PaymentMethod>(
                        initialValue: _method,
                        decoration: const InputDecoration(
                          labelText: 'Payment method',
                          isDense: true,
                        ),
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
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _isBusy ? null : _resolve,
                        child: _isBusy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Mark ${_selectedIds.length} as Paid'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _resolve() async {
    final sessions =
        (ref
                    .read(
                      pendingPaytSessionsForProfileProvider(widget.profileId),
                    )
                    .asData
                    ?.value ??
                [])
            .where((s) => _selectedIds.contains(s.id))
            .toList();

    if (sessions.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      await ref
          .read(bulkResolvePaytSessionsUseCaseProvider)
          .call(
            sessions: sessions
                .map(
                  (s) => (
                    sessionId: s.id,
                    profileId: s.profileId,
                    amount: s.amount,
                  ),
                )
                .toList(),
            paymentMethod: _method,
            recordedByAdminId: ref.read(currentAdminIdProvider) ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${sessions.length} session'
              '${sessions.length == 1 ? '' : 's'} marked as paid.',
            ),
          ),
        );
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

// ── Session check tile ───────────────────────────────────────────────────────

class _SessionCheckTile extends StatelessWidget {
  const _SessionCheckTile({
    required this.session,
    required this.selected,
    required this.onToggle,
  });

  final PaytSession session;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE d MMM yyyy').format(session.sessionDate);
    return CheckboxListTile(
      value: selected,
      onChanged: (_) => onToggle(),
      title: Text(
        dateLabel,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        session.disciplineId,
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      secondary: Text(
        '£${session.amount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
