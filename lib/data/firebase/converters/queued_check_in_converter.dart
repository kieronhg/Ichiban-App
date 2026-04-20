import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/queued_check_in.dart';

class QueuedCheckInConverter {
  QueuedCheckInConverter._();

  static QueuedCheckIn fromMap(String id, Map<String, dynamic> map) {
    return QueuedCheckIn(
      id: id,
      studentId: map['studentId'] as String,
      disciplineId: map['disciplineId'] as String,
      queuedAt: (map['queuedAt'] as Timestamp).toDate(),
      queueDate: (map['queueDate'] as Timestamp).toDate(),
      status: QueuedCheckInStatus.values.byName(map['status'] as String),
      resolvedSessionId: map['resolvedSessionId'] as String?,
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      discardedByAdminId: map['discardedByAdminId'] as String?,
      discardedAt: map['discardedAt'] != null
          ? (map['discardedAt'] as Timestamp).toDate()
          : null,
    );
  }

  static Map<String, dynamic> toMap(QueuedCheckIn q) {
    return {
      'studentId': q.studentId,
      'disciplineId': q.disciplineId,
      'queuedAt': Timestamp.fromDate(q.queuedAt),
      'queueDate': Timestamp.fromDate(q.queueDate),
      'status': q.status.name,
      'resolvedSessionId': q.resolvedSessionId,
      'resolvedAt': q.resolvedAt != null
          ? Timestamp.fromDate(q.resolvedAt!)
          : null,
      'discardedByAdminId': q.discardedByAdminId,
      'discardedAt': q.discardedAt != null
          ? Timestamp.fromDate(q.discardedAt!)
          : null,
    };
  }
}
