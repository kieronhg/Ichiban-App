import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event.dart';

class GradingEventConverter {
  GradingEventConverter._();

  static GradingEvent fromMap(String id, Map<String, dynamic> map) {
    return GradingEvent(
      id: id,
      disciplineId: map['disciplineId'] as String,
      eventDate: (map['eventDate'] as Timestamp).toDate(),
      title: map['title'] as String?,
      status: GradingEventStatus.values.byName(map['status'] as String),
      createdByAdminId: map['createdByAdminId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
      startTime: map['startTime'] as String?,
      cancelledByAdminId: map['cancelledByAdminId'] as String?,
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(GradingEvent event) {
    return {
      'disciplineId': event.disciplineId,
      'eventDate': Timestamp.fromDate(event.eventDate),
      'title': event.title,
      'status': event.status.name,
      'createdByAdminId': event.createdByAdminId,
      'createdAt': Timestamp.fromDate(event.createdAt),
      'notes': event.notes,
      'startTime': event.startTime,
      'cancelledByAdminId': event.cancelledByAdminId,
      'cancelledAt': event.cancelledAt != null
          ? Timestamp.fromDate(event.cancelledAt!)
          : null,
    };
  }
}
