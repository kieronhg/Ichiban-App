import '../../entities/enums.dart';
import '../../entities/membership.dart';
import '../../entities/membership_history.dart';
import '../../entities/profile.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/membership_history_repository.dart';

class RemoveFamilyMemberUseCase {
  const RemoveFamilyMemberUseCase({
    required MembershipRepository membershipRepo,
    required MembershipHistoryRepository historyRepo,
  }) : _membershipRepo = membershipRepo,
       _historyRepo = historyRepo;

  final MembershipRepository _membershipRepo;
  final MembershipHistoryRepository _historyRepo;

  Future<void> call({
    required Membership membership,
    required Profile profile,
    required String adminId,
  }) async {
    if (!membership.isFamily) {
      throw Exception('Only family memberships support member removal.');
    }

    if (profile.id == membership.primaryHolderId) {
      throw Exception(
        'Cannot remove the primary holder. '
        'Please assign a new primary holder first.',
      );
    }

    final now = DateTime.now();
    await _membershipRepo.removeFamilyMember(membership.id, profile.id);

    final newCount = membership.memberProfileIds.length - 1;
    String? tierNotice;
    if (newCount == 3 && membership.memberProfileIds.length == 4) {
      tierNotice =
          'Member removed — pricing tier will update to £55.00/month at next renewal.';
    }

    await _historyRepo.create(
      MembershipHistory(
        id: '',
        membershipId: membership.id,
        changeType: MembershipChangeType.statusOverride,
        newStatus: membership.status,
        changedByAdminId: adminId,
        triggeredByCloudFunction: false,
        changedAt: now,
        notes:
            'Member ${profile.firstName} ${profile.lastName} removed.${tierNotice != null ? ' $tierNotice' : ''}',
      ),
    );
  }
}
