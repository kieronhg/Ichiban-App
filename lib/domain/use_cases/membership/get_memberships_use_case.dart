import '../../entities/enums.dart';
import '../../entities/membership.dart';
import '../../repositories/membership_repository.dart';

class GetMembershipsUseCase {
  const GetMembershipsUseCase(this._repo);

  final MembershipRepository _repo;

  /// All memberships in real time — used for the admin membership list.
  Stream<List<Membership>> watchAll() => _repo.watchAll();

  /// Single membership in real time — used for the membership detail screen.
  Stream<Membership?> watchById(String id) => _repo.watchById(id);

  /// All memberships (any status) where [profileId] appears — for profile history.
  Future<List<Membership>> getForProfile(String profileId) =>
      _repo.getForProfile(profileId);

  /// Active or PAYT membership for a profile — for grading eligibility check.
  Future<Membership?> getActiveForProfile(String profileId) =>
      _repo.getActiveForProfile(profileId);

  /// All memberships by status — for dashboard flags and Cloud Function queries.
  Future<List<Membership>> getByStatus(MembershipStatus status) =>
      _repo.getByStatus(status);
}
