import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/email_template.dart';

class EmailTemplateConverter {
  EmailTemplateConverter._();

  static EmailTemplate fromMap(String key, Map<String, dynamic> map) {
    return EmailTemplate(
      key: key,
      subject: map['subject'] as String,
      bodyHtml: map['bodyHtml'] as String,
      lastEditedByAdminId: map['lastEditedByAdminId'] as String?,
      lastEditedAt: (map['lastEditedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(EmailTemplate template) {
    return {
      'subject': template.subject,
      'bodyHtml': template.bodyHtml,
      'lastEditedByAdminId': template.lastEditedByAdminId,
      'lastEditedAt': template.lastEditedAt != null
          ? Timestamp.fromDate(template.lastEditedAt!)
          : null,
    };
  }
}
