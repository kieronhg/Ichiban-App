import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/membership_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreMembershipRepository implements MembershipRepository {
  @override
  Future<Membership?> getById(String id) async {
    final snap = await FirestoreCollections.memberships().doc(id).get();
    return snap.data();
  }

  @override
  Future<Membership?> getActiveForProfile(String profileId) async {
    final snap = await FirestoreCollections.memberships()
        .where('memberProfileIds', arrayContains: profileId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  @override
  Future<List<Membership>> getByStatus(MembershipStatus status) async {
    final snap = await FirestoreCollections.memberships()
        .where('status', isEqualTo: status.name)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Membership>> getExpiringWithin(int withinDays) async {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));
    final snap = await FirestoreCollections.memberships()
        .where('status', isEqualTo: MembershipStatus.active.name)
        .where(
          'subscriptionRenewalDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(now),
        )
        .where(
          'subscriptionRenewalDate',
          isLessThanOrEqualTo: Timestamp.fromDate(cutoff),
        )
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Membership>> getTrialsExpiringWithin(int withinDays) async {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));
    final snap = await FirestoreCollections.memberships()
        .where('status', isEqualTo: MembershipStatus.trial.name)
        .where('trialEndDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('trialEndDate', isLessThanOrEqualTo: Timestamp.fromDate(cutoff))
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<String> create(Membership membership) async {
    final ref = await FirestoreCollections.memberships().add(membership);
    return ref.id;
  }

  @override
  Future<void> update(Membership membership) async {
    await FirestoreCollections.memberships().doc(membership.id).set(membership);
  }

  @override
  Future<void> updateStatus(String id, MembershipStatus status) async {
    await FirestoreCollections.memberships().doc(id).update({
      'status': status.name,
    });
  }

  @override
  Future<void> addFamilyMember(String membershipId, String profileId) async {
    final ref = FirestoreCollections.memberships().doc(membershipId);

    // Add the profile to the array
    await ref.update({
      'memberProfileIds': FieldValue.arrayUnion([profileId]),
    });

    // Re-fetch to get the updated count and recalculate tier
    final snap = await ref.get();
    final updated = snap.data()!;
    final newTier = Membership.deriveFamilyTier(
      updated.memberProfileIds.length,
    );
    await ref.update({'familyPricingTier': newTier.name});
  }

  @override
  Future<void> removeFamilyMember(String membershipId, String profileId) async {
    final ref = FirestoreCollections.memberships().doc(membershipId);

    // Remove the profile from the array
    await ref.update({
      'memberProfileIds': FieldValue.arrayRemove([profileId]),
    });

    // Re-fetch to get the updated count and recalculate tier
    final snap = await ref.get();
    final updated = snap.data()!;
    final newTier = Membership.deriveFamilyTier(
      updated.memberProfileIds.length,
    );
    await ref.update({'familyPricingTier': newTier.name});
  }

  @override
  Stream<List<Membership>> watchAll() {
    return FirestoreCollections.memberships().snapshots().map(
      (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }

  @override
  Stream<Membership?> watchById(String id) {
    return FirestoreCollections.memberships()
        .doc(id)
        .snapshots()
        .map((snap) => snap.data());
  }
}
