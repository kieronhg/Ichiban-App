import '../../domain/entities/email_template.dart';
import '../../domain/repositories/email_template_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreEmailTemplateRepository implements EmailTemplateRepository {
  @override
  Future<List<EmailTemplate>> getAll() async {
    final snap = await FirestoreCollections.emailTemplates().get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<EmailTemplate?> getByKey(String key) async {
    final snap =
        await FirestoreCollections.emailTemplates().doc(key).get();
    return snap.data();
  }

  @override
  Future<void> update(EmailTemplate template) async {
    await FirestoreCollections.emailTemplates()
        .doc(template.key)
        .set(template);
  }

  @override
  Stream<List<EmailTemplate>> watchAll() {
    return FirestoreCollections.emailTemplates()
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
