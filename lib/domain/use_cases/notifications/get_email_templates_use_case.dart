import '../../entities/email_template.dart';
import '../../repositories/email_template_repository.dart';

class GetEmailTemplatesUseCase {
  const GetEmailTemplatesUseCase(this._repo);

  final EmailTemplateRepository _repo;

  Stream<List<EmailTemplate>> watchAll() => _repo.watchAll();

  Future<EmailTemplate?> getByKey(String key) => _repo.getByKey(key);
}
