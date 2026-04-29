import '../../repositories/app_settings_repository.dart';
import '../../repositories/profile_repository.dart';

class RecordReConsentUseCase {
  const RecordReConsentUseCase(this._profiles, this._settings);

  final ProfileRepository _profiles;
  final AppSettingsRepository _settings;

  Future<void> call(String profileId) async {
    final profile = await _profiles.getById(profileId);
    if (profile == null) throw StateError('Profile not found: $profileId');

    final versionSetting = await _settings.get('privacyPolicyVersion');
    final currentVersion = versionSetting?.stringValue ?? '1.0';

    await _profiles.update(
      profile.copyWith(
        requiresReConsent: false,
        dataProcessingConsentVersion: currentVersion,
        dataProcessingConsentDate: DateTime.now(),
      ),
    );
  }
}
