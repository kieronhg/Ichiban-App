import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/notification_log.dart';
import '../../../domain/entities/enums.dart';

class NotificationLogConverter {
  NotificationLogConverter._();

  static NotificationLog fromMap(String id, Map<String, dynamic> map) {
    return NotificationLog(
      id: id,
      recipientProfileId: map['recipientProfileId'] as String,
      channel: NotificationChannel.values.byName(map['channel'] as String),
      type: NotificationType.values.byName(map['type'] as String),
      title: map['title'] as String?,
      body: map['body'] as String?,
      isRead: map['isRead'] as bool?,
      emailTemplateKey: map['emailTemplateKey'] as String?,
      deliveryStatus: map['deliveryStatus'] != null
          ? EmailDeliveryStatus.values.byName(map['deliveryStatus'] as String)
          : null,
      sentAt: (map['sentAt'] as Timestamp).toDate(),
    );
  }

  static Map<String, dynamic> toMap(NotificationLog log) {
    return {
      'recipientProfileId': log.recipientProfileId,
      'channel': log.channel.name,
      'type': log.type.name,
      'title': log.title,
      'body': log.body,
      'isRead': log.isRead,
      'emailTemplateKey': log.emailTemplateKey,
      'deliveryStatus': log.deliveryStatus?.name,
      'sentAt': Timestamp.fromDate(log.sentAt),
    };
  }
}
