import '../entities/membership.dart';
import '../entities/enums.dart';

abstract class MembershipRepository {
  /// Returns a single membership by ID, or null if not found.
  Future<Membership?> getById(String id);

  /// Returns all memberships (any status) where [profileId] is in memberProfileIds.
  Future<List<Membership>> getForProfile(String profileId);

  /// Returns the active or payt membership for a given profile, or null.
  Future<Membership?> getActiveForProfile(String profileId);

  /// Returns all memberships with a given status.
  Future<List<Membership>> getByStatus(MembershipStatus status);

  /// Returns all memberships in the system.
  Future<List<Membership>> getAll();

  /// Returns memberships whose subscriptionRenewalDate falls within [withinDays] days.
  Future<List<Membership>> getExpiringWithin(int withinDays);

  /// Returns memberships whose trial is expiring within [withinDays] days.
  Future<List<Membership>> getTrialsExpiringWithin(int withinDays);

  /// Creates a new membership and returns the generated document ID.
  Future<String> create(Membership membership);

  /// Updates an existing membership document in full.
  Future<void> update(Membership membership);

  /// Updates only the status field of a membership.
  Future<void> updateStatus(String id, MembershipStatus status);

  /// Records a renewal: extends renewalDate, updates amount, payment method,
  /// and optionally recalculates the family pricing tier.
  Future<void> renew({
    required String id,
    required DateTime newRenewalDate,
    required double newAmount,
    required PaymentMethod paymentMethod,
    FamilyPricingTier? newFamilyTier,
  });

  /// Records a cancellation: sets status, cancelledAt, cancelledByAdminId,
  /// isActive=false, and optionally updates notes.
  Future<void> cancel({
    required String id,
    required String adminId,
    required DateTime cancelledAt,
    String? notes,
  });

  /// Adds a profile to a family membership's memberProfileIds array.
  /// Does NOT recalculate familyPricingTier — tier changes at next renewal only.
  Future<void> addFamilyMember(String membershipId, String profileId);

  /// Removes a profile from a family membership's memberProfileIds array.
  /// Does NOT recalculate familyPricingTier — tier changes at next renewal only.
  Future<void> removeFamilyMember(String membershipId, String profileId);

  /// Watches all memberships in real time.
  Stream<List<Membership>> watchAll();

  /// Watches a single membership in real time.
  Stream<Membership?> watchById(String id);
}
