import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/membership_history.dart';
import '../../domain/entities/cash_payment.dart';
import '../../domain/use_cases/membership/get_memberships_use_case.dart';
import '../../domain/use_cases/membership/create_membership_use_case.dart';
import '../../domain/use_cases/membership/renew_membership_use_case.dart';
import '../../domain/use_cases/membership/convert_membership_plan_use_case.dart';
import '../../domain/use_cases/membership/cancel_membership_use_case.dart';
import '../../domain/use_cases/membership/add_family_member_use_case.dart';
import '../../domain/use_cases/membership/remove_family_member_use_case.dart';
import '../../domain/use_cases/membership/override_membership_status_use_case.dart';
import 'repository_providers.dart';

// ── Use case providers ─────────────────────────────────────────────────────

final getMembershipsUseCaseProvider = Provider<GetMembershipsUseCase>((ref) {
  return GetMembershipsUseCase(ref.read(membershipRepositoryProvider));
});

final createMembershipUseCaseProvider = Provider<CreateMembershipUseCase>(
  (ref) => CreateMembershipUseCase(
    membershipRepo: ref.read(membershipRepositoryProvider),
    historyRepo: ref.read(membershipHistoryRepositoryProvider),
    pricingRepo: ref.read(membershipPricingRepositoryProvider),
    cashPaymentRepo: ref.read(cashPaymentRepositoryProvider),
  ),
);

final renewMembershipUseCaseProvider = Provider<RenewMembershipUseCase>(
  (ref) => RenewMembershipUseCase(
    membershipRepo: ref.read(membershipRepositoryProvider),
    historyRepo: ref.read(membershipHistoryRepositoryProvider),
    pricingRepo: ref.read(membershipPricingRepositoryProvider),
    cashPaymentRepo: ref.read(cashPaymentRepositoryProvider),
  ),
);

final convertMembershipPlanUseCaseProvider =
    Provider<ConvertMembershipPlanUseCase>(
      (ref) => ConvertMembershipPlanUseCase(
        membershipRepo: ref.read(membershipRepositoryProvider),
        historyRepo: ref.read(membershipHistoryRepositoryProvider),
        pricingRepo: ref.read(membershipPricingRepositoryProvider),
        cashPaymentRepo: ref.read(cashPaymentRepositoryProvider),
      ),
    );

final cancelMembershipUseCaseProvider = Provider<CancelMembershipUseCase>(
  (ref) => CancelMembershipUseCase(
    membershipRepo: ref.read(membershipRepositoryProvider),
    historyRepo: ref.read(membershipHistoryRepositoryProvider),
  ),
);

final addFamilyMemberUseCaseProvider = Provider<AddFamilyMemberUseCase>(
  (ref) => AddFamilyMemberUseCase(
    membershipRepo: ref.read(membershipRepositoryProvider),
    historyRepo: ref.read(membershipHistoryRepositoryProvider),
  ),
);

final removeFamilyMemberUseCaseProvider = Provider<RemoveFamilyMemberUseCase>(
  (ref) => RemoveFamilyMemberUseCase(
    membershipRepo: ref.read(membershipRepositoryProvider),
    historyRepo: ref.read(membershipHistoryRepositoryProvider),
  ),
);

final overrideMembershipStatusUseCaseProvider =
    Provider<OverrideMembershipStatusUseCase>(
      (ref) => OverrideMembershipStatusUseCase(
        membershipRepo: ref.read(membershipRepositoryProvider),
        historyRepo: ref.read(membershipHistoryRepositoryProvider),
      ),
    );

// ── Data providers ─────────────────────────────────────────────────────────

/// All memberships in real time — used in the admin membership list.
final membershipListProvider = StreamProvider<List<Membership>>((ref) {
  return ref.read(getMembershipsUseCaseProvider).watchAll();
});

/// Single membership in real time — used in membership detail screen.
final membershipProvider = StreamProvider.family<Membership?, String>((
  ref,
  id,
) {
  return ref.read(membershipRepositoryProvider).watchById(id);
});

/// Active or PAYT membership for a profile — used in profile detail + grading.
final activeMembershipForProfileProvider =
    FutureProvider.family<Membership?, String>((ref, profileId) {
      return ref
          .read(getMembershipsUseCaseProvider)
          .getActiveForProfile(profileId);
    });

/// All memberships (any status) for a profile — used in profile membership tab.
final membershipsForProfileProvider =
    FutureProvider.family<List<Membership>, String>((ref, profileId) {
      return ref.read(getMembershipsUseCaseProvider).getForProfile(profileId);
    });

/// Membership history for a membership — used in membership detail screen.
final membershipHistoryProvider =
    StreamProvider.family<List<MembershipHistory>, String>((ref, membershipId) {
      return ref
          .read(membershipHistoryRepositoryProvider)
          .watchForMembership(membershipId);
    });

/// Cash payments linked to a membership — used in membership detail screen.
final cashPaymentsForMembershipProvider =
    FutureProvider.family<List<CashPayment>, String>((ref, membershipId) {
      return ref
          .read(cashPaymentRepositoryProvider)
          .getForMembership(membershipId);
    });

/// All pricing documents as a keyed map — used during create/renew flows.
final membershipPricingMapProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final all = await ref.read(membershipPricingRepositoryProvider).getAll();
  return {for (final p in all) p.key: p.amount};
});

/// Memberships with a given status — used for dashboard flags (deferred).
final membershipsByStatusProvider =
    FutureProvider.family<List<Membership>, MembershipStatus>((ref, status) {
      return ref.read(getMembershipsUseCaseProvider).getByStatus(status);
    });
