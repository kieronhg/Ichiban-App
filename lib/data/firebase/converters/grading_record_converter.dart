import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_record.dart';

class GradingRecordConverter {
  GradingRecordConverter._();

  static GradingRecord fromMap(String id, Map<String, dynamic> map) {
    return GradingRecord(
      id: id,
      studentId: map['studentId'] as String,
      disciplineId: map['disciplineId'] as String,
      enrollmentId: map['enrollmentId'] as String,
      gradingEventId: map['gradingEventId'] as String,
      fromRankId: map['fromRankId'] as String,
      rankAchievedId: map['rankAchievedId'] as String,
      outcome: GradingOutcome.values.byName(map['outcome'] as String),
      gradingScore: (map['gradingScore'] as num?)?.toDouble(),
      gradingDate: (map['gradingDate'] as Timestamp).toDate(),
      markedEligibleByAdminId: map['markedEligibleByAdminId'] as String,
      eligibilityAnnouncedDate: (map['eligibilityAnnouncedDate'] as Timestamp?)
          ?.toDate(),
      gradedByAdminId: map['gradedByAdminId'] as String,
      notes: map['notes'] as String?,
    );
  }

  static Map<String, dynamic> toMap(GradingRecord record) {
    return {
      'studentId': record.studentId,
      'disciplineId': record.disciplineId,
      'enrollmentId': record.enrollmentId,
      'gradingEventId': record.gradingEventId,
      'fromRankId': record.fromRankId,
      'rankAchievedId': record.rankAchievedId,
      'outcome': record.outcome.name,
      'gradingScore': record.gradingScore,
      'gradingDate': Timestamp.fromDate(record.gradingDate),
      'markedEligibleByAdminId': record.markedEligibleByAdminId,
      'eligibilityAnnouncedDate': record.eligibilityAnnouncedDate != null
          ? Timestamp.fromDate(record.eligibilityAnnouncedDate!)
          : null,
      'gradedByAdminId': record.gradedByAdminId,
      'notes': record.notes,
    };
  }
}
