import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/cash_payment.dart';
import '../../../domain/entities/enums.dart';

class CashPaymentConverter {
  CashPaymentConverter._();

  static CashPayment fromMap(String id, Map<String, dynamic> map) {
    return CashPayment(
      id: id,
      profileId: map['profileId'] as String,
      membershipId: map['membershipId'] as String?,
      paytSessionId: map['paytSessionId'] as String?,
      amount: (map['amount'] as num).toDouble(),
      // Gracefully handle legacy records that predate the paymentMethod field.
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.byName(map['paymentMethod'] as String)
          : PaymentMethod.cash,
      recordedByAdminId: map['recordedByAdminId'] as String,
      recordedAt: (map['recordedAt'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
    );
  }

  static Map<String, dynamic> toMap(CashPayment payment) {
    return {
      'profileId': payment.profileId,
      'membershipId': payment.membershipId,
      'paytSessionId': payment.paytSessionId,
      'amount': payment.amount,
      'paymentMethod': payment.paymentMethod.name,
      'recordedByAdminId': payment.recordedByAdminId,
      'recordedAt': Timestamp.fromDate(payment.recordedAt),
      'notes': payment.notes,
    };
  }
}
