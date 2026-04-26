import '../../domain/entities/app_setup.dart';
import '../../domain/repositories/app_setup_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreAppSetupRepository implements AppSetupRepository {
  @override
  Future<AppSetup> getSetupStatus() async {
    final snap = await FirestoreCollections.appSetupDoc().get();
    return snap.data() ?? const AppSetup(setupComplete: false);
  }

  @override
  Stream<AppSetup> watchSetupStatus() {
    return FirestoreCollections.appSetupDoc().snapshots().map(
      (snap) => snap.data() ?? const AppSetup(setupComplete: false),
    );
  }

  @override
  Future<void> markComplete({required String setupCompletedByAdminId}) async {
    await FirestoreCollections.appSetupDoc().set(
      AppSetup(
        setupComplete: true,
        setupCompletedAt: DateTime.now(),
        setupCompletedByAdminId: setupCompletedByAdminId,
      ),
    );
  }
}
