import '../../domain/entities/cash_payment.dart';
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
}
