import 'package:equatable/equatable.dart';

class MembershipPricing extends Equatable {
  final String key;
  final double amount;

  const MembershipPricing({required this.key, required this.amount});

  MembershipPricing copyWith({String? key, double? amount}) {
    return MembershipPricing(
      key: key ?? this.key,
      amount: amount ?? this.amount,
    );
  }

  @override
  List<Object?> get props => [key, amount];
}
