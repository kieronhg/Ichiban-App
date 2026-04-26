import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/coach_profile.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/coach_profile_repository.dart';
import '../firebase/converters/coach_profile_converter.dart';
import '../firebase/firestore_collections.dart';

class FirestoreCoachProfileRepository implements CoachProfileRepository {
  @override
  Future<CoachProfile?> getById(String adminUserId) async {
    final snap = await FirestoreCollections.coachProfiles()
        .doc(adminUserId)
        .get();
    return snap.data();
  }

  @override
  Stream<CoachProfile?> watchById(String adminUserId) {
    return FirestoreCollections.coachProfiles()
        .doc(adminUserId)
        .snapshots()
        .map((snap) => snap.data());
  }

  @override
  Stream<List<CoachProfile>> watchAll() {
    return FirestoreCollections.coachProfiles().snapshots().map(
      (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }

  @override
  Future<void> create(CoachProfile coachProfile) async {
    await FirestoreCollections.coachProfiles()
        .doc(coachProfile.adminUserId)
        .set(coachProfile);
  }

  @override
  Future<void> updatePersonalDetails(
    String adminUserId, {
    String? qualificationsNotes,
  }) async {
    await FirestoreCollections.coachProfiles().doc(adminUserId).update({
      'qualificationsNotes': qualificationsNotes,
    });
  }

  @override
  Future<void> updateDbs(String adminUserId, DbsRecord dbs) async {
    await FirestoreCollections.coachProfiles().doc(adminUserId).update({
      'dbs': CoachProfileConverter.dbsToMap(dbs),
    });
  }

  @override
  Future<void> updateFirstAid(
    String adminUserId,
    FirstAidRecord firstAid,
  ) async {
    await FirestoreCollections.coachProfiles().doc(adminUserId).update({
      'firstAid': CoachProfileConverter.firstAidToMap(firstAid),
    });
  }

  @override
  Future<void> verify(
    String adminUserId, {
    required CoachComplianceType type,
    required String verifiedByAdminId,
    required DateTime verifiedAt,
  }) async {
    final prefix = type == CoachComplianceType.dbs ? 'dbs' : 'firstAid';
    await FirestoreCollections.coachProfiles().doc(adminUserId).update({
      '$prefix.pendingVerification': false,
      '$prefix.lastUpdatedByAdminId': verifiedByAdminId,
      '$prefix.lastUpdatedAt': Timestamp.fromDate(verifiedAt),
    });
  }
}
