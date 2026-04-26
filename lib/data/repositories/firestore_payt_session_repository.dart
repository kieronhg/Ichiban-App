import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payt_session.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/payt_session_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestorePaytSessionRepository implements PaytSessionRepository {
  @override
  Future<PaytSession?> getById(String id) async {
    final snap = await FirestoreCollections.paytSessions().doc(id).get();
    return snap.data();
  }

  @override
  Future<List<PaytSession>> getForProfile(String profileId) async {
    final snap = await FirestoreCollections.paytSessions()
        .where('profileId', isEqualTo: profileId)
        .orderBy('sessionDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<PaytSession>> getPendingForProfile(String profileId) async {
    final snap = await FirestoreCollections.paytSessions()
        .where('profileId', isEqualTo: profileId)
        .where('paymentStatus', isEqualTo: PaytPaymentStatus.pending.name)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<String> create(PaytSession session) async {
    final ref = await FirestoreCollections.paytSessions().add(session);
    return ref.id;
  }

  @override
  Future<void> markPaid(
    String id, {
    required String recordedByAdminId,
    required PaymentMethod paymentMethod,
  }) async {
    await FirestoreCollections.paytSessions().doc(id).update({
      'paymentStatus': PaytPaymentStatus.paid.name,
      'paidAt': Timestamp.fromDate(DateTime.now()),
      'recordedByAdminId': recordedByAdminId,
      'paymentMethod': paymentMethod.name,
    });
  }

  @override
  Future<void> writeOff(
    String id, {
    required String writtenOffByAdminId,
    required String writeOffReason,
  }) async {
    await FirestoreCollections.paytSessions().doc(id).update({
      'paymentStatus': PaytPaymentStatus.writtenOff.name,
      'paymentMethod': PaymentMethod.writtenOff.name,
      'writtenOffByAdminId': writtenOffByAdminId,
      'writtenOffAt': Timestamp.fromDate(DateTime.now()),
      'writeOffReason': writeOffReason,
    });
  }

  @override
  Future<void> linkAttendanceRecord(
    String sessionId,
    String attendanceRecordId,
  ) async {
    await FirestoreCollections.paytSessions().doc(sessionId).update({
      'attendanceRecordId': attendanceRecordId,
    });
  }

  @override
  Stream<List<PaytSession>> watchAll() {
    return FirestoreCollections.paytSessions()
        .orderBy('sessionDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<List<PaytSession>> watchForProfile(String profileId) {
    return FirestoreCollections.paytSessions()
        .where('profileId', isEqualTo: profileId)
        .orderBy('sessionDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<List<PaytSession>> watchPendingForProfile(String profileId) {
    return FirestoreCollections.paytSessions()
        .where('profileId', isEqualTo: profileId)
        .where('paymentStatus', isEqualTo: PaytPaymentStatus.pending.name)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
