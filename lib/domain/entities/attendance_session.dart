import 'package:equatable/equatable.dart';

class AttendanceSession extends Equatable {
  final String id;
  final String disciplineId;
  final DateTime sessionDate;
  final String? notes;
  final String createdByCoachId;

  const AttendanceSession({
    required this.id,
    required this.disciplineId,
    required this.sessionDate,
    this.notes,
    required this.createdByCoachId,
  });

  AttendanceSession copyWith({
    String? id,
    String? disciplineId,
    DateTime? sessionDate,
    String? notes,
    String? createdByCoachId,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      disciplineId: disciplineId ?? this.disciplineId,
      sessionDate: sessionDate ?? this.sessionDate,
      notes: notes ?? this.notes,
      createdByCoachId: createdByCoachId ?? this.createdByCoachId,
    );
  }

  @override
  List<Object?> get props => [id, disciplineId, sessionDate, notes, createdByCoachId];
}
