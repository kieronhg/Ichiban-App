import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/email_template.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/notification_log.dart';
import '../../domain/use_cases/notifications/get_admin_notification_logs_use_case.dart';
import '../../domain/use_cases/notifications/get_email_templates_use_case.dart';
import '../../domain/use_cases/notifications/mark_notification_read_use_case.dart';
import '../../domain/use_cases/notifications/save_email_template_use_case.dart';
import '../../domain/use_cases/notifications/send_announcement_use_case.dart';
import '../../domain/use_cases/notifications/watch_student_notifications_use_case.dart';
import '../../domain/use_cases/notifications/watch_unread_failure_count_use_case.dart';
import 'repository_providers.dart';

// ── Use-case providers ─────────────────────────────────────────────────────

final watchStudentNotificationsUseCaseProvider =
    Provider<WatchStudentNotificationsUseCase>(
      (ref) => WatchStudentNotificationsUseCase(
        ref.watch(notificationRepositoryProvider),
      ),
    );

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>(
      (ref) => MarkNotificationReadUseCase(
        ref.watch(notificationRepositoryProvider),
      ),
    );

final getAdminNotificationLogsUseCaseProvider =
    Provider<GetAdminNotificationLogsUseCase>(
      (ref) => GetAdminNotificationLogsUseCase(
        ref.watch(notificationRepositoryProvider),
      ),
    );

final watchUnreadFailureCountUseCaseProvider =
    Provider<WatchUnreadFailureCountUseCase>(
      (ref) => WatchUnreadFailureCountUseCase(
        ref.watch(notificationRepositoryProvider),
      ),
    );

final sendAnnouncementUseCaseProvider = Provider<SendAnnouncementUseCase>(
  (ref) => const SendAnnouncementUseCase(),
);

final getEmailTemplatesUseCaseProvider = Provider<GetEmailTemplatesUseCase>(
  (ref) => GetEmailTemplatesUseCase(ref.watch(emailTemplateRepositoryProvider)),
);

final saveEmailTemplateUseCaseProvider = Provider<SaveEmailTemplateUseCase>(
  (ref) => SaveEmailTemplateUseCase(ref.watch(emailTemplateRepositoryProvider)),
);

// ── Stream providers ───────────────────────────────────────────────────────

/// Student-visible notifications for the given profile, live.
final studentNotificationsProvider =
    StreamProvider.family<List<NotificationLog>, String>(
      (ref, profileId) =>
          ref.watch(watchStudentNotificationsUseCaseProvider).call(profileId),
    );

/// Unread delivery failure count for a given admin user, live.
final unreadFailureCountProvider = StreamProvider.family<int, String>(
  (ref, adminUserId) =>
      ref.watch(watchUnreadFailureCountUseCaseProvider).call(adminUserId),
);

/// All email templates, live.
final emailTemplatesProvider = StreamProvider<List<EmailTemplate>>(
  (ref) => ref.watch(getEmailTemplatesUseCaseProvider).watchAll(),
);

// ── Admin notification log notifier ───────────────────────────────────────

/// Holds the filter state and fetched results for the admin notification
/// log screen.
class AdminNotificationLogsNotifier
    extends AsyncNotifier<List<NotificationLog>> {
  NotificationType? _type;
  NotificationChannel? _channel;
  NotificationDeliveryStatus? _status;
  DateTime? _from;
  DateTime? _to;
  String? _recipientProfileId;

  @override
  Future<List<NotificationLog>> build() => _fetch();

  Future<List<NotificationLog>> _fetch() {
    return ref
        .read(getAdminNotificationLogsUseCaseProvider)
        .call(
          type: _type,
          channel: _channel,
          status: _status,
          from: _from,
          to: _to,
          recipientProfileId: _recipientProfileId,
        );
  }

  Future<void> applyFilters({
    NotificationType? type,
    NotificationChannel? channel,
    NotificationDeliveryStatus? status,
    DateTime? from,
    DateTime? to,
    String? recipientProfileId,
  }) async {
    _type = type;
    _channel = channel;
    _status = status;
    _from = from;
    _to = to;
    _recipientProfileId = recipientProfileId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> clearFilters() async {
    _type = null;
    _channel = null;
    _status = null;
    _from = null;
    _to = null;
    _recipientProfileId = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final adminNotificationLogsProvider =
    AsyncNotifierProvider.autoDispose<
      AdminNotificationLogsNotifier,
      List<NotificationLog>
    >(AdminNotificationLogsNotifier.new);
