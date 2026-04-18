import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/profile.dart';

/// Read-only profile view for the student-facing app.
///
/// Receives [profileId] from the student session (set after PIN entry).
/// All data is live via [profileProvider].
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(profileId));

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }
          return _StudentProfileView(profile: profile);
        },
      ),
    );
  }
}

class _StudentProfileView extends StatelessWidget {
  const _StudentProfileView({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Avatar & name ──────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: Text(
                  '${profile.firstName[0]}${profile.lastName[0]}',
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.fullName,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _typeLabels(profile.profileTypes),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Personal ───────────────────────────────────────────────────
        _SectionCard(
          title: 'Personal',
          children: [
            _Row('Date of birth',
                DateFormat('d MMMM yyyy').format(profile.dateOfBirth)),
            if (profile.gender != null)
              _Row('Gender', profile.gender!),
            _Row('Member since',
                DateFormat('d MMMM yyyy').format(profile.registrationDate)),
          ],
        ),
        const SizedBox(height: 12),

        // ── Contact ────────────────────────────────────────────────────
        _SectionCard(
          title: 'Contact',
          children: [
            _Row('Phone', profile.phone),
            _Row('Email', profile.email),
            _Row('Address', _formatAddress(profile)),
          ],
        ),
        const SizedBox(height: 12),

        // ── Emergency contact ──────────────────────────────────────────
        _SectionCard(
          title: 'Emergency Contact',
          children: [
            _Row('Name', profile.emergencyContactName),
            _Row('Relationship', profile.emergencyContactRelationship),
            _Row('Phone', profile.emergencyContactPhone),
          ],
        ),
        const SizedBox(height: 12),

        // ── Medical & consent ──────────────────────────────────────────
        _SectionCard(
          title: 'Medical & Consent',
          children: [
            _Row(
              'Photo / video consent',
              profile.photoVideoConsent ? 'Given' : 'Not given',
            ),
            if (profile.allergiesOrMedicalNotes != null &&
                profile.allergiesOrMedicalNotes!.isNotEmpty)
              _Row('Allergies / medical notes',
                  profile.allergiesOrMedicalNotes!),
          ],
        ),
        const SizedBox(height: 24),

        // ── Edit note ──────────────────────────────────────────────────
        Center(
          child: Text(
            'To update your details, please speak to a member of staff.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatAddress(Profile p) => [
        p.addressLine1,
        if (p.addressLine2 != null) p.addressLine2!,
        p.city,
        p.county,
        p.postcode,
        p.country,
      ].join(', ');

  String _typeLabels(List<ProfileType> types) => types
      .map((t) => switch (t) {
            ProfileType.adultStudent => 'Adult Student',
            ProfileType.juniorStudent => 'Junior Student',
            ProfileType.coach => 'Coach',
            ProfileType.parentGuardian => 'Parent / Guardian',
          })
      .join(' · ');
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
