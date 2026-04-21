import 'package:equatable/equatable.dart';
import 'enums.dart';

// Audit record for every manually recorded payment.
// Either membershipId OR paytSessionId will be set — never both.
class CashPayment extends Equatable {
  final String id;
  final String profileId;
  final String? membershipId;
  final String? paytSessionId;
  final double amount;

  /// The actual payment method used (cash, card, bank transfer, etc.).
  final PaymentMethod paymentMethod;

  final String recordedByAdminId;
  final DateTime recordedAt;
  final String? notes;

  const CashPayment({
    required this.id,
    required this.profileId,
    this.membershipId,
    this.paytSessionId,
    required this.amount,
    required this.paymentMethod,
    required this.recordedByAdminId,
    required this.recordedAt,
    this.notes,
  }) : assert(
         (membershipId != null) != (paytSessionId != null),
         'Exactly one of membershipId or paytSessionId must be set.',
       );

  CashPayment copyWith({
    String? id,
    String? profileId,
    String? membershipId,
    String? paytSessionId,
    double? amount,
    PaymentMethod? paymentMethod,
    String? recordedByAdminId,
    DateTime? recordedAt,
    String? notes,
  }) {
    return CashPayment(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      membershipId: membershipId ?? this.membershipId,
      paytSessionId: paytSessionId ?? this.paytSessionId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      recordedByAdminId: recordedByAdminId ?? this.recordedByAdminId,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    profileId,
    membershipId,
    paytSessionId,
    amount,
    paymentMethod,
    recordedByAdminId,
    recordedAt,
    notes,
  ];
}
