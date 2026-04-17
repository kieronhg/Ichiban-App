import '../entities/email_template.dart';

abstract class EmailTemplateRepository {
  /// Returns all email templates.
  Future<List<EmailTemplate>> getAll();

  /// Returns a single email template by key, or null if not found.
  Future<EmailTemplate?> getByKey(String key);

  /// Updates an existing email template's subject and body.
  Future<void> update(EmailTemplate template);

  /// Watches all email templates in real time.
  Stream<List<EmailTemplate>> watchAll();
}
