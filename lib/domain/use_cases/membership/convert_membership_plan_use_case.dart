import '../../entities/enums.dart';
import '../../entities/membership.dart';
import '../../entities/membership_history.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/membership_history_repository.dart';
import '../../repositories/membership_pricing_repository.dart';
import '../../repositories/cash_payment_repository.dart';
import 'create_membership_use_case.dart';

class ConvertMembershipPlanUseCase {
  const ConvertMembershipPlanUseCase({
    required MembershipRepository membershipRepo,
    required MembershipHistoryRepository historyRepo,
    required MembershipPricingRepository pricingRepo,
    required CashPaymentRepository cashPaymentRepo,
  }) : _membershipRepo = membershipRepo,
       _historyRepo = historyRepo,
       _pricingRepo = pricingRepo,
       _cashPaymentRepo = cashPaymentRepo;

  final MembershipRepository _membershipRepo;
  final MembershipHistoryRepository _historyRepo;
  final MembershipPricingRepository _pricingRepo;
  final CashPaymentRepository _cashPaymentRepo;

  Future<String> call({
    required Membership oldMembership,
    required MembershipPlanType newPlanType,
    required PaymentMethod paymentMethod,
    required String adminId,
    FamilyPricingTier? familyPricingTier,
  }) async {
    final now = DateTime.now();

    // Step 1 — cancel old membership.
    await _membershipRepo.cancel(
      id: oldMembership.id,
      adminId: adminId,
      cancelledAt: now,
    );

    // Step 2 — write planChanged history on old membership.
    await _historyRepo.create(
      MembershipHistory(
        id: '',
        membershipId: oldMembership.id,
        changeType: MembershipChangeType.planChanged,
        previousStatus: oldMembership.status,
        newStatus: MembershipStatus.cancelled,
        previousPlanType: oldMembership.planType,
        newPlanType: newPlanType,
        previousAmount: oldMembership.monthlyAmount,
        changedByAdminId: adminId,
        triggeredByCloudFunction: false,
        changedAt: now,
      ),
    );

    // Step 3 — create new membership using the same members.
    // Temporarily bypass the active-membership guard by cancelling first (done above).
    final createUseCase = CreateMembershipUseCase(
      membershipRepo: _membershipRepo,
      historyRepo: _historyRepo,
      pricingRepo: _pricingRepo,
      cashPaymentRepo: _cashPaymentRepo,
    );

    // CreateMembershipUseCase checks for active memberships — since we just
    // cancelled the old one, this should pass. Re-check is intentional.
    final newMembershipId = await createUseCase.call(
      planType: newPlanType,
      primaryHolderId: oldMembership.primaryHolderId,
      memberProfileIds: List.from(oldMembership.memberProfileIds),
      paymentMethod: paymentMethod,
      adminId: adminId,
      familyPricingTier: familyPricingTier,
    );

    return newMembershipId;
  }
}
