import '../../entities/enums.dart';
import '../../entities/membership.dart';
import '../../entities/membership_history.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/membership_history_repository.dart';

class CancelMembershipUseCase {
  const CancelMembershipUseCase({
    required MembershipRepository membershipRepo,
    required MembershipHistoryRepository historyRepo,
  }) : _membershipRepo = membershipRepo,
       _historyRepo = historyRepo;

  final MembershipRepository _membershipRepo;
  final MembershipHistoryRepository _historyRepo;

  Future<void> call({
    required Membership membership,
    required String adminId,
    String? notes,
  }) async {
    final now = DateTime.now();

    await _membershipRepo.cancel(
      id: membership.id,
      adminId: adminId,
      cancelledAt: now,
      notes: notes,
    );

    await _historyRepo.create(
      MembershipHistory(
        id: '',
        membershipId: membership.id,
        changeType: MembershipChangeType.cancelled,
        previousStatus: membership.status,
        newStatus: MembershipStatus.cancelled,
        changedByAdminId: adminId,
        triggeredByCloudFunction: false,
        changedAt: now,
        notes: notes,
      ),
    );
  }
}
