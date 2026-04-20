import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event_student.dart';

class GradingEventStudentConverter {
  GradingEventStudentConverter._();

  static GradingEventStudent fromMap(String id, Map<String, dynamic> map) {
    return GradingEventStudent(
      id: id,
      gradingEventId: map['gradingEventId'] as String,
      studentId: map['studentId'] as String,
      disciplineId: map['disciplineId'] as String,
      enrollmentId: map['enrollmentId'] as String,
      currentRankId: map['currentRankId'] as String,
      nominatedByAdminId: map['nominatedByAdminId'] as String,
      nominatedAt: (map['nominatedAt'] as Timestamp).toDate(),
      notificationSentAt: (map['notificationSentAt'] as Timestamp?)?.toDate(),
      outcome: map['outcome'] != null
          ? GradingOutcome.values.byName(map['outcome'] as String)
          : null,
      rankAchievedId: map['rankAchievedId'] as String?,
      gradingScore: (map['gradingScore'] as num?)?.toDouble(),
      resultRecordedByAdminId: map['resultRecordedByAdminId'] as String?,
      resultRecordedAt: (map['resultRecordedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'] as String?,
    );
  }

  static Map<String, dynamic> toMap(GradingEventStudent student) {
    return {
      'gradingEventId': student.gradingEventId,
      'studentId': student.studentId,
      'disciplineId': student.disciplineId,
      'enrollmentId': student.enrollmentId,
      'currentRankId': student.currentRankId,
      'nominatedByAdminId': student.nominatedByAdminId,
      'nominatedAt': Timestamp.fromDate(student.nominatedAt),
      'notificationSentAt': student.notificationSentAt != null
          ? Timestamp.fromDate(student.notificationSentAt!)
          : null,
      'outcome': student.outcome?.name,
      'rankAchievedId': student.rankAchievedId,
      'gradingScore': student.gradingScore,
      'resultRecordedByAdminId': student.resultRecordedByAdminId,
      'resultRecordedAt': student.resultRecordedAt != null
          ? Timestamp.fromDate(student.resultRecordedAt!)
          : null,
      'notes': student.notes,
    };
  }
}
