import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/payt_session.dart';
import '../../../domain/entities/enums.dart';

class PaytSessionConverter {
  PaytSessionConverter._();

  static PaytSession fromMap(String id, Map<String, dynamic> map) {
    return PaytSession(
      id: id,
      profileId: map['profileId'] as String,
      disciplineId: map['disciplineId'] as String,
      sessionDate: (map['sessionDate'] as Timestamp).toDate(),
      attendanceRecordId: map['attendanceRecordId'] as String?,
      paymentMethod: PaymentMethod.values.byName(
        map['paymentMethod'] as String,
      ),
      paymentStatus: PaytPaymentStatus.values.byName(
        map['paymentStatus'] as String,
      ),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      amount: (map['amount'] as num).toDouble(),
      recordedByAdminId: map['recordedByAdminId'] as String?,
      writtenOffByAdminId: map['writtenOffByAdminId'] as String?,
      writtenOffAt: (map['writtenOffAt'] as Timestamp?)?.toDate(),
      writeOffReason: map['writeOffReason'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
    );
  }

  static Map<String, dynamic> toMap(PaytSession session) {
    return {
      'profileId': session.profileId,
      'disciplineId': session.disciplineId,
      'sessionDate': Timestamp.fromDate(session.sessionDate),
      'attendanceRecordId': session.attendanceRecordId,
      'paymentMethod': session.paymentMethod.name,
      'paymentStatus': session.paymentStatus.name,
      'paidAt': session.paidAt != null
          ? Timestamp.fromDate(session.paidAt!)
          : null,
      'amount': session.amount,
      'recordedByAdminId': session.recordedByAdminId,
      'writtenOffByAdminId': session.writtenOffByAdminId,
      'writtenOffAt': session.writtenOffAt != null
          ? Timestamp.fromDate(session.writtenOffAt!)
          : null,
      'writeOffReason': session.writeOffReason,
      'createdAt': Timestamp.fromDate(session.createdAt),
      'notes': session.notes,
    };
  }
}
