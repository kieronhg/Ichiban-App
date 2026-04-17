import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/attendance_session.dart';

class AttendanceSessionConverter {
  AttendanceSessionConverter._();

  static AttendanceSession fromMap(String id, Map<String, dynamic> map) {
    return AttendanceSession(
      id: id,
      disciplineId: map['disciplineId'] as String,
      sessionDate: (map['sessionDate'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
      createdByCoachId: map['createdByCoachId'] as String,
    );
  }

  static Map<String, dynamic> toMap(AttendanceSession session) {
    return {
      'disciplineId': session.disciplineId,
      'sessionDate': Timestamp.fromDate(session.sessionDate),
      'notes': session.notes,
      'createdByCoachId': session.createdByCoachId,
    };
  }
}
