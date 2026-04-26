import '../entities/app_setup.dart';

abstract interface class AppSetupRepository {
  /// Returns current setup status. Returns a default incomplete state if the
  /// document does not yet exist.
  Future<AppSetup> getSetupStatus();

  /// Stream the setup status document in real time.
  Stream<AppSetup> watchSetupStatus();

  /// Mark the wizard as complete and record who ran it.
  Future<void> markComplete({required String setupCompletedByAdminId});
}
