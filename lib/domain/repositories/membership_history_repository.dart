import '../entities/membership_history.dart';

abstract class MembershipHistoryRepository {
  /// Creates a new history record and returns the generated document ID.
  Future<String> create(MembershipHistory record);

  /// Returns all history records for a membership, ordered by changedAt descending.
  Future<List<MembershipHistory>> getForMembership(String membershipId);

  /// Watches history records for a membership in real time.
  Stream<List<MembershipHistory>> watchForMembership(String membershipId);

  /// Most-recent [limit] records across all memberships, ordered by changedAt desc.
  Future<List<MembershipHistory>> getRecent(int limit);
}
