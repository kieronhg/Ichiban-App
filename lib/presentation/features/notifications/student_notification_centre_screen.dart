import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/student_session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/notification_log.dart';

class StudentNotificationCentreScreen extends ConsumerWidget {
  const StudentNotificationCentreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ref.watch(studentSessionProvider).profileId;

    if (profileId == null) {
      return const Scaffold(body: Center(child: Text('No profile selected.')));
    }

    final notificationsAsync = ref.watch(
      studentNotificationsProvider(profileId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final notifier = ref.read(markNotificationReadUseCaseProvider);
              final logs = notificationsAsync.asData?.value ?? [];
              final unread = logs.where((l) => l.isRead != true).toList();
              for (final log in unread) {
                await notifier.call(log.id);
              }
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.textOnPrimary),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: logs.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, i) => _StudentNotificationTile(
              log: logs[i],
              onTap: () async {
                if (logs[i].isRead != true) {
                  await ref
                      .read(markNotificationReadUseCaseProvider)
                      .call(logs[i].id);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Tile ───────────────────────────────────────────────────────────────────

class _StudentNotificationTile extends StatelessWidget {
  const _StudentNotificationTile({required this.log, required this.onTap});

  final NotificationLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = log.isRead != true;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? AppColors.accent.withAlpha(10) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeIcon(type: log.type),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.title ?? _typeLabel(log.type),
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (log.body != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      log.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(log.sentAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(NotificationType t) => switch (t) {
    NotificationType.gradingEligibility => 'Grading Eligibility',
    NotificationType.gradingPromotion => 'Grading Promotion',
    NotificationType.trialExpiring => 'Trial Expiring',
    NotificationType.announcement => 'Announcement',
    _ => 'Notification',
  };

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.gradingEligibility ||
      NotificationType.gradingPromotion => (
        Icons.military_tech_outlined,
        AppColors.accent,
      ),
      NotificationType.trialExpiring => (
        Icons.timer_outlined,
        AppColors.warning,
      ),
      NotificationType.announcement => (
        Icons.campaign_outlined,
        AppColors.info,
      ),
      _ => (Icons.notifications_outlined, AppColors.textSecondary),
    };
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withAlpha(26),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
