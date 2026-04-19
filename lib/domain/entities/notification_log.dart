import 'package:equatable/equatable.dart';
import 'enums.dart';

class NotificationLog extends Equatable {
  final String id;
  final String recipientProfileId;
  final NotificationChannel channel;
  final NotificationType type;

  // Push only
  final String? title;
  final String? body;
  final bool? isRead;

  // Email only
  final String? emailTemplateKey;
  final EmailDeliveryStatus? deliveryStatus;

  final DateTime sentAt;

  const NotificationLog({
    required this.id,
    required this.recipientProfileId,
    required this.channel,
    required this.type,
    this.title,
    this.body,
    this.isRead,
    this.emailTemplateKey,
    this.deliveryStatus,
    required this.sentAt,
  });

  NotificationLog copyWith({
    String? id,
    String? recipientProfileId,
    NotificationChannel? channel,
    NotificationType? type,
    String? title,
    String? body,
    bool? isRead,
    String? emailTemplateKey,
    EmailDeliveryStatus? deliveryStatus,
    DateTime? sentAt,
  }) {
    return NotificationLog(
      id: id ?? this.id,
      recipientProfileId: recipientProfileId ?? this.recipientProfileId,
      channel: channel ?? this.channel,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      emailTemplateKey: emailTemplateKey ?? this.emailTemplateKey,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    recipientProfileId,
    channel,
    type,
    title,
    body,
    isRead,
    emailTemplateKey,
    deliveryStatus,
    sentAt,
  ];
}
