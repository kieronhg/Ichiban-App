import 'package:equatable/equatable.dart';

class GradingRecord extends Equatable {
  final String id;
  final String studentId;
  final String disciplineId;
  final String enrollmentId;
  final String rankAchievedId;
  final DateTime gradingDate;
  final String markedEligibleByCoachId;
  final DateTime? eligibilityAnnouncedDate;
  final String? notes;

  const GradingRecord({
    required this.id,
    required this.studentId,
    required this.disciplineId,
    required this.enrollmentId,
    required this.rankAchievedId,
    required this.gradingDate,
    required this.markedEligibleByCoachId,
    this.eligibilityAnnouncedDate,
    this.notes,
  });

  GradingRecord copyWith({
    String? id,
    String? studentId,
    String? disciplineId,
    String? enrollmentId,
    String? rankAchievedId,
    DateTime? gradingDate,
    String? markedEligibleByCoachId,
    DateTime? eligibilityAnnouncedDate,
    String? notes,
  }) {
    return GradingRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      disciplineId: disciplineId ?? this.disciplineId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      rankAchievedId: rankAchievedId ?? this.rankAchievedId,
      gradingDate: gradingDate ?? this.gradingDate,
      markedEligibleByCoachId: markedEligibleByCoachId ?? this.markedEligibleByCoachId,
      eligibilityAnnouncedDate: eligibilityAnnouncedDate ?? this.eligibilityAnnouncedDate,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id, studentId, disciplineId, enrollmentId, rankAchievedId,
        gradingDate, markedEligibleByCoachId, eligibilityAnnouncedDate, notes,
      ];
}
