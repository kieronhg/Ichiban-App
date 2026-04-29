import '../../repositories/app_settings_repository.dart';
import '../../repositories/profile_repository.dart';

class SaveGeneralSettingsUseCase {
  const SaveGeneralSettingsUseCase(this._settings, this._profiles);

  final AppSettingsRepository _settings;
  final ProfileRepository _profiles;

  Future<void> call({
    required String dojoName,
    required String dojoEmail,
    required String privacyPolicyVersion,
  }) async {
    final current = await _settings.get('privacyPolicyVersion');
    final currentVersion = current?.stringValue ?? '1.0';

    await _settings.set('dojoName', dojoName);
    await _settings.set('dojoEmail', dojoEmail);
    await _settings.set('privacyPolicyVersion', privacyPolicyVersion);

    if (privacyPolicyVersion != currentVersion) {
      await _profiles.flagAllActiveForReConsent();
    }
  }
}
