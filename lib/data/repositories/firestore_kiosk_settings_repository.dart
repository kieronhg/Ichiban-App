import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/kiosk_settings.dart';
import '../../domain/repositories/kiosk_settings_repository.dart';

class FirestoreKioskSettingsRepository implements KioskSettingsRepository {
  static const _collection = 'appSettings';
  static const _docId = 'kioskSettings';

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection(_collection).doc(_docId);

  @override
  Future<KioskSettings?> get() async {
    final snap = await _doc.get();
    final data = snap.data();
    if (data == null) return null;
    return KioskSettings(
      kioskExitPinHash: data['kioskExitPinHash'] as String,
      kioskExitPinSetAt: (data['kioskExitPinSetAt'] as Timestamp).toDate(),
      kioskExitPinSetByAdminId: data['kioskExitPinSetByAdminId'] as String,
    );
  }

  @override
  Future<void> save(KioskSettings settings) async {
    await _doc.set({
      'kioskExitPinHash': settings.kioskExitPinHash,
      'kioskExitPinSetAt': Timestamp.fromDate(settings.kioskExitPinSetAt),
      'kioskExitPinSetByAdminId': settings.kioskExitPinSetByAdminId,
    });
  }
}
