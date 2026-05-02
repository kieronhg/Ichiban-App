import 'package:equatable/equatable.dart';

class AttendanceSession extends Equatable {
  final String id;

  /// Coach-given name, e.g. "Kids Karate Class".
  final String? title;

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

  /// Whether this session is part of a weekly recurring series.
  final bool isRecurring;

  /// Shared across all sessions in the same recurring series.
  final String? recurringGroupId;

  const AttendanceSession({
    required this.id,
    this.title,
    required this.disciplineId,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.createdByAdminId,
    required this.createdAt,
    this.isRecurring = false,
    this.recurringGroupId,
  });

  AttendanceSession copyWith({
    String? id,
    Object? title = _sentinel,
    String? disciplineId,
    DateTime? sessionDate,
    String? startTime,
    String? endTime,
    Object? notes = _sentinel,
    String? createdByAdminId,
    DateTime? createdAt,
    bool? isRecurring,
    Object? recurringGroupId = _sentinel,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      title: title == _sentinel ? this.title : title as String?,
      disciplineId: disciplineId ?? this.disciplineId,
      sessionDate: sessionDate ?? this.sessionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes == _sentinel ? this.notes : notes as String?,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdAt: createdAt ?? this.createdAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringGroupId: recurringGroupId == _sentinel
          ? this.recurringGroupId
          : recurringGroupId as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    disciplineId,
    sessionDate,
    startTime,
    endTime,
    notes,
    createdByAdminId,
    createdAt,
    isRecurring,
    recurringGroupId,
  ];
}

// Sentinel for nullable copyWith fields.
const Object _sentinel = Object();
