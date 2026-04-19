import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/entities/enums.dart';

class AttendanceRecordConverter {
  AttendanceRecordConverter._();

  static AttendanceRecord fromMap(String id, Map<String, dynamic> map) {
    return AttendanceRecord(
      id: id,
      sessionId: map['sessionId'] as String,
      studentId: map['studentId'] as String,
      disciplineId: map['disciplineId'] as String,
      sessionDate: (map['sessionDate'] as Timestamp).toDate(),
      checkInMethod: CheckInMethod.values.byName(
        map['checkInMethod'] as String,
      ),
      checkedInByProfileId: map['checkedInByProfileId'] as String?,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  static Map<String, dynamic> toMap(AttendanceRecord record) {
    return {
      'sessionId': record.sessionId,
      'studentId': record.studentId,
      'disciplineId': record.disciplineId,
      'sessionDate': Timestamp.fromDate(record.sessionDate),
      'checkInMethod': record.checkInMethod.name,
      'checkedInByProfileId': record.checkedInByProfileId,
      'timestamp': Timestamp.fromDate(record.timestamp),
    };
  }
}
