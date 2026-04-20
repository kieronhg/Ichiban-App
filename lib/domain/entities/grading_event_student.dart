import 'package:equatable/equatable.dart';
import 'enums.dart';

/// Per-student nomination and outcome record linked to a [GradingEvent].
///
/// Written when admin nominates a student. [outcome] is null until results
/// are recorded. A [GradingRecord] is additionally written when
/// [outcome] = [GradingOutcome.promoted].
class GradingEventStudent extends Equatable {
  final String id;
  final String gradingEventId;
  final String studentId;

  /// Denormalised for querying without loading the event document.
  final String disciplineId;

  final String enrollmentId;

  /// Rank held at the time of nomination.
  final String currentRankId;

  final String nominatedByAdminId;
  final DateTime nominatedAt;

  /// When the eligibility push notification was sent. Null until sent.
  final DateTime? notificationSentAt;

  /// Null until results are recorded.
  final GradingOutcome? outcome;

  /// Set when [outcome] = [GradingOutcome.promoted].
  final String? rankAchievedId;

  /// Numeric score (0–100). Disciplines with [Discipline.hasGradingScore] only.
  final double? gradingScore;

  final String? resultRecordedByAdminId;
  final DateTime? resultRecordedAt;
  final String? notes;

  const GradingEventStudent({
    required this.id,
    required this.gradingEventId,
    required this.studentId,
    required this.disciplineId,
    required this.enrollmentId,
    required this.currentRankId,
    required this.nominatedByAdminId,
    required this.nominatedAt,
    this.notificationSentAt,
    this.outcome,
    this.rankAchievedId,
    this.gradingScore,
    this.resultRecordedByAdminId,
    this.resultRecordedAt,
    this.notes,
  });

  GradingEventStudent copyWith({
    String? id,
    String? gradingEventId,
    String? studentId,
    String? disciplineId,
    String? enrollmentId,
    String? currentRankId,
    String? nominatedByAdminId,
    DateTime? nominatedAt,
    DateTime? notificationSentAt,
    GradingOutcome? outcome,
    String? rankAchievedId,
    double? gradingScore,
    String? resultRecordedByAdminId,
    DateTime? resultRecordedAt,
    String? notes,
  }) {
    return GradingEventStudent(
      id: id ?? this.id,
      gradingEventId: gradingEventId ?? this.gradingEventId,
      studentId: studentId ?? this.studentId,
      disciplineId: disciplineId ?? this.disciplineId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      currentRankId: currentRankId ?? this.currentRankId,
      nominatedByAdminId: nominatedByAdminId ?? this.nominatedByAdminId,
      nominatedAt: nominatedAt ?? this.nominatedAt,
      notificationSentAt: notificationSentAt ?? this.notificationSentAt,
      outcome: outcome ?? this.outcome,
      rankAchievedId: rankAchievedId ?? this.rankAchievedId,
      gradingScore: gradingScore ?? this.gradingScore,
      resultRecordedByAdminId:
          resultRecordedByAdminId ?? this.resultRecordedByAdminId,
      resultRecordedAt: resultRecordedAt ?? this.resultRecordedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    gradingEventId,
    studentId,
    disciplineId,
    enrollmentId,
    currentRankId,
    nominatedByAdminId,
    nominatedAt,
    notificationSentAt,
    outcome,
    rankAchievedId,
    gradingScore,
    resultRecordedByAdminId,
    resultRecordedAt,
    notes,
  ];
}
