import 'package:equatable/equatable.dart';

// Supported substitution variables (replaced at send time by Cloud Functions):
// {{memberName}}, {{dojoName}}, {{renewalDate}},
// {{trialEndDate}}, {{amount}}, {{gradingDate}}
class EmailTemplate extends Equatable {
  final String key;
  final String subject;
  final String bodyHtml;
  final String? lastEditedByAdminId;
  final DateTime? lastEditedAt;

  const EmailTemplate({
    required this.key,
    required this.subject,
    required this.bodyHtml,
    this.lastEditedByAdminId,
    this.lastEditedAt,
  });

  EmailTemplate copyWith({
    String? key,
    String? subject,
    String? bodyHtml,
    String? lastEditedByAdminId,
    DateTime? lastEditedAt,
  }) {
    return EmailTemplate(
      key: key ?? this.key,
      subject: subject ?? this.subject,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      lastEditedByAdminId: lastEditedByAdminId ?? this.lastEditedByAdminId,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
    );
  }

  @override
  List<Object?> get props => [key, subject, bodyHtml, lastEditedByAdminId, lastEditedAt];
}
