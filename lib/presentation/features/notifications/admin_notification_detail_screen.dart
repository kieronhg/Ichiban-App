import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/notification_log.dart';

class AdminNotificationDetailScreen extends StatelessWidget {
  const AdminNotificationDetailScreen({super.key, required this.log});

  final NotificationLog log;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(log: log),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Message',
            children: [
              if (log.title != null) _Row('Title', log.title!),
              if (log.body != null) _Row('Body', log.body!),
              if (log.emailSubject != null)
                _Row('Email Subject', log.emailSubject!),
              if (log.emailTemplateKey != null)
                _Row('Template Key', log.emailTemplateKey!),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Delivery',
            children: [
              _Row('Channel', _channelLabel(log.channel)),
              _Row('Type', log.type.name),
              _Row('Recipient Type', log.recipientType.name),
              _Row('Recipient ID', log.recipientProfileId),
              _Row(
                'Sent At',
                DateFormat('dd MMM yyyy HH:mm:ss').format(log.sentAt),
              ),
              if (log.readAt != null)
                _Row(
                  'Read At',
                  DateFormat('dd MMM yyyy HH:mm:ss').format(log.readAt!),
                ),
            ],
          ),
          if (log.failureReason != null || log.suppressionReason != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Failure / Suppression',
              children: [
                if (log.failureReason != null)
                  _Row('Failure Reason', log.failureReason!),
                if (log.suppressionReason != null)
                  _Row('Suppression Reason', log.suppressionReason!),
              ],
            ),
          ],
          if (log.announcementId != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Announcement',
              children: [_Row('Announcement ID', log.announcementId!)],
            ),
          ],
        ],
      ),
    );
  }

  String _channelLabel(NotificationChannel c) => switch (c) {
    NotificationChannel.push => 'Push',
    NotificationChannel.email => 'Email',
  };
}

// ── Status card ────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.log});

  final NotificationLog log;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (log.deliveryStatus) {
      NotificationDeliveryStatus.sent => (
        Icons.check_circle_outline,
        AppColors.success,
        'Delivered',
      ),
      NotificationDeliveryStatus.failed => (
        Icons.error_outline,
        AppColors.error,
        'Failed',
      ),
      NotificationDeliveryStatus.suppressed => (
        Icons.block_outlined,
        AppColors.textSecondary,
        'Suppressed',
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  log.type.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
