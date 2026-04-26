import '../../entities/enums.dart';
import '../../entities/membership.dart';
import '../../entities/membership_history.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/membership_history_repository.dart';

class OverrideMembershipStatusUseCase {
  const OverrideMembershipStatusUseCase({
    required MembershipRepository membershipRepo,
    required MembershipHistoryRepository historyRepo,
  }) : _membershipRepo = membershipRepo,
       _historyRepo = historyRepo;

  final MembershipRepository _membershipRepo;
  final MembershipHistoryRepository _historyRepo;

  Future<void> call({
    required Membership membership,
    required MembershipStatus newStatus,
    required String adminId,
    required String notes,
  }) async {
    if (notes.trim().isEmpty) {
      throw Exception('Notes are required for a manual status override.');
    }

    final now = DateTime.now();
    final isActive =
        newStatus == MembershipStatus.active ||
        newStatus == MembershipStatus.trial ||
        newStatus == MembershipStatus.payt;

    await _membershipRepo.update(
      membership.copyWith(status: newStatus, isActive: isActive),
    );

    await _historyRepo.create(
      MembershipHistory(
        id: '',
        membershipId: membership.id,
        changeType: MembershipChangeType.statusOverride,
        previousStatus: membership.status,
        newStatus: newStatus,
        changedByAdminId: adminId,
        triggeredByCloudFunction: false,
        changedAt: now,
        notes: notes,
      ),
    );
  }
}
