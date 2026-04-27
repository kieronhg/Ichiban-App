import '../../entities/email_template.dart';
import '../../repositories/email_template_repository.dart';

class SaveEmailTemplateUseCase {
  const SaveEmailTemplateUseCase(this._repo);

  final EmailTemplateRepository _repo;

  Future<void> call(EmailTemplate template) => _repo.update(template);
}
