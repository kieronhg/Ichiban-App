import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/profile.dart';

class ProfileDetailScreen extends ConsumerWidget {
  const ProfileDetailScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(profileId));

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Profile not found.')),
          );
        }
        return _ProfileDetailView(profile: profile);
      },
    );
  }
}

class _ProfileDetailView extends ConsumerWidget {
  const _ProfileDetailView({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.pushNamed(
              'adminProfileEdit',
              pathParameters: {'id': profile.id},
              extra: profile,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status banner ────────────────────────────────────────────
          if (!profile.isActive)
            _InfoBanner(
              color: AppColors.error,
              icon: Icons.block,
              message: 'This profile is inactive.',
            ),

          // ── Identity ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Personal',
            children: [
              _DetailRow('First name', profile.firstName),
              _DetailRow('Last name', profile.lastName),
              _DetailRow(
                'Date of birth',
                DateFormat('d MMMM yyyy').format(profile.dateOfBirth),
              ),
              if (profile.gender != null)
                _DetailRow('Gender', profile.gender!),
              _DetailRow(
                'Profile types',
                profile.profileTypes.map(_typeLabel).join(', '),
              ),
              _DetailRow(
                'Member since',
                DateFormat('d MMMM yyyy').format(profile.registrationDate),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Contact ──────────────────────────────────────────────────
          _SectionCard(
            title: 'Contact',
            children: [
              _DetailRow('Phone', profile.phone),
              _DetailRow('Email', profile.email),
              _DetailRow('Address', _formatAddress(profile)),
            ],
          ),
          const SizedBox(height: 12),

          // ── Emergency contact ─────────────────────────────────────────
          _SectionCard(
            title: 'Emergency Contact',
            children: [
              _DetailRow('Name', profile.emergencyContactName),
              _DetailRow('Relationship', profile.emergencyContactRelationship),
              _DetailRow('Phone', profile.emergencyContactPhone),
            ],
          ),
          const SizedBox(height: 12),

          // ── Medical & consent ─────────────────────────────────────────
          _SectionCard(
            title: 'Medical & Consent',
            children: [
              _DetailRow(
                'Photo / video consent',
                profile.photoVideoConsent ? 'Given' : 'Not given',
              ),
              if (profile.allergiesOrMedicalNotes != null &&
                  profile.allergiesOrMedicalNotes!.isNotEmpty)
                _DetailRow(
                    'Allergies / medical notes',
                    profile.allergiesOrMedicalNotes!),
            ],
          ),
          const SizedBox(height: 12),

          // ── Family links (juniors) ────────────────────────────────────
          if (profile.isJunior) ...[
            _SectionCard(
              title: 'Family Links',
              children: [
                if (profile.parentProfileId != null)
                  _ProfileLinkRow(
                    label: 'Parent / Guardian',
                    profileId: profile.parentProfileId!,
                    ref: ref,
                  ),
                if (profile.secondParentProfileId != null)
                  _ProfileLinkRow(
                    label: 'Second Parent / Guardian',
                    profileId: profile.secondParentProfileId!,
                    ref: ref,
                  ),
                if (profile.payingParentId != null)
                  _ProfileLinkRow(
                    label: 'Paying Parent',
                    profileId: profile.payingParentId!,
                    ref: ref,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Communication ─────────────────────────────────────────────
          _SectionCard(
            title: 'Communication',
            children: [
              _DetailRow(
                'Preferences',
                profile.communicationPreferences.isEmpty
                    ? 'None set'
                    : profile.communicationPreferences
                        .map((c) => c.name)
                        .join(', '),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Admin notes ───────────────────────────────────────────────
          if (profile.notes != null && profile.notes!.isNotEmpty) ...[
            _SectionCard(
              title: 'Admin Notes',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Text(profile.notes!),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Membership summary placeholder ────────────────────────────
          _SectionCard(
            title: 'Membership',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Membership summary coming in a future phase.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Deactivate ────────────────────────────────────────────────
          if (profile.isActive)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
              ),
              icon: const Icon(Icons.person_off_outlined),
              label: const Text('Deactivate Profile'),
              onPressed: () => _confirmDeactivate(context, ref),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatAddress(Profile p) {
    return [
      p.addressLine1,
      if (p.addressLine2 != null) p.addressLine2!,
      p.city,
      p.county,
      p.postcode,
      p.country,
    ].join(', ');
  }

  String _typeLabel(ProfileType t) => switch (t) {
        ProfileType.adultStudent => 'Adult Student',
        ProfileType.juniorStudent => 'Junior Student',
        ProfileType.coach => 'Coach',
        ProfileType.parentGuardian => 'Parent / Guardian',
      };

  Future<void> _confirmDeactivate(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate Profile'),
        content: Text(
          'Are you sure you want to deactivate ${profile.fullName}? '
          'They will no longer appear in active member lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(deactivateProfileUseCaseProvider)
          .call(profile.id);
      if (context.mounted) context.pop();
    }
  }
}

// ── Shared detail widgets ──────────────────────────────────────────────────

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
            padding:
                const EdgeInsets.fromLTRB(16, 14, 16, 4),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

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
            width: 160,
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

class _ProfileLinkRow extends StatelessWidget {
  const _ProfileLinkRow({
    required this.label,
    required this.profileId,
    required this.ref,
  });

  final String label;
  final String profileId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider(profileId));
    return profileAsync.when(
      loading: () => _DetailRow(label, '…'),
      error: (_, stack) => _DetailRow(label, profileId),
      data: (p) => _DetailRow(label, p?.fullName ?? profileId),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
