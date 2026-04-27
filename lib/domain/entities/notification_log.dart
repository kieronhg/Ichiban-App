import 'package:equatable/equatable.dart';
import 'enums.dart';

class NotificationLog extends Equatable {
  const NotificationLog({
    required this.id,
    required this.recipientProfileId,
    required this.recipientType,
    required this.channel,
    required this.type,
    required this.deliveryStatus,
    required this.sentAt,
    this.title,
    this.body,
    this.isRead,
    this.readAt,
    this.emailTemplateKey,
    this.emailSubject,
    this.suppressionReason,
    this.failureReason,
    this.announcementId,
  });

  final String id;
  final String recipientProfileId;
  final RecipientType recipientType;
  final NotificationChannel channel;
  final NotificationType type;
  final NotificationDeliveryStatus deliveryStatus;
  final DateTime sentAt;

  // Push only
  final String? title;
  final String? body;
  final bool? isRead;
  final DateTime? readAt;

  // Email only
  final String? emailTemplateKey;
  final String? emailSubject;

  // Failure / suppression
  final String? suppressionReason;
  final String? failureReason;

  // Set for announcement notifications
  final String? announcementId;

  NotificationLog copyWith({
    String? id,
    String? recipientProfileId,
    RecipientType? recipientType,
    NotificationChannel? channel,
    NotificationType? type,
    NotificationDeliveryStatus? deliveryStatus,
    DateTime? sentAt,
    String? title,
    String? body,
    bool? isRead,
    DateTime? readAt,
    String? emailTemplateKey,
    String? emailSubject,
    String? suppressionReason,
    String? failureReason,
    String? announcementId,
  }) {
    return NotificationLog(
      id: id ?? this.id,
      recipientProfileId: recipientProfileId ?? this.recipientProfileId,
      recipientType: recipientType ?? this.recipientType,
      channel: channel ?? this.channel,
      type: type ?? this.type,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      sentAt: sentAt ?? this.sentAt,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      emailTemplateKey: emailTemplateKey ?? this.emailTemplateKey,
      emailSubject: emailSubject ?? this.emailSubject,
      suppressionReason: suppressionReason ?? this.suppressionReason,
      failureReason: failureReason ?? this.failureReason,
      announcementId: announcementId ?? this.announcementId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    recipientProfileId,
    recipientType,
    channel,
    type,
    deliveryStatus,
    sentAt,
    title,
    body,
    isRead,
    readAt,
    emailTemplateKey,
    emailSubject,
    suppressionReason,
    failureReason,
    announcementId,
  ];
}
