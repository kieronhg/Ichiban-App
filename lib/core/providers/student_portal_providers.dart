import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/enrollment.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/membership_pricing.dart';
import '../../domain/entities/notification_log.dart';
import '../../domain/entities/profile.dart';
import 'repository_providers.dart';
import 'student_auth_provider.dart';

final _portalProfileIdProvider = Provider<String?>((ref) {
  return ref.watch(currentStudentProfileProvider)?.id;
});

final studentPortalMembershipProvider = FutureProvider.autoDispose<Membership?>(
  (ref) async {
    final profileId = ref.watch(_portalProfileIdProvider);
    if (profileId == null) return null;
    return ref
        .read(membershipRepositoryProvider)
        .getActiveForProfile(profileId);
  },
);

final studentPortalEnrollmentsProvider =
    StreamProvider.autoDispose<List<Enrollment>>((ref) {
      final profileId = ref.watch(_portalProfileIdProvider);
      if (profileId == null) return Stream.value([]);
      return ref.read(enrollmentRepositoryProvider).watchForStudent(profileId);
    });

final studentPortalNotificationsProvider =
    StreamProvider.autoDispose<List<NotificationLog>>((ref) {
      final profileId = ref.watch(_portalProfileIdProvider);
      if (profileId == null) return Stream.value([]);
      return ref
          .read(notificationRepositoryProvider)
          .watchForProfile(profileId);
    });

final studentPortalChildrenProvider = FutureProvider.autoDispose<List<Profile>>(
  (ref) async {
    final profileId = ref.watch(_portalProfileIdProvider);
    if (profileId == null) return [];
    return ref.read(profileRepositoryProvider).getJuniorsForParent(profileId);
  },
);

final membershipPricingAllProvider =
    FutureProvider.autoDispose<List<MembershipPricing>>((ref) async {
      return ref.read(membershipPricingRepositoryProvider).getAll();
    });

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  return ref
          .watch(studentPortalNotificationsProvider)
          .value
          ?.where((n) => n.isRead != true)
          .length ??
      0;
});
