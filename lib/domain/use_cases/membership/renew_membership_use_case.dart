import '../../entities/enums.dart';
import '../../entities/membership.dart';
import '../../entities/membership_history.dart';
import '../../entities/cash_payment.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/membership_history_repository.dart';
import '../../repositories/membership_pricing_repository.dart';
import '../../repositories/cash_payment_repository.dart';

class RenewMembershipUseCase {
  const RenewMembershipUseCase({
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

  Future<void> call({
    required Membership membership,
    required PaymentMethod paymentMethod,
    required String adminId,
  }) async {
    final now = DateTime.now();

    // Extend from current renewalDate, not from today (edge case: early renewal).
    final base = membership.subscriptionRenewalDate ?? now;
    final isAnnual =
        membership.planType == MembershipPlanType.annualAdult ||
        membership.planType == MembershipPlanType.annualJunior;
    final newRenewalDate = isAnnual
        ? DateTime(base.year + 1, base.month, base.day)
        : DateTime(base.year, base.month + 1, base.day);

    // Re-fetch current price.
    FamilyPricingTier? newTier;
    if (membership.isFamily) {
      newTier = Membership.deriveFamilyTier(membership.memberProfileIds.length);
    }
    final pricingKey = _pricingKeyFor(membership.planType, newTier);
    final pricing = await _pricingRepo.getByKey(pricingKey);
    final newAmount = pricing?.amount ?? membership.monthlyAmount;
    final previousAmount = membership.monthlyAmount;

    await _membershipRepo.renew(
      id: membership.id,
      newRenewalDate: newRenewalDate,
      newAmount: newAmount,
      paymentMethod: paymentMethod,
      newFamilyTier: newTier,
    );

    await _historyRepo.create(
      MembershipHistory(
        id: '',
        membershipId: membership.id,
        changeType: MembershipChangeType.renewed,
        previousStatus: membership.status,
        newStatus: MembershipStatus.active,
        previousAmount: previousAmount,
        newAmount: newAmount,
        changedByAdminId: adminId,
        triggeredByCloudFunction: false,
        changedAt: now,
      ),
    );

    if (paymentMethod != PaymentMethod.none &&
        paymentMethod != PaymentMethod.stripe) {
      await _cashPaymentRepo.create(
        CashPayment(
          id: '',
          profileId: membership.primaryHolderId,
          membershipId: membership.id,
          paytSessionId: null,
          amount: newAmount,
          paymentMethod: paymentMethod,
          recordedByAdminId: adminId,
          recordedAt: now,
        ),
      );
    }
  }

  String _pricingKeyFor(
    MembershipPlanType planType,
    FamilyPricingTier? familyTier,
  ) {
    return switch (planType) {
      MembershipPlanType.monthlyAdult => 'monthlyAdult',
      MembershipPlanType.monthlyJunior => 'monthlyJunior',
      MembershipPlanType.annualAdult => 'annualAdult',
      MembershipPlanType.annualJunior => 'annualJunior',
      MembershipPlanType.familyMonthly =>
        familyTier == FamilyPricingTier.fourOrMore
            ? 'familyMonthlyFourOrMore'
            : 'familyMonthlyUpToThree',
      MembershipPlanType.payAsYouTrainAdult => 'payAsYouTrainAdult',
      MembershipPlanType.payAsYouTrainJunior => 'payAsYouTrainJunior',
      MembershipPlanType.trial => 'trial',
    };
  }
}
