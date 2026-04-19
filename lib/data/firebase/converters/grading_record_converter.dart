import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/grading_record.dart';

class GradingRecordConverter {
  GradingRecordConverter._();

  static GradingRecord fromMap(String id, Map<String, dynamic> map) {
    return GradingRecord(
      id: id,
      studentId: map['studentId'] as String,
      disciplineId: map['disciplineId'] as String,
      enrollmentId: map['enrollmentId'] as String,
      rankAchievedId: map['rankAchievedId'] as String,
      gradingDate: (map['gradingDate'] as Timestamp).toDate(),
      markedEligibleByCoachId: map['markedEligibleByCoachId'] as String,
      eligibilityAnnouncedDate: (map['eligibilityAnnouncedDate'] as Timestamp?)
          ?.toDate(),
      notes: map['notes'] as String?,
    );
  }

  static Map<String, dynamic> toMap(GradingRecord record) {
    return {
      'studentId': record.studentId,
      'disciplineId': record.disciplineId,
      'enrollmentId': record.enrollmentId,
      'rankAchievedId': record.rankAchievedId,
      'gradingDate': Timestamp.fromDate(record.gradingDate),
      'markedEligibleByCoachId': record.markedEligibleByCoachId,
      'eligibilityAnnouncedDate': record.eligibilityAnnouncedDate != null
          ? Timestamp.fromDate(record.eligibilityAnnouncedDate!)
          : null,
      'notes': record.notes,
    };
  }
}
