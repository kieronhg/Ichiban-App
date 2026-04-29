import '../../repositories/app_settings_repository.dart';

class SaveGdprRetentionUseCase {
  const SaveGdprRetentionUseCase(this._settings);

  final AppSettingsRepository _settings;

  Future<void> call({required int gdprRetentionMonths}) async {
    if (gdprRetentionMonths < 1) {
      throw ArgumentError('Retention period must be at least 1 month');
    }
    await _settings.set('gdprRetentionMonths', gdprRetentionMonths);
  }
}
