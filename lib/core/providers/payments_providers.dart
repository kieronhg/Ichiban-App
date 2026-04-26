import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cash_payment.dart';
import '../../domain/entities/payt_session.dart';
import '../../domain/use_cases/payments/bulk_resolve_payt_sessions_use_case.dart';
import '../../domain/use_cases/payments/edit_payment_use_case.dart';
import '../../domain/use_cases/payments/record_standalone_payment_use_case.dart';
import '../../domain/use_cases/payments/resolve_payt_session_use_case.dart';
import '../../domain/use_cases/payments/write_off_payt_session_use_case.dart';
import 'admin_session_provider.dart';
import 'repository_providers.dart';

/// Whether the current admin is an owner (can edit payments, view reports).
/// Delegates to the real auth session — no longer a stub.
final isSuperAdminProvider = Provider<bool>(
  (ref) => ref.watch(isOwnerProvider),
);

// ── Use-case providers ─────────────────────────────────────────────────────

final resolvePaytSessionUseCaseProvider = Provider<ResolvePaytSessionUseCase>(
  (ref) => ResolvePaytSessionUseCase(
    ref.watch(paytSessionRepositoryProvider),
    ref.watch(cashPaymentRepositoryProvider),
  ),
);

final bulkResolvePaytSessionsUseCaseProvider =
    Provider<BulkResolvePaytSessionsUseCase>(
      (ref) => BulkResolvePaytSessionsUseCase(
        ref.watch(paytSessionRepositoryProvider),
        ref.watch(cashPaymentRepositoryProvider),
      ),
    );

final writeOffPaytSessionUseCaseProvider = Provider<WriteOffPaytSessionUseCase>(
  (ref) => WriteOffPaytSessionUseCase(ref.watch(paytSessionRepositoryProvider)),
);

final recordStandalonePaymentUseCaseProvider =
    Provider<RecordStandalonePaymentUseCase>(
      (ref) => RecordStandalonePaymentUseCase(
        ref.watch(cashPaymentRepositoryProvider),
      ),
    );

final editPaymentUseCaseProvider = Provider<EditPaymentUseCase>(
  (ref) => EditPaymentUseCase(ref.watch(cashPaymentRepositoryProvider)),
);

// ── PAYT Session stream providers ──────────────────────────────────────────

/// All PAYT sessions across all profiles, ordered by sessionDate descending.
final allPaytSessionsProvider = StreamProvider<List<PaytSession>>(
  (ref) => ref.watch(paytSessionRepositoryProvider).watchAll(),
);

/// All PAYT sessions for a specific profile, ordered by sessionDate descending.
final paytSessionsForProfileProvider =
    StreamProvider.family<List<PaytSession>, String>(
      (ref, profileId) =>
          ref.watch(paytSessionRepositoryProvider).watchForProfile(profileId),
    );

/// Pending (unpaid) PAYT sessions for a specific profile.
final pendingPaytSessionsForProfileProvider =
    StreamProvider.family<List<PaytSession>, String>(
      (ref, profileId) => ref
          .watch(paytSessionRepositoryProvider)
          .watchPendingForProfile(profileId),
    );

// ── Cash Payment stream providers ──────────────────────────────────────────

/// All cash payments across all profiles, ordered by recordedAt descending.
final allCashPaymentsProvider = StreamProvider<List<CashPayment>>(
  (ref) => ref.watch(cashPaymentRepositoryProvider).watchAll(),
);

/// All cash payments for a specific profile, ordered by recordedAt descending.
final cashPaymentsForProfileProvider =
    StreamProvider.family<List<CashPayment>, String>(
      (ref, profileId) =>
          ref.watch(cashPaymentRepositoryProvider).watchForProfile(profileId),
    );

/// All cash payments linked to a specific membership.
final cashPaymentsForMembershipProvider =
    StreamProvider.family<List<CashPayment>, String>(
      (ref, membershipId) => ref
          .watch(cashPaymentRepositoryProvider)
          .watchForMembership(membershipId),
    );

// ── Derived providers ──────────────────────────────────────────────────────

/// The outstanding PAYT balance for a profile — the sum of all pending
/// session amounts. Returns 0.0 while loading or on error.
final outstandingBalanceProvider = Provider.family<double, String>((
  ref,
  profileId,
) {
  final pending = ref.watch(pendingPaytSessionsForProfileProvider(profileId));
  return pending.whenOrNull(
        data: (sessions) =>
            sessions.fold<double>(0.0, (sum, s) => sum + s.amount),
      ) ??
      0.0;
});

/// The count of pending PAYT sessions for a profile.
final pendingPaytSessionCountProvider = Provider.family<int, String>((
  ref,
  profileId,
) {
  final pending = ref.watch(pendingPaytSessionsForProfileProvider(profileId));
  return pending.whenOrNull(data: (sessions) => sessions.length) ?? 0;
});
