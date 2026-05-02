import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../sign_up_provider.dart';

final _dobFormat = DateFormat('dd/MM/yyyy');

class SignUpStep10Review extends ConsumerWidget {
  const SignUpStep10Review({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewSection(
          title: 'Account',
          onEdit: () => notifier.goToStep(1),
          children: [_ReviewRow('Email', s.email)],
        ),
        _ReviewSection(
          title: s.hasJuniors ? 'Your details' : 'Personal details',
          onEdit: () => notifier.goToStep(2),
          children: [
            _ReviewRow('Name', '${s.firstName} ${s.lastName}'),
            if (s.dateOfBirth != null)
              _ReviewRow('Date of birth', _dobFormat.format(s.dateOfBirth!)),
            if (s.gender != null) _ReviewRow('Gender', s.gender!),
            _ReviewRow(
              'Address',
              [
                s.addressLine1,
                if (s.addressLine2 != null) s.addressLine2!,
                s.city,
                s.county,
                s.postcode,
                s.country,
              ].join(', '),
            ),
            _ReviewRow('Phone', s.phone),
          ],
        ),
        if (s.hasJuniors)
          _ReviewSection(
            title: 'Children (${s.children.length})',
            onEdit: () => notifier.goToStep(2),
            children: s.children
                .asMap()
                .entries
                .map(
                  (e) => _ReviewRow(
                    'Child ${e.key + 1}',
                    [
                      '${e.value.firstName} ${e.value.lastName}',
                      if (e.value.dateOfBirth != null)
                        _dobFormat.format(e.value.dateOfBirth!),
                    ].join(', '),
                  ),
                )
                .toList(),
          ),
        _ReviewSection(
          title: 'Emergency contact',
          onEdit: () => notifier.goToStep(3),
          children: [
            _ReviewRow('Name', s.emergencyContactName),
            _ReviewRow('Relationship', s.emergencyContactRelationship),
            _ReviewRow('Phone', s.emergencyContactPhone),
          ],
        ),
        _ReviewSection(
          title: 'Medical notes',
          onEdit: () => notifier.goToStep(4),
          children: [
            _ReviewRow(
              'Notes',
              s.allergiesOrMedicalNotes?.isNotEmpty == true
                  ? s.allergiesOrMedicalNotes!
                  : 'None declared',
            ),
          ],
        ),
        _ReviewSection(
          title: 'Disciplines',
          onEdit: () => notifier.goToStep(5),
          children: [
            _ReviewRow(
              'Selected',
              s.selectedDisciplineIds.isEmpty
                  ? 'None'
                  : '${s.selectedDisciplineIds.length} discipline(s)',
            ),
          ],
        ),
        _ReviewSection(
          title: 'Consents',
          onEdit: () => notifier.goToStep(6),
          children: [
            _ReviewRow(
              'Data processing',
              s.dataProcessingConsent ? 'Agreed' : 'Not agreed',
              valueColor: s.dataProcessingConsent ? null : AppColors.error,
            ),
            _ReviewRow(
              'Photo & video',
              s.photoVideoConsent ? 'Consented' : 'Declined',
            ),
          ],
        ),
        _ReviewSection(
          title: 'Membership',
          onEdit: () => notifier.goToStep(8),
          children: const [_ReviewRow('Plan', 'Free trial')],
        ),
        const SizedBox(height: 8),
        Text(
          'By tapping "Create account" you confirm the details above are '
          'correct and agree to abide by dojo rules and our privacy policy.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
