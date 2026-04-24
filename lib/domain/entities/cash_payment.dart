import 'package:equatable/equatable.dart';
import 'enums.dart';

const _absent = Object();

// Audit record for every manually recorded payment.
// For membership payments: membershipId is set, paytSessionId is null.
// For PAYT payments:       paytSessionId is set, membershipId is null.
// For other payments:      both are null.
// membershipId and paytSessionId cannot BOTH be set simultaneously.
class CashPayment extends Equatable {
  final String id;
  final String profileId;
  final String? membershipId;
  final String? paytSessionId;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentType paymentType;
  final String recordedByAdminId;
  final DateTime recordedAt;
  final String? notes;

  // Set by super admin if the record was later edited
  final String? editedByAdminId;
  final DateTime? editedAt;

  const CashPayment({
    required this.id,
    required this.profileId,
    this.membershipId,
    this.paytSessionId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentType,
    required this.recordedByAdminId,
    required this.recordedAt,
    this.notes,
    this.editedByAdminId,
    this.editedAt,
  }) : assert(
         !(membershipId != null && paytSessionId != null),
         'membershipId and paytSessionId cannot both be set.',
       );

  CashPayment copyWith({
    String? id,
    String? profileId,
    Object? membershipId = _absent,
    Object? paytSessionId = _absent,
    double? amount,
    PaymentMethod? paymentMethod,
    PaymentType? paymentType,
    String? recordedByAdminId,
    DateTime? recordedAt,
    Object? notes = _absent,
    Object? editedByAdminId = _absent,
    Object? editedAt = _absent,
  }) {
    return CashPayment(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      membershipId: identical(membershipId, _absent)
          ? this.membershipId
          : membershipId as String?,
      paytSessionId: identical(paytSessionId, _absent)
          ? this.paytSessionId
          : paytSessionId as String?,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentType: paymentType ?? this.paymentType,
      recordedByAdminId: recordedByAdminId ?? this.recordedByAdminId,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: identical(notes, _absent) ? this.notes : notes as String?,
      editedByAdminId: identical(editedByAdminId, _absent)
          ? this.editedByAdminId
          : editedByAdminId as String?,
      editedAt: identical(editedAt, _absent)
          ? this.editedAt
          : editedAt as DateTime?,
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
    paymentType,
    recordedByAdminId,
    recordedAt,
    notes,
    editedByAdminId,
    editedAt,
  ];
}
