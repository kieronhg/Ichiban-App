import 'package:equatable/equatable.dart';
import 'enums.dart';

/// A formal grading event for a single discipline.
class GradingEvent extends Equatable {
  final String id;
  final String disciplineId;
  final DateTime eventDate;

  /// Optional human-readable title, e.g. "Spring Grading 2025".
  final String? title;

  final GradingEventStatus status;
  final String createdByAdminId;
  final DateTime createdAt;
  final String? notes;

  /// Set when [status] = [GradingEventStatus.cancelled].
  final String? cancelledByAdminId;
  final DateTime? cancelledAt;

  const GradingEvent({
    required this.id,
    required this.disciplineId,
    required this.eventDate,
    this.title,
    required this.status,
    required this.createdByAdminId,
    required this.createdAt,
    this.notes,
    this.cancelledByAdminId,
    this.cancelledAt,
  });

  GradingEvent copyWith({
    String? id,
    String? disciplineId,
    DateTime? eventDate,
    String? title,
    GradingEventStatus? status,
    String? createdByAdminId,
    DateTime? createdAt,
    String? notes,
    String? cancelledByAdminId,
    DateTime? cancelledAt,
  }) {
    return GradingEvent(
      id: id ?? this.id,
      disciplineId: disciplineId ?? this.disciplineId,
      eventDate: eventDate ?? this.eventDate,
      title: title ?? this.title,
      status: status ?? this.status,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      cancelledByAdminId: cancelledByAdminId ?? this.cancelledByAdminId,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    disciplineId,
    eventDate,
    title,
    status,
    createdByAdminId,
    createdAt,
    notes,
    cancelledByAdminId,
    cancelledAt,
  ];
}
