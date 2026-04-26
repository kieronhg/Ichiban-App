import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_user.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/admin_user_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreAdminUserRepository implements AdminUserRepository {
  @override
  Future<AdminUser?> getById(String uid) async {
    final snap = await FirestoreCollections.adminUsers().doc(uid).get();
    return snap.data();
  }

  @override
  Stream<AdminUser?> watchById(String uid) {
    return FirestoreCollections.adminUsers()
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data());
  }

  @override
  Stream<List<AdminUser>> watchAll() {
    return FirestoreCollections.adminUsers()
        .orderBy('lastName')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<void> create(AdminUser adminUser) async {
    await FirestoreCollections.adminUsers()
        .doc(adminUser.firebaseUid)
        .set(adminUser);
  }

  @override
  Future<void> update(
    String uid, {
    String? firstName,
    String? lastName,
    String? email,
    List<String>? assignedDisciplineIds,
    String? profileId,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (email != null) data['email'] = email;
    if (assignedDisciplineIds != null) {
      data['assignedDisciplineIds'] = assignedDisciplineIds;
    }
    if (profileId != null) data['profileId'] = profileId;
    if (data.isEmpty) return;
    await FirestoreCollections.adminUsers().doc(uid).update(data);
  }

  @override
  Future<void> deactivate(
    String uid, {
    required String deactivatedByAdminId,
  }) async {
    await FirestoreCollections.adminUsers().doc(uid).update({
      'isActive': false,
      'deactivatedAt': Timestamp.fromDate(DateTime.now()),
      'deactivatedByAdminId': deactivatedByAdminId,
    });
  }

  @override
  Future<void> reactivate(String uid) async {
    await FirestoreCollections.adminUsers().doc(uid).update({
      'isActive': true,
      'deactivatedAt': null,
      'deactivatedByAdminId': null,
    });
  }

  @override
  Future<void> delete(String uid) async {
    await FirestoreCollections.adminUsers().doc(uid).delete();
  }

  @override
  Future<void> updateRole(
    String uid, {
    required AdminRole role,
    required List<String> assignedDisciplineIds,
  }) async {
    await FirestoreCollections.adminUsers().doc(uid).update({
      'role': role.name,
      'assignedDisciplineIds': assignedDisciplineIds,
    });
  }

  @override
  Future<void> recordLogin(String uid) async {
    await FirestoreCollections.adminUsers().doc(uid).update({
      'lastLoginAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<int> countActiveOwners() async {
    final snap = await FirestoreCollections.adminUsers()
        .where('role', isEqualTo: AdminRole.owner.name)
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    return snap.count ?? 0;
  }
}
