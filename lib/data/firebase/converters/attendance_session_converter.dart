import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/attendance_session.dart';

class AttendanceSessionConverter {
  AttendanceSessionConverter._();

  static AttendanceSession fromMap(String id, Map<String, dynamic> map) {
    return AttendanceSession(
      id: id,
      disciplineId: map['disciplineId'] as String,
      sessionDate: (map['sessionDate'] as Timestamp).toDate(),
      // Graceful fallback for legacy documents written before times were added
      startTime: (map['startTime'] as String?) ?? '',
      endTime: (map['endTime'] as String?) ?? '',
      notes: map['notes'] as String?,
      createdByAdminId:
          (map['createdByAdminId'] as String?) ??
          (map['createdByCoachId'] as String?) ??
          '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static Map<String, dynamic> toMap(AttendanceSession session) {
    return {
      'disciplineId': session.disciplineId,
      'sessionDate': Timestamp.fromDate(session.sessionDate),
      'startTime': session.startTime,
      'endTime': session.endTime,
      'notes': session.notes,
      'createdByAdminId': session.createdByAdminId,
      'createdAt': Timestamp.fromDate(session.createdAt),
    };
  }
}
