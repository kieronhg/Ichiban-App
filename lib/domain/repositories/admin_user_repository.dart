import '../entities/admin_user.dart';
import '../entities/enums.dart';

abstract interface class AdminUserRepository {
  /// Fetch a single admin user by Firebase UID. Returns null if not found.
  Future<AdminUser?> getById(String uid);

  /// Stream a single admin user by Firebase UID. Emits null if not found.
  Stream<AdminUser?> watchById(String uid);

  /// Stream all admin users ordered by lastName, firstName.
  Stream<List<AdminUser>> watchAll();

  /// Create a new adminUsers document. The Firebase Auth account must be
  /// created separately via Cloud Function before calling this.
  Future<void> create(AdminUser adminUser);

  /// Update editable fields on an existing admin user.
  Future<void> update(
    String uid, {
    String? firstName,
    String? lastName,
    String? email,
    List<String>? assignedDisciplineIds,
    String? profileId,
  });

  /// Soft-deactivate: sets isActive=false and records who did it.
  Future<void> deactivate(String uid, {required String deactivatedByAdminId});

  /// Re-activate a previously deactivated account.
  Future<void> reactivate(String uid);

  /// Delete the adminUsers document. Firebase Auth deletion handled by Cloud Function.
  Future<void> delete(String uid);

  /// Update the role field directly. Used by promote/demote use cases.
  Future<void> updateRole(
    String uid, {
    required AdminRole role,
    required List<String> assignedDisciplineIds,
  });

  /// Stamp lastLoginAt to now.
  Future<void> recordLogin(String uid);

  /// Count of documents where role == owner and isActive == true.
  Future<int> countActiveOwners();
}
