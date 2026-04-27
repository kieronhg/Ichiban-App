import 'package:equatable/equatable.dart';
import 'enums.dart';

class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.sentByAdminId,
    required this.sentAt,
    required this.channel,
    required this.audience,
    this.disciplineId,
    required this.recipientCount,
    required this.deliveredCount,
    required this.failedCount,
  });

  final String id;
  final String title;
  final String body;
  final String sentByAdminId;
  final DateTime sentAt;
  final AnnouncementChannel channel;
  final AnnouncementAudience audience;

  /// Set when audience == AnnouncementAudience.discipline.
  final String? disciplineId;

  final int recipientCount;
  final int deliveredCount;
  final int failedCount;

  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    String? sentByAdminId,
    DateTime? sentAt,
    AnnouncementChannel? channel,
    AnnouncementAudience? audience,
    String? disciplineId,
    int? recipientCount,
    int? deliveredCount,
    int? failedCount,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      sentByAdminId: sentByAdminId ?? this.sentByAdminId,
      sentAt: sentAt ?? this.sentAt,
      channel: channel ?? this.channel,
      audience: audience ?? this.audience,
      disciplineId: disciplineId ?? this.disciplineId,
      recipientCount: recipientCount ?? this.recipientCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      failedCount: failedCount ?? this.failedCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    sentByAdminId,
    sentAt,
    channel,
    audience,
    disciplineId,
    recipientCount,
    deliveredCount,
    failedCount,
  ];
}
