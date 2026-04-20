import 'package:equatable/equatable.dart';
import 'enums.dart';

/// A check-in made by a student when no session existed yet for that
/// discipline on that day. Automatically resolved when admin creates the
/// matching session (same discipline + same date). Can also be manually
/// discarded by an admin.
class QueuedCheckIn extends Equatable {
  final String id;
  final String studentId;
  final String disciplineId;

  /// Exact timestamp when the student queued the check-in.
  final DateTime queuedAt;

  /// Date portion only (midnight UTC) — used to match against session dates.
  final DateTime queueDate;

  final QueuedCheckInStatus status;

  /// Set when status → resolved; references the session that resolved it.
  final String? resolvedSessionId;
  final DateTime? resolvedAt;

  /// Set when status → discarded by admin.
  final String? discardedByAdminId;
  final DateTime? discardedAt;

  const QueuedCheckIn({
    required this.id,
    required this.studentId,
    required this.disciplineId,
    required this.queuedAt,
    required this.queueDate,
    required this.status,
    this.resolvedSessionId,
    this.resolvedAt,
    this.discardedByAdminId,
    this.discardedAt,
  });

  QueuedCheckIn copyWith({
    String? id,
    String? studentId,
    String? disciplineId,
    DateTime? queuedAt,
    DateTime? queueDate,
    QueuedCheckInStatus? status,
    String? resolvedSessionId,
    DateTime? resolvedAt,
    String? discardedByAdminId,
    DateTime? discardedAt,
  }) {
    return QueuedCheckIn(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      disciplineId: disciplineId ?? this.disciplineId,
      queuedAt: queuedAt ?? this.queuedAt,
      queueDate: queueDate ?? this.queueDate,
      status: status ?? this.status,
      resolvedSessionId: resolvedSessionId ?? this.resolvedSessionId,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      discardedByAdminId: discardedByAdminId ?? this.discardedByAdminId,
      discardedAt: discardedAt ?? this.discardedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    disciplineId,
    queuedAt,
    queueDate,
    status,
    resolvedSessionId,
    resolvedAt,
    discardedByAdminId,
    discardedAt,
  ];
}
