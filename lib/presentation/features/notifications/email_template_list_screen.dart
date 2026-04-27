import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/notification_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/email_template.dart';

class EmailTemplateListScreen extends ConsumerWidget {
  const EmailTemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(emailTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Email Templates')),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No templates yet.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Templates are created automatically when Cloud Functions\nrun for the first time.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: templates.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, i) => _TemplateTile(
              template: templates[i],
              onTap: () => context.pushNamed(
                'adminEmailTemplateEditor',
                extra: templates[i],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template, required this.onTap});

  final EmailTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(
        backgroundColor: AppColors.surfaceVariant,
        child: Icon(Icons.email_outlined, color: AppColors.textSecondary),
      ),
      title: Text(
        template.key,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        template.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (template.lastEditedAt != null)
            Text(
              DateFormat('dd MMM yy').format(template.lastEditedAt!),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
