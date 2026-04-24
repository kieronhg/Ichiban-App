import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/cash_payment.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/cash_payment_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreCashPaymentRepository implements CashPaymentRepository {
  @override
  Future<List<CashPayment>> getForProfile(String profileId) async {
    final snap = await FirestoreCollections.cashPayments()
        .where('profileId', isEqualTo: profileId)
        .orderBy('recordedAt', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<CashPayment>> getForMembership(String membershipId) async {
    final snap = await FirestoreCollections.cashPayments()
        .where('membershipId', isEqualTo: membershipId)
        .orderBy('recordedAt', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<CashPayment>> getAll() async {
    final snap = await FirestoreCollections.cashPayments()
        .orderBy('recordedAt', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<String> create(CashPayment payment) async {
    final ref = await FirestoreCollections.cashPayments().add(payment);
    return ref.id;
  }

  @override
  Future<void> edit(
    String id, {
    required double amount,
    required PaymentMethod paymentMethod,
    required PaymentType paymentType,
    String? notes,
    required String editedByAdminId,
  }) async {
    await FirestoreCollections.cashPayments().doc(id).update({
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'paymentType': paymentType.name,
      'notes': notes,
      'editedByAdminId': editedByAdminId,
      'editedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Stream<List<CashPayment>> watchAll() {
    return FirestoreCollections.cashPayments()
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<List<CashPayment>> watchForProfile(String profileId) {
    return FirestoreCollections.cashPayments()
        .where('profileId', isEqualTo: profileId)
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<List<CashPayment>> watchForMembership(String membershipId) {
    return FirestoreCollections.cashPayments()
        .where('membershipId', isEqualTo: membershipId)
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
