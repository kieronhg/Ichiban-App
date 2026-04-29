import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';

// Template catalogue — key + human-readable description
const _templates = <_TemplateEntry>[
  _TemplateEntry(
    key: 'renewalReminderPre',
    name: 'Renewal Reminder',
    description: 'Sent before membership renewal date to prompt payment.',
  ),
  _TemplateEntry(
    key: 'lapseReminderPre',
    name: 'Pre-Lapse Reminder',
    description: 'Sent working days before renewal if payment not received.',
  ),
  _TemplateEntry(
    key: 'lapseReminderPost',
    name: 'Post-Lapse Reminder',
    description: 'Sent after renewal date if membership has lapsed.',
  ),
  _TemplateEntry(
    key: 'trialExpiring',
    name: 'Trial Expiry Reminder',
    description: 'Sent before trial membership ends.',
  ),
  _TemplateEntry(
    key: 'gradingEligibility',
    name: 'Grading Eligibility',
    description: 'Sent when a member is nominated for grading.',
  ),
  _TemplateEntry(
    key: 'gradingPromotion',
    name: 'Grading Promotion',
    description: 'Sent when a member is promoted after grading.',
  ),
  _TemplateEntry(
    key: 'dbsExpiry',
    name: 'DBS Expiry Alert',
    description: 'Sent to coach and owners before DBS check expires.',
  ),
  _TemplateEntry(
    key: 'firstAidExpiry',
    name: 'First Aid Expiry Alert',
    description:
        'Sent to coach and owners before first aid certification expires.',
  ),
  _TemplateEntry(
    key: 'announcement',
    name: 'Announcement',
    description: 'Used for manual broadcast emails to members.',
  ),
  _TemplateEntry(
    key: 'licenceReminder',
    name: 'Licence Reminder',
    description: 'Reserved for future licence renewal notifications.',
  ),
];

class EmailTemplatesSettingsScreen extends StatelessWidget {
  const EmailTemplatesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Templates')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Templates are edited in the Communications section. '
              'Tap "Edit Templates" below to manage them.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _templates.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final t = _templates[i];
                return ListTile(
                  leading: const Icon(
                    Icons.email_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(t.name),
                  subtitle: Text(t.description),
                  isThreeLine: true,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => context.go(RouteNames.adminNotifications),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Templates'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateEntry {
  const _TemplateEntry({
    required this.key,
    required this.name,
    required this.description,
  });

  final String key;
  final String name;
  final String description;
}
