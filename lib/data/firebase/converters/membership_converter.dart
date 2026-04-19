import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/enums.dart';

class MembershipConverter {
  MembershipConverter._();

  static Membership fromMap(String id, Map<String, dynamic> map) {
    return Membership(
      id: id,
      planType: MembershipPlanType.values.byName(map['planType'] as String),
      familyPricingTier: map['familyPricingTier'] != null
          ? FamilyPricingTier.values.byName(map['familyPricingTier'] as String)
          : null,
      monthlyAmount: (map['monthlyAmount'] as num).toDouble(),
      primaryHolderId: map['primaryHolderId'] as String,
      memberProfileIds: List<String>.from(map['memberProfileIds'] as List),
      trialStartDate: (map['trialStartDate'] as Timestamp?)?.toDate(),
      trialEndDate: (map['trialEndDate'] as Timestamp?)?.toDate(),
      membershipStartDate: (map['membershipStartDate'] as Timestamp?)?.toDate(),
      subscriptionRenewalDate: (map['subscriptionRenewalDate'] as Timestamp?)
          ?.toDate(),
      status: MembershipStatus.values.byName(map['status'] as String),
      paymentMethod: PaymentMethod.values.byName(
        map['paymentMethod'] as String,
      ),
      stripeCustomerId: map['stripeCustomerId'] as String?,
      stripeSubscriptionId: map['stripeSubscriptionId'] as String?,
      createdByAdminId: map['createdByAdminId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool,
    );
  }

  static Map<String, dynamic> toMap(Membership membership) {
    return {
      'planType': membership.planType.name,
      'familyPricingTier': membership.familyPricingTier?.name,
      'monthlyAmount': membership.monthlyAmount,
      'primaryHolderId': membership.primaryHolderId,
      'memberProfileIds': membership.memberProfileIds,
      'trialStartDate': membership.trialStartDate != null
          ? Timestamp.fromDate(membership.trialStartDate!)
          : null,
      'trialEndDate': membership.trialEndDate != null
          ? Timestamp.fromDate(membership.trialEndDate!)
          : null,
      'membershipStartDate': membership.membershipStartDate != null
          ? Timestamp.fromDate(membership.membershipStartDate!)
          : null,
      'subscriptionRenewalDate': membership.subscriptionRenewalDate != null
          ? Timestamp.fromDate(membership.subscriptionRenewalDate!)
          : null,
      'status': membership.status.name,
      'paymentMethod': membership.paymentMethod.name,
      'stripeCustomerId': membership.stripeCustomerId,
      'stripeSubscriptionId': membership.stripeSubscriptionId,
      'createdByAdminId': membership.createdByAdminId,
      'createdAt': Timestamp.fromDate(membership.createdAt),
      'notes': membership.notes,
      'isActive': membership.isActive,
    };
  }
}
