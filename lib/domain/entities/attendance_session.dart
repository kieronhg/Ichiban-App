import 'package:equatable/equatable.dart';

class AttendanceSession extends Equatable {
  final String id;
  final String disciplineId;

  /// Date portion only — time component is midnight UTC.
  final DateTime sessionDate;

  /// 24-hour time string, e.g. "18:00".
  final String startTime;

  /// 24-hour time string, e.g. "19:30".
  final String endTime;

  final String? notes;
  final String createdByAdminId;
  final DateTime createdAt;

  const AttendanceSession({
    required this.id,
    required this.disciplineId,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.createdByAdminId,
    required this.createdAt,
  });

  AttendanceSession copyWith({
    String? id,
    String? disciplineId,
    DateTime? sessionDate,
    String? startTime,
    String? endTime,
    String? notes,
    String? createdByAdminId,
    DateTime? createdAt,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      disciplineId: disciplineId ?? this.disciplineId,
      sessionDate: sessionDate ?? this.sessionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    disciplineId,
    sessionDate,
    startTime,
    endTime,
    notes,
    createdByAdminId,
    createdAt,
  ];
}
