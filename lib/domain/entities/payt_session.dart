import 'package:equatable/equatable.dart';
import 'enums.dart';

class PaytSession extends Equatable {
  final String id;
  final String profileId;
  final String disciplineId;
  final DateTime sessionDate;

  // Linked after admin logs payment against an attendance record
  final String? attendanceRecordId;

  final PaymentMethod paymentMethod;
  final PaytPaymentStatus paymentStatus;
  final DateTime? paidAt;

  // GBP snapshot at time of session
  final double amount;

  // Set when admin logs a cash payment
  final String? recordedByAdminId;

  final DateTime createdAt;
  final String? notes;

  const PaytSession({
    required this.id,
    required this.profileId,
    required this.disciplineId,
    required this.sessionDate,
    this.attendanceRecordId,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paidAt,
    required this.amount,
    this.recordedByAdminId,
    required this.createdAt,
    this.notes,
  });

  bool get isPaid => paymentStatus == PaytPaymentStatus.paid;

  PaytSession copyWith({
    String? id,
    String? profileId,
    String? disciplineId,
    DateTime? sessionDate,
    String? attendanceRecordId,
    PaymentMethod? paymentMethod,
    PaytPaymentStatus? paymentStatus,
    DateTime? paidAt,
    double? amount,
    String? recordedByAdminId,
    DateTime? createdAt,
    String? notes,
  }) {
    return PaytSession(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      disciplineId: disciplineId ?? this.disciplineId,
      sessionDate: sessionDate ?? this.sessionDate,
      attendanceRecordId: attendanceRecordId ?? this.attendanceRecordId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: paidAt ?? this.paidAt,
      amount: amount ?? this.amount,
      recordedByAdminId: recordedByAdminId ?? this.recordedByAdminId,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id, profileId, disciplineId, sessionDate,
        attendanceRecordId, paymentMethod, paymentStatus, paidAt,
        amount, recordedByAdminId, createdAt, notes,
      ];
}
