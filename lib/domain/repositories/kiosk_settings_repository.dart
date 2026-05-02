import '../entities/kiosk_settings.dart';

abstract class KioskSettingsRepository {
  /// Returns the current kiosk settings, or null if none have been set.
  Future<KioskSettings?> get();

  /// Persists kiosk settings (creates or overwrites).
  Future<void> save(KioskSettings settings);
}
