import '../../../domain/entities/membership_pricing.dart';

class MembershipPricingConverter {
  MembershipPricingConverter._();

  static MembershipPricing fromMap(String key, Map<String, dynamic> map) {
    return MembershipPricing(
      key: key,
      amount: (map['amount'] as num).toDouble(),
    );
  }

  static Map<String, dynamic> toMap(MembershipPricing pricing) {
    return {'amount': pricing.amount};
  }
}
