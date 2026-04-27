import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/announcement.dart';
import '../../../domain/entities/enums.dart';

class AnnouncementConverter {
  AnnouncementConverter._();

  static Announcement fromMap(String id, Map<String, dynamic> map) {
    return Announcement(
      id: id,
      title: map['title'] as String,
      body: map['body'] as String,
      sentByAdminId: map['sentByAdminId'] as String,
      sentAt: (map['sentAt'] as Timestamp).toDate(),
      channel: AnnouncementChannel.values.byName(map['channel'] as String),
      audience: AnnouncementAudience.values.byName(map['audience'] as String),
      disciplineId: map['disciplineId'] as String?,
      recipientCount: (map['recipientCount'] as num).toInt(),
      deliveredCount: (map['deliveredCount'] as num).toInt(),
      failedCount: (map['failedCount'] as num).toInt(),
    );
  }

  static Map<String, dynamic> toMap(Announcement announcement) {
    return {
      'title': announcement.title,
      'body': announcement.body,
      'sentByAdminId': announcement.sentByAdminId,
      'sentAt': Timestamp.fromDate(announcement.sentAt),
      'channel': announcement.channel.name,
      'audience': announcement.audience.name,
      'disciplineId': announcement.disciplineId,
      'recipientCount': announcement.recipientCount,
      'deliveredCount': announcement.deliveredCount,
      'failedCount': announcement.failedCount,
    };
  }
}
