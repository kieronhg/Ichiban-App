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
  Future<List<Membership>> getForProfile(String profileId) async {
    final snap = await FirestoreCollections.memberships()
        .where('memberProfileIds', arrayContains: profileId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
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
  Future<List<Membership>> getAll() async {
    final snap = await FirestoreCollections.memberships()
        .orderBy('createdAt', descending: true)
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
  Future<void> renew({
    required String id,
    required DateTime newRenewalDate,
    required double newAmount,
    required PaymentMethod paymentMethod,
    FamilyPricingTier? newFamilyTier,
  }) async {
    final data = <String, dynamic>{
      'status': MembershipStatus.active.name,
      'subscriptionRenewalDate': Timestamp.fromDate(newRenewalDate),
      'monthlyAmount': newAmount,
      'paymentMethod': paymentMethod.name,
      'isActive': true,
    };
    if (newFamilyTier != null) {
      data['familyPricingTier'] = newFamilyTier.name;
    }
    await FirestoreCollections.memberships().doc(id).update(data);
  }

  @override
  Future<void> cancel({
    required String id,
    required String adminId,
    required DateTime cancelledAt,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'status': MembershipStatus.cancelled.name,
      'cancelledAt': Timestamp.fromDate(cancelledAt),
      'cancelledByAdminId': adminId,
      'isActive': false,
    };
    if (notes != null) data['notes'] = notes;
    await FirestoreCollections.memberships().doc(id).update(data);
  }

  @override
  Future<void> addFamilyMember(String membershipId, String profileId) async {
    // Per handover Part 9: tier does NOT recalculate on add — only at renewal.
    await FirestoreCollections.memberships().doc(membershipId).update({
      'memberProfileIds': FieldValue.arrayUnion([profileId]),
    });
  }

  @override
  Future<void> removeFamilyMember(String membershipId, String profileId) async {
    // Per handover Part 9: tier does NOT recalculate on remove — only at renewal.
    await FirestoreCollections.memberships().doc(membershipId).update({
      'memberProfileIds': FieldValue.arrayRemove([profileId]),
    });
  }

  @override
  Future<void> cancelAtPeriodEnd({
    required String id,
    required DateTime cancelledAt,
  }) async {
    await FirestoreCollections.memberships().doc(id).update({
      'cancelledAt': Timestamp.fromDate(cancelledAt),
      // isActive remains true until period end — Cloud Function sets it false
    });
  }

  @override
  Future<void> startGracePeriod({
    required String id,
    required DateTime gracePeriodEnd,
  }) async {
    await FirestoreCollections.memberships().doc(id).update({
      'status': MembershipStatus.gracePeriod.name,
      'gracePeriodEnd': Timestamp.fromDate(gracePeriodEnd),
    });
  }

  @override
  Future<void> requestDowngrade({
    required String id,
    required String pendingPlanId,
    required DateTime requestedAt,
  }) async {
    await FirestoreCollections.memberships().doc(id).update({
      'pendingDowngradePlanId': pendingPlanId,
      'downgradeRequestedAt': Timestamp.fromDate(requestedAt),
    });
  }

  @override
  Future<void> clearPendingDowngrade(String id) async {
    await FirestoreCollections.memberships().doc(id).update({
      'pendingDowngradePlanId': null,
      'downgradeRequestedAt': null,
    });
  }

  @override
  Stream<List<Membership>> watchAll() {
    return FirestoreCollections.memberships()
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<Membership?> watchById(String id) {
    return FirestoreCollections.memberships()
        .doc(id)
        .snapshots()
        .map((snap) => snap.data());
  }
}
