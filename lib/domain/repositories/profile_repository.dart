import '../entities/profile.dart';
import '../entities/enums.dart';

abstract class ProfileRepository {
  /// Returns a single profile by ID, or null if not found.
  Future<Profile?> getById(String id);

  /// Returns the profile whose Firebase Auth UID matches [uid], or null.
  Future<Profile?> findByUid(String uid);

  /// Returns the profile whose email address matches [email], or null.
  Future<Profile?> findByEmail(String email);

  /// Returns all profiles in the system.
  Future<List<Profile>> getAll();

  /// Returns all profiles that include the given type in their profileTypes list.
  Future<List<Profile>> getByType(ProfileType type);

  /// Returns all junior profiles linked to a given parent/guardian.
  Future<List<Profile>> getJuniorsForParent(String parentProfileId);

  /// Creates a new profile and returns the generated document ID.
  Future<String> create(Profile profile);

  /// Updates an existing profile.
  Future<void> update(Profile profile);

  /// Soft-deletes a profile by setting isActive to false.
  Future<void> deactivate(String id);

  /// Clears the PIN hash for a profile so the student must set a new PIN
  /// before they can sign in again.
  Future<void> resetPin(String id);

  /// Sets requiresReConsent=true on all active, non-anonymised profiles.
  /// Used when the owner updates the privacy policy version.
  Future<void> flagAllActiveForReConsent();

  /// Anonymises a profile under Right to Erasure.
  ///
  /// Replaces all personal data fields with placeholder values and sets
  /// [isAnonymised] to true and [anonymisedAt] to now.
  Future<void> anonymise(String id);

  /// Updates only the invite fields on a profile.
  Future<void> updateInviteStatus({
    required String id,
    required InviteStatus status,
    DateTime? sentAt,
    DateTime? expiresAt,
    int? resendCount,
  });

  /// Returns all profiles where inviteStatus is pending.
  Future<List<Profile>> getPendingInvites();

  /// Watches all profiles in real time.
  Stream<List<Profile>> watchAll();

  /// Watches a single profile in real time.
  Stream<Profile?> watchById(String id);

  /// Watches profiles where inviteStatus is pending in real time.
  Stream<List<Profile>> watchPendingInvites();
}
