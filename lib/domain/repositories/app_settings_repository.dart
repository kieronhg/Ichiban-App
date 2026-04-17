import '../entities/app_setting.dart';

abstract class AppSettingsRepository {
  /// Returns a single setting by key, or null if not found.
  Future<AppSetting?> get(String key);

  /// Returns all app settings as a map of key → value.
  Future<Map<String, dynamic>> getAll();

  /// Writes or updates a setting value.
  Future<void> set(String key, dynamic value);

  /// Watches a single setting in real time.
  Stream<AppSetting?> watch(String key);
}
