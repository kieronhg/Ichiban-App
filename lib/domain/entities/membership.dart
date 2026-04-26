import 'package:equatable/equatable.dart';
import 'enums.dart';

class Membership extends Equatable {
  final String id;
  final MembershipPlanType planType;

  // Family monthly only — derived from memberProfileIds.length and stored for audit
  final FamilyPricingTier? familyPricingTier;

  // GBP price snapshot at time of creation
  final double monthlyAmount;

  final String primaryHolderId;
  final List<String> memberProfileIds;

  // Trial fields
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;

  // Set when paid plan begins (NOT trial start on conversion)
  final DateTime? membershipStartDate;

  // Monthly / annual only
  final DateTime? subscriptionRenewalDate;

  final MembershipStatus status;
  final PaymentMethod paymentMethod;

  // Stripe — placeholder for future card integration
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;

  final String createdByAdminId;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancelledByAdminId;
  final String? notes;
  final bool isActive;

  const Membership({
    required this.id,
    required this.planType,
    this.familyPricingTier,
    required this.monthlyAmount,
    required this.primaryHolderId,
    required this.memberProfileIds,
    this.trialStartDate,
    this.trialEndDate,
    this.membershipStartDate,
    this.subscriptionRenewalDate,
    required this.status,
    required this.paymentMethod,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    required this.createdByAdminId,
    required this.createdAt,
    this.cancelledAt,
    this.cancelledByAdminId,
    this.notes,
    required this.isActive,
  });

  bool get isTrial => planType == MembershipPlanType.trial;
  bool get isPayAsYouTrain =>
      planType == MembershipPlanType.payAsYouTrainAdult ||
      planType == MembershipPlanType.payAsYouTrainJunior;
  bool get isFamily => planType == MembershipPlanType.familyMonthly;

  /// Derives the correct family pricing tier from member count.
  static FamilyPricingTier deriveFamilyTier(int memberCount) {
    return memberCount >= 4
        ? FamilyPricingTier.fourOrMore
        : FamilyPricingTier.upToThree;
  }

  Membership copyWith({
    String? id,
    MembershipPlanType? planType,
    FamilyPricingTier? familyPricingTier,
    double? monthlyAmount,
    String? primaryHolderId,
    List<String>? memberProfileIds,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    DateTime? membershipStartDate,
    DateTime? subscriptionRenewalDate,
    MembershipStatus? status,
    PaymentMethod? paymentMethod,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    String? createdByAdminId,
    DateTime? createdAt,
    DateTime? cancelledAt,
    String? cancelledByAdminId,
    String? notes,
    bool? isActive,
  }) {
    return Membership(
      id: id ?? this.id,
      planType: planType ?? this.planType,
      familyPricingTier: familyPricingTier ?? this.familyPricingTier,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      primaryHolderId: primaryHolderId ?? this.primaryHolderId,
      memberProfileIds: memberProfileIds ?? this.memberProfileIds,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      subscriptionRenewalDate:
          subscriptionRenewalDate ?? this.subscriptionRenewalDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledByAdminId: cancelledByAdminId ?? this.cancelledByAdminId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    planType,
    familyPricingTier,
    monthlyAmount,
    primaryHolderId,
    memberProfileIds,
    trialStartDate,
    trialEndDate,
    membershipStartDate,
    subscriptionRenewalDate,
    status,
    paymentMethod,
    stripeCustomerId,
    stripeSubscriptionId,
    createdByAdminId,
    createdAt,
    cancelledAt,
    cancelledByAdminId,
    notes,
    isActive,
  ];
}
