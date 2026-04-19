import 'package:equatable/equatable.dart';
import 'enums.dart';

class AttendanceRecord extends Equatable {
  final String id;
  final String sessionId;
  final String studentId;
  final String disciplineId;

  // Denormalised for querying without needing the session document
  final DateTime sessionDate;

  final CheckInMethod checkInMethod;

  // Set when a coach marks attendance; null for self check-in
  final String? checkedInByProfileId;

  final DateTime timestamp;

  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.disciplineId,
    required this.sessionDate,
    required this.checkInMethod,
    this.checkedInByProfileId,
    required this.timestamp,
  });

  AttendanceRecord copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    String? disciplineId,
    DateTime? sessionDate,
    CheckInMethod? checkInMethod,
    String? checkedInByProfileId,
    DateTime? timestamp,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      disciplineId: disciplineId ?? this.disciplineId,
      sessionDate: sessionDate ?? this.sessionDate,
      checkInMethod: checkInMethod ?? this.checkInMethod,
      checkedInByProfileId: checkedInByProfileId ?? this.checkedInByProfileId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sessionId,
    studentId,
    disciplineId,
    sessionDate,
    checkInMethod,
    checkedInByProfileId,
    timestamp,
  ];
}
