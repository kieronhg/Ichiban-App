import '../entities/membership.dart';
import '../entities/enums.dart';

abstract class MembershipRepository {
  /// Returns a single membership by ID, or null if not found.
  Future<Membership?> getById(String id);

  /// Returns the active membership for a given profile, or null.
  Future<Membership?> getActiveForProfile(String profileId);

  /// Returns all memberships with a given status.
  Future<List<Membership>> getByStatus(MembershipStatus status);

  /// Returns memberships whose subscriptionRenewalDate falls within [withinDays] days.
  Future<List<Membership>> getExpiringWithin(int withinDays);

  /// Returns memberships whose trial is expiring within [withinDays] days.
  Future<List<Membership>> getTrialsExpiringWithin(int withinDays);

  /// Creates a new membership and returns the generated document ID.
  Future<String> create(Membership membership);

  /// Updates an existing membership document.
  Future<void> update(Membership membership);

  /// Updates only the status field of a membership.
  Future<void> updateStatus(String id, MembershipStatus status);

  /// Adds a profile to a family membership's memberProfileIds array
  /// and recalculates familyPricingTier from the new member count.
  Future<void> addFamilyMember(String membershipId, String profileId);

  /// Removes a profile from a family membership's memberProfileIds array
  /// and recalculates familyPricingTier from the new member count.
  Future<void> removeFamilyMember(String membershipId, String profileId);

  /// Watches all memberships in real time.
  Stream<List<Membership>> watchAll();

  /// Watches a single membership in real time.
  Stream<Membership?> watchById(String id);
}
