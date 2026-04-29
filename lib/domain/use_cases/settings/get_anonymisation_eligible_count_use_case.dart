import '../../entities/enums.dart';
import '../../entities/membership.dart';
import '../../repositories/app_settings_repository.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/profile_repository.dart';

class GetAnonymisationEligibleCountUseCase {
  const GetAnonymisationEligibleCountUseCase(
    this._settings,
    this._memberships,
    this._profiles,
  );

  final AppSettingsRepository _settings;
  final MembershipRepository _memberships;
  final ProfileRepository _profiles;

  Future<int> call() async {
    final retentionSetting = await _settings.get('gdprRetentionMonths');
    final retentionMonths = retentionSetting?.intValue ?? 12;
    final cutoff = DateTime.now().subtract(
      Duration(days: retentionMonths * 30),
    );

    final lapsed = await _memberships.getByStatus(MembershipStatus.lapsed);
    final expired = await _memberships.getByStatus(MembershipStatus.expired);
    final cancelled = await _memberships.getByStatus(
      MembershipStatus.cancelled,
    );

    final eligible = [...lapsed, ...expired, ...cancelled]
        .where((m) => _relevantDate(m).isBefore(cutoff))
        .expand((m) => m.memberProfileIds)
        .toSet();

    if (eligible.isEmpty) return 0;

    var count = 0;
    for (final profileId in eligible) {
      final profile = await _profiles.getById(profileId);
      if (profile != null && !profile.isAnonymised) count++;
    }
    return count;
  }

  DateTime _relevantDate(Membership membership) {
    return switch (membership.status) {
      MembershipStatus.lapsed =>
        membership.subscriptionRenewalDate ?? membership.createdAt,
      MembershipStatus.expired =>
        membership.trialEndDate ?? membership.createdAt,
      MembershipStatus.cancelled =>
        membership.cancelledAt ?? membership.createdAt,
      _ => membership.createdAt,
    };
  }
}
