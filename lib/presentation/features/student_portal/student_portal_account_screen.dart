import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/student_auth_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import 'student_portal_drawer.dart';

final _dateFormat = DateFormat('d MMMM yyyy');

class StudentPortalAccountScreen extends ConsumerWidget {
  const StudentPortalAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentStudentProfileProvider);
    final theme = Theme.of(context);

    if (profile == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Account')),
        drawer: const StudentPortalDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final initials = _initials(profile.firstName, profile.lastName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Account')),
      drawer: const StudentPortalDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                profile.fullName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Center(
              child: Text(
                profile.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'Personal details',
              rows: [
                _Row('Date of birth', _dateFormat.format(profile.dateOfBirth)),
                if (profile.gender != null) _Row('Gender', profile.gender!),
                _Row('Phone', profile.phone),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Address',
              rows: [
                _Row('Line 1', profile.addressLine1),
                if (profile.addressLine2 != null &&
                    profile.addressLine2!.isNotEmpty)
                  _Row('Line 2', profile.addressLine2!),
                _Row('City', profile.city),
                _Row('County', profile.county),
                _Row('Postcode', profile.postcode),
                _Row('Country', profile.country),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Emergency contact',
              rows: [
                _Row('Name', profile.emergencyContactName),
                _Row('Relationship', profile.emergencyContactRelationship),
                _Row('Phone', profile.emergencyContactPhone),
              ],
            ),
            if (profile.allergiesOrMedicalNotes != null &&
                profile.allergiesOrMedicalNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Medical notes',
                rows: [_Row('Notes', profile.allergiesOrMedicalNotes!)],
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'To update your personal details, please speak to the dojo team.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                ref.read(studentAuthProvider.notifier).signOut();
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go(RouteNames.entry);
              },
              icon: const Icon(Icons.logout_outlined, color: AppColors.error),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }
}

class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String value;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.rows});
  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        row.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
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
}
