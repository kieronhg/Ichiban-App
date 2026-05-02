import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/membership_pricing.dart';
import '../../domain/repositories/membership_pricing_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreMembershipPricingRepository
    implements MembershipPricingRepository {
  @override
  Future<List<MembershipPricing>> getAll() async {
    final snap = await FirestoreCollections.membershipPricing().get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<MembershipPricing?> getByKey(String key) async {
    final snap = await FirestoreCollections.membershipPricing().doc(key).get();
    return snap.data();
  }

  @override
  Future<void> updatePrice(String key, double amount) async {
    await FirestoreCollections.membershipPricing()
        .doc(key)
        .set(
          MembershipPricing(key: key, amount: amount),
          SetOptions(merge: true),
        );
  }

  @override
  Stream<List<MembershipPricing>> watchAll() {
    return FirestoreCollections.membershipPricing().snapshots().map(
      (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }
}
