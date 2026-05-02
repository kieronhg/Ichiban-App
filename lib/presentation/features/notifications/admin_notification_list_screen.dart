import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../dashboard/admin_drawer.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/notification_log.dart';

class AdminNotificationListScreen extends ConsumerWidget {
  const AdminNotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminNotificationLogsProvider);

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Notification Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () => _showFilterSheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            tooltip: 'Send Announcement',
            onPressed: () => context.pushNamed('adminSendAnnouncement'),
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined),
            tooltip: 'Email Templates',
            onPressed: () => context.pushNamed('adminEmailTemplates'),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(adminNotificationLogsProvider.notifier).refresh(),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return const _EmptyView();
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(adminNotificationLogsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) => _NotificationTile(
                log: logs[i],
                onTap: () => context.pushNamed(
                  'adminNotificationDetail',
                  extra: logs[i],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FilterSheet(
        onApply: (type, channel, status) async {
          Navigator.of(ctx).pop();
          await ref
              .read(adminNotificationLogsProvider.notifier)
              .applyFilters(type: type, channel: channel, status: status);
        },
        onClear: () async {
          Navigator.of(ctx).pop();
          await ref.read(adminNotificationLogsProvider.notifier).clearFilters();
        },
      ),
    );
  }
}

// ── Tile ───────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.log, required this.onTap});

  final NotificationLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _StatusIcon(status: log.deliveryStatus),
      title: Text(
        log.title ?? _typeLabel(log.type),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${_channelLabel(log.channel)}  •  ${DateFormat('dd MMM yyyy HH:mm').format(log.sentAt)}',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DeliveryBadge(status: log.deliveryStatus),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  String _typeLabel(NotificationType t) => switch (t) {
    NotificationType.lapseReminderPre => 'Lapse Reminder (Pre)',
    NotificationType.lapseReminderPost => 'Lapse Reminder (Post)',
    NotificationType.trialExpiring => 'Trial Expiring',
    NotificationType.gradingEligibility => 'Grading Eligibility',
    NotificationType.gradingPromotion => 'Grading Promotion',
    NotificationType.announcement => 'Announcement',
    NotificationType.dbsExpiry => 'DBS Expiry',
    NotificationType.firstAidExpiry => 'First Aid Expiry',
    NotificationType.complianceSubmitted => 'Compliance Submitted',
    NotificationType.complianceVerified => 'Compliance Verified',
    NotificationType.coachComplianceExpiring => 'Coach Compliance Expiring',
    NotificationType.deliveryFailure => 'Delivery Failure',
    NotificationType.selfRegistration => 'New Student Registration',
  };

  String _channelLabel(NotificationChannel c) => switch (c) {
    NotificationChannel.push => 'Push',
    NotificationChannel.email => 'Email',
  };
}

// ── Status icon ────────────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final NotificationDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      NotificationDeliveryStatus.sent => (
        Icons.check_circle_outline,
        AppColors.success,
      ),
      NotificationDeliveryStatus.failed => (
        Icons.error_outline,
        AppColors.error,
      ),
      NotificationDeliveryStatus.suppressed => (
        Icons.block_outlined,
        AppColors.textSecondary,
      ),
    };
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withAlpha(26),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ── Delivery badge ─────────────────────────────────────────────────────────

class _DeliveryBadge extends StatelessWidget {
  const _DeliveryBadge({required this.status});

  final NotificationDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      NotificationDeliveryStatus.sent => ('Sent', AppColors.success),
      NotificationDeliveryStatus.failed => ('Failed', AppColors.error),
      NotificationDeliveryStatus.suppressed => (
        'Suppressed',
        AppColors.textSecondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Filter bottom sheet ────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.onApply, required this.onClear});

  final void Function(
    NotificationType? type,
    NotificationChannel? channel,
    NotificationDeliveryStatus? status,
  )
  onApply;
  final VoidCallback onClear;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  NotificationType? _type;
  NotificationChannel? _channel;
  NotificationDeliveryStatus? _status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          _label(context, 'Type'),
          DropdownButton<NotificationType?>(
            value: _type,
            isExpanded: true,
            hint: const Text('All types'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All types')),
              ...NotificationType.values.map(
                (t) => DropdownMenuItem(value: t, child: Text(t.name)),
              ),
            ],
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 12),
          _label(context, 'Channel'),
          DropdownButton<NotificationChannel?>(
            value: _channel,
            isExpanded: true,
            hint: const Text('All channels'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All channels')),
              ...NotificationChannel.values.map(
                (c) => DropdownMenuItem(value: c, child: Text(c.name)),
              ),
            ],
            onChanged: (v) => setState(() => _channel = v),
          ),
          const SizedBox(height: 12),
          _label(context, 'Status'),
          DropdownButton<NotificationDeliveryStatus?>(
            value: _status,
            isExpanded: true,
            hint: const Text('All statuses'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All statuses')),
              ...NotificationDeliveryStatus.values.map(
                (s) => DropdownMenuItem(value: s, child: Text(s.name)),
              ),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClear,
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_type, _channel, _status),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
