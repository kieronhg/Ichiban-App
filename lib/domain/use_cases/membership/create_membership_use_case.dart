import '../../entities/enums.dart';
import '../../entities/membership.dart';
import '../../entities/membership_history.dart';
import '../../entities/cash_payment.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/membership_history_repository.dart';
import '../../repositories/membership_pricing_repository.dart';
import '../../repositories/cash_payment_repository.dart';

class CreateMembershipUseCase {
  const CreateMembershipUseCase({
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
    required MembershipPlanType planType,
    required String primaryHolderId,
    required List<String> memberProfileIds,
    required PaymentMethod paymentMethod,
    required String adminId,
    FamilyPricingTier? familyPricingTier,
  }) async {
    // Guard: warn if any member already has an active membership.
    for (final profileId in memberProfileIds) {
      final existing = await _membershipRepo.getActiveForProfile(profileId);
      if (existing != null) {
        throw Exception(
          'One or more members already have an active membership. '
          'Cancel the existing membership before creating a new one.',
        );
      }
    }

    final now = DateTime.now();

    // Derive dates and status from plan type.
    DateTime? trialStartDate;
    DateTime? trialEndDate;
    DateTime? membershipStartDate;
    DateTime? subscriptionRenewalDate;
    MembershipStatus status;
    bool isActive;

    if (planType == MembershipPlanType.trial) {
      trialStartDate = now;
      trialEndDate = now.add(const Duration(days: 14));
      status = MembershipStatus.trial;
      isActive = true;
    } else if (planType == MembershipPlanType.payAsYouTrainAdult ||
        planType == MembershipPlanType.payAsYouTrainJunior) {
      status = MembershipStatus.payt;
      isActive = true;
    } else {
      membershipStartDate = now;
      final isAnnual =
          planType == MembershipPlanType.annualAdult ||
          planType == MembershipPlanType.annualJunior;
      subscriptionRenewalDate = isAnnual
          ? DateTime(now.year + 1, now.month, now.day)
          : DateTime(now.year, now.month + 1, now.day);
      status = MembershipStatus.active;
      isActive = true;
    }

    // Fetch price snapshot from membershipPricing collection.
    final pricingKey = _pricingKeyFor(planType, familyPricingTier);
    final pricing = await _pricingRepo.getByKey(pricingKey);
    final amount = pricing?.amount ?? _defaultAmounts[pricingKey] ?? 0.0;

    final membership = Membership(
      id: '',
      planType: planType,
      familyPricingTier: familyPricingTier,
      monthlyAmount: amount,
      primaryHolderId: primaryHolderId,
      memberProfileIds: memberProfileIds,
      trialStartDate: trialStartDate,
      trialEndDate: trialEndDate,
      membershipStartDate: membershipStartDate,
      subscriptionRenewalDate: subscriptionRenewalDate,
      status: status,
      paymentMethod: paymentMethod,
      createdByAdminId: adminId,
      createdAt: now,
      isActive: isActive,
    );

    final membershipId = await _membershipRepo.create(membership);

    // Write history record: created.
    await _historyRepo.create(
      MembershipHistory(
        id: '',
        membershipId: membershipId,
        changeType: MembershipChangeType.created,
        newStatus: status,
        changedByAdminId: adminId,
        triggeredByCloudFunction: false,
        changedAt: now,
      ),
    );

    // Write cashPayment record if payment was made (not trial or PAYT).
    if (paymentMethod != PaymentMethod.none &&
        paymentMethod != PaymentMethod.stripe &&
        status != MembershipStatus.payt) {
      await _cashPaymentRepo.create(
        CashPayment(
          id: '',
          profileId: primaryHolderId,
          membershipId: membershipId,
          paytSessionId: null,
          amount: amount,
          paymentMethod: paymentMethod,
          paymentType: PaymentType.membership,
          recordedByAdminId: adminId,
          recordedAt: now,
        ),
      );
    }

    return membershipId;
  }

  static const Map<String, double> _defaultAmounts = {
    'monthlyAdult': 33.00,
    'monthlyJunior': 25.00,
    'annualAdult': 330.00,
    'annualJunior': 242.00,
    'familyMonthlyUpToThree': 55.00,
    'familyMonthlyFourOrMore': 66.00,
    'payAsYouTrainAdult': 10.00,
    'payAsYouTrainJunior': 7.00,
    'trial': 0.00,
  };

  /// Maps a plan type (and optional family tier) to its membershipPricing key.
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
