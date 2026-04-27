import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/notification_log.dart';
import '../../../domain/entities/enums.dart';

class NotificationLogConverter {
  NotificationLogConverter._();

  static NotificationLog fromMap(String id, Map<String, dynamic> map) {
    return NotificationLog(
      id: id,
      recipientProfileId: map['recipientProfileId'] as String,
      recipientType: RecipientType.values.byName(
        (map['recipientType'] as String?) ?? RecipientType.member.name,
      ),
      channel: NotificationChannel.values.byName(map['channel'] as String),
      type: NotificationType.values.byName(map['type'] as String),
      deliveryStatus: NotificationDeliveryStatus.values.byName(
        (map['deliveryStatus'] as String?) ??
            NotificationDeliveryStatus.sent.name,
      ),
      sentAt: (map['sentAt'] as Timestamp).toDate(),
      title: map['title'] as String?,
      body: map['body'] as String?,
      isRead: map['isRead'] as bool?,
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
      emailTemplateKey: map['emailTemplateKey'] as String?,
      emailSubject: map['emailSubject'] as String?,
      suppressionReason: map['suppressionReason'] as String?,
      failureReason: map['failureReason'] as String?,
      announcementId: map['announcementId'] as String?,
    );
  }

  static Map<String, dynamic> toMap(NotificationLog log) {
    return {
      'recipientProfileId': log.recipientProfileId,
      'recipientType': log.recipientType.name,
      'channel': log.channel.name,
      'type': log.type.name,
      'deliveryStatus': log.deliveryStatus.name,
      'sentAt': Timestamp.fromDate(log.sentAt),
      'title': log.title,
      'body': log.body,
      'isRead': log.isRead,
      'readAt': log.readAt != null ? Timestamp.fromDate(log.readAt!) : null,
      'emailTemplateKey': log.emailTemplateKey,
      'emailSubject': log.emailSubject,
      'suppressionReason': log.suppressionReason,
      'failureReason': log.failureReason,
      'announcementId': log.announcementId,
    };
  }
}
