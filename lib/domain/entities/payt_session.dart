import 'package:equatable/equatable.dart';
import 'enums.dart';

const _absent = Object();

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

  // Set when admin resolves payment
  final String? recordedByAdminId;

  // Set when admin writes off the session
  final String? writtenOffByAdminId;
  final DateTime? writtenOffAt;
  final String? writeOffReason;

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
    this.writtenOffByAdminId,
    this.writtenOffAt,
    this.writeOffReason,
    required this.createdAt,
    this.notes,
  });

  bool get isPaid => paymentStatus == PaytPaymentStatus.paid;
  bool get isPending => paymentStatus == PaytPaymentStatus.pending;
  bool get isWrittenOff => paymentStatus == PaytPaymentStatus.writtenOff;

  PaytSession copyWith({
    String? id,
    String? profileId,
    String? disciplineId,
    DateTime? sessionDate,
    Object? attendanceRecordId = _absent,
    PaymentMethod? paymentMethod,
    PaytPaymentStatus? paymentStatus,
    Object? paidAt = _absent,
    double? amount,
    Object? recordedByAdminId = _absent,
    Object? writtenOffByAdminId = _absent,
    Object? writtenOffAt = _absent,
    Object? writeOffReason = _absent,
    DateTime? createdAt,
    Object? notes = _absent,
  }) {
    return PaytSession(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      disciplineId: disciplineId ?? this.disciplineId,
      sessionDate: sessionDate ?? this.sessionDate,
      attendanceRecordId: identical(attendanceRecordId, _absent)
          ? this.attendanceRecordId
          : attendanceRecordId as String?,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: identical(paidAt, _absent) ? this.paidAt : paidAt as DateTime?,
      amount: amount ?? this.amount,
      recordedByAdminId: identical(recordedByAdminId, _absent)
          ? this.recordedByAdminId
          : recordedByAdminId as String?,
      writtenOffByAdminId: identical(writtenOffByAdminId, _absent)
          ? this.writtenOffByAdminId
          : writtenOffByAdminId as String?,
      writtenOffAt: identical(writtenOffAt, _absent)
          ? this.writtenOffAt
          : writtenOffAt as DateTime?,
      writeOffReason: identical(writeOffReason, _absent)
          ? this.writeOffReason
          : writeOffReason as String?,
      createdAt: createdAt ?? this.createdAt,
      notes: identical(notes, _absent) ? this.notes : notes as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    profileId,
    disciplineId,
    sessionDate,
    attendanceRecordId,
    paymentMethod,
    paymentStatus,
    paidAt,
    amount,
    recordedByAdminId,
    writtenOffByAdminId,
    writtenOffAt,
    writeOffReason,
    createdAt,
    notes,
  ];
}
