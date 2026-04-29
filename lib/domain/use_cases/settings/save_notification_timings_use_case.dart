import '../../repositories/app_settings_repository.dart';

class SaveNotificationTimingsUseCase {
  const SaveNotificationTimingsUseCase(this._settings);

  final AppSettingsRepository _settings;

  Future<void> call({
    required int renewalReminderDays,
    required int lapseReminderPreDueDays,
    required int lapseReminderPostDueDays,
    required int trialExpiryReminderDays,
    required int dbsExpiryAlertDays,
    required int firstAidExpiryAlertDays,
    required int licenceReminderDays,
  }) async {
    await _settings.set('renewalReminderDays', renewalReminderDays);
    await _settings.set('lapseReminderPreDueDays', lapseReminderPreDueDays);
    await _settings.set('lapseReminderPostDueDays', lapseReminderPostDueDays);
    await _settings.set('trialExpiryReminderDays', trialExpiryReminderDays);
    await _settings.set('dbsExpiryAlertDays', dbsExpiryAlertDays);
    await _settings.set('firstAidExpiryAlertDays', firstAidExpiryAlertDays);
    await _settings.set('licenceReminderDays', licenceReminderDays);
  }
}
