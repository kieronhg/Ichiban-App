import 'package:equatable/equatable.dart';
import 'enums.dart';

/// The canonical promotion record for a student.
///
/// A [GradingRecord] is written only when a student is marked
/// [GradingOutcome.promoted]. Fails and absences are stored on
/// [GradingEventStudent] only.
class GradingRecord extends Equatable {
  final String id;
  final String studentId;
  final String disciplineId;
  final String enrollmentId;

  /// The grading event this record belongs to.
  final String gradingEventId;

  /// Rank held by the student at the time of grading.
  final String fromRankId;

  /// Rank the student was promoted to.
  final String rankAchievedId;

  final GradingOutcome outcome;

  /// Numeric score (0–100). Only populated for disciplines with
  /// [Discipline.hasGradingScore] = true (e.g. Karate). Null otherwise.
  final double? gradingScore;

  /// Denormalised from the grading event for efficient querying.
  final DateTime gradingDate;

  /// Admin who nominated the student for grading.
  final String markedEligibleByAdminId;

  /// When the eligibility notification was sent.
  final DateTime? eligibilityAnnouncedDate;

  /// Admin who recorded the result.
  final String gradedByAdminId;

  final String? notes;

  const GradingRecord({
    required this.id,
    required this.studentId,
    required this.disciplineId,
    required this.enrollmentId,
    required this.gradingEventId,
    required this.fromRankId,
    required this.rankAchievedId,
    required this.outcome,
    this.gradingScore,
    required this.gradingDate,
    required this.markedEligibleByAdminId,
    this.eligibilityAnnouncedDate,
    required this.gradedByAdminId,
    this.notes,
  });

  GradingRecord copyWith({
    String? id,
    String? studentId,
    String? disciplineId,
    String? enrollmentId,
    String? gradingEventId,
    String? fromRankId,
    String? rankAchievedId,
    GradingOutcome? outcome,
    double? gradingScore,
    DateTime? gradingDate,
    String? markedEligibleByAdminId,
    DateTime? eligibilityAnnouncedDate,
    String? gradedByAdminId,
    String? notes,
  }) {
    return GradingRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      disciplineId: disciplineId ?? this.disciplineId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      gradingEventId: gradingEventId ?? this.gradingEventId,
      fromRankId: fromRankId ?? this.fromRankId,
      rankAchievedId: rankAchievedId ?? this.rankAchievedId,
      outcome: outcome ?? this.outcome,
      gradingScore: gradingScore ?? this.gradingScore,
      gradingDate: gradingDate ?? this.gradingDate,
      markedEligibleByAdminId:
          markedEligibleByAdminId ?? this.markedEligibleByAdminId,
      eligibilityAnnouncedDate:
          eligibilityAnnouncedDate ?? this.eligibilityAnnouncedDate,
      gradedByAdminId: gradedByAdminId ?? this.gradedByAdminId,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    disciplineId,
    enrollmentId,
    gradingEventId,
    fromRankId,
    rankAchievedId,
    outcome,
    gradingScore,
    gradingDate,
    markedEligibleByAdminId,
    eligibilityAnnouncedDate,
    gradedByAdminId,
    notes,
  ];
}
