import '../../domain/entities/app_setting.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreAppSettingsRepository implements AppSettingsRepository {
  @override
  Future<AppSetting?> get(String key) async {
    final snap = await FirestoreCollections.appSettings().doc(key).get();
    return snap.data();
  }

  @override
  Future<Map<String, dynamic>> getAll() async {
    final snap = await FirestoreCollections.appSettings().get();
    return {for (final doc in snap.docs) doc.id: doc.data().value};
  }

  @override
  Future<void> set(String key, dynamic value) async {
    await FirestoreCollections.appSettings()
        .doc(key)
        .set(AppSetting(key: key, value: value));
  }

  @override
  Stream<AppSetting?> watch(String key) {
    return FirestoreCollections.appSettings()
        .doc(key)
        .snapshots()
        .map((snap) => snap.data());
  }
}
