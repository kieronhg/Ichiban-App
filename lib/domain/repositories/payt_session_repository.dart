import '../entities/payt_session.dart';
import '../entities/enums.dart';

abstract class PaytSessionRepository {
  /// Returns a single PAYT session by ID, or null if not found.
  Future<PaytSession?> getById(String id);

  /// Returns all PAYT sessions for a given profile.
  Future<List<PaytSession>> getForProfile(String profileId);

  /// Returns all unpaid PAYT sessions for a given profile.
  Future<List<PaytSession>> getPendingForProfile(String profileId);

  /// Creates a new PAYT session record and returns the generated document ID.
  Future<String> create(PaytSession session);

  /// Marks a PAYT session as paid, recording the admin and payment method.
  Future<void> markPaid(
    String id, {
    required String recordedByAdminId,
    required PaymentMethod paymentMethod,
  });

  /// Links an attendance record to a PAYT session after check-in.
  Future<void> linkAttendanceRecord(String sessionId, String attendanceRecordId);
}
