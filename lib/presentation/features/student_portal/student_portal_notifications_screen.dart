import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/student_portal_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/notification_log.dart';
import 'student_portal_drawer.dart';

final _timeFormat = DateFormat('d MMM yyyy · HH:mm');

class StudentPortalNotificationsScreen extends ConsumerWidget {
  const StudentPortalNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(studentPortalNotificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      drawer: const StudentPortalDrawer(),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Could not load notifications. Please try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        data: (notifications) {
          final push = notifications
              .where((n) => n.title != null || n.body != null)
              .toList();

          if (push.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_none_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will be notified here about your membership, gradings, and dojo announcements.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: push.length,
            separatorBuilder: (_, i) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _NotificationTile(
              log: push[i],
              onTap: () async {
                final log = push[i];
                if (log.isRead != true) {
                  await ref
                      .read(notificationRepositoryProvider)
                      .markReadAt(log.id, DateTime.now());
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.log, required this.onTap});
  final NotificationLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = log.isRead != true;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5, right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnread ? AppColors.accent : Colors.transparent,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log.title != null)
                      Text(
                        log.title!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    if (log.body != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        log.body!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _timeFormat.format(log.sentAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
