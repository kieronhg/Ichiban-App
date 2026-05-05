import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../core/providers/membership_providers.dart';
import '../../../core/providers/payments_providers.dart';
import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/settings_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/entities/cash_payment.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_record.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/payt_session.dart';
import '../../../domain/entities/profile.dart';
import '../../shared/widgets/member_avatar.dart';

class ProfileDetailScreen extends ConsumerWidget {
  const ProfileDetailScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(profileId));

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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

// ── Main view ────────────────────────────────────────────────────────────────

class _ProfileDetailView extends ConsumerWidget {
  const _ProfileDetailView({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(profile.fullName),
          actions: [
            OutlinedButton(
              onPressed: () => context.pushNamed('adminGrading'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink1,
                side: const BorderSide(color: AppColors.hairline),
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Add to grading'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () =>
                  context.pushNamed('adminPaymentsRecord', extra: profile.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink1,
                side: const BorderSide(color: AppColors.hairline),
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Record payment'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => context.pushNamed(
                'adminProfileEdit',
                pathParameters: {'id': profile.id},
                extra: profile,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Edit'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            // Fixed profile hero — visible across all tabs
            _ProfileHero(profile: profile),
            // Tab bar — pinned below hero
            Container(
              color: AppColors.paper1,
              child: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Membership'),
                  Tab(text: 'Disciplines & Grading'),
                  Tab(text: 'Payments'),
                ],
              ),
            ),
            // Scrollable tab content
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(profile: profile, ref: ref),
                  _MembershipTab(profile: profile, ref: ref),
                  _DisciplinesGradingTab(profile: profile),
                  _PaymentsTab(profileId: profile.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile hero ─────────────────────────────────────────────────────────────

class _ProfileHero extends ConsumerWidget {
  const _ProfileHero({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(
      allEnrollmentsForStudentProvider(profile.id),
    );
    final attendanceAsync = ref.watch(
      attendanceHistoryForStudentProvider(profile.id),
    );

    final activeEnrollments =
        enrollmentsAsync.asData?.value.where((e) => e.isActive).toList() ?? [];

    // Most recent attendance record
    final allRecords = attendanceAsync.asData?.value ?? [];
    final lastRecord = allRecords.isNotEmpty
        ? allRecords.reduce(
            (a, b) => a.sessionDate.isAfter(b.sessionDate) ? a : b,
          )
        : null;

    final age = _calcAge(profile.dateOfBirth);
    final dobLabel = DateFormat('d MMM yyyy').format(profile.dateOfBirth);
    final joinedLabel = DateFormat(
      'd MMM yyyy',
    ).format(profile.registrationDate);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.paper2,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          MemberAvatar(
            initials: '${profile.firstName[0]}${profile.lastName[0]}',
            size: AvatarSize.xl,
          ),
          const SizedBox(width: 24),

          // Name + badges + belt strips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role + status badges
                Row(
                  children: [
                    _RoleBadge(profile: profile),
                    const SizedBox(width: 8),
                    _StatusBadge(isActive: profile.isActive),
                  ],
                ),
                const SizedBox(height: 8),
                // Display name
                Text(
                  profile.fullName,
                  style: GoogleFonts.notoSerifJp(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    color: AppColors.ink1,
                  ),
                ),
                const SizedBox(height: 4),
                // Age · DOB · joined
                Text(
                  '$age years · DOB $dobLabel · joined $joinedLabel',
                  style: const TextStyle(fontSize: 13, color: AppColors.ink3),
                ),
                if (activeEnrollments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: activeEnrollments
                        .map((e) => _BeltHeroChip(enrollment: e))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Last check-in (right column)
          if (lastRecord != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'LAST CHECK-IN',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 10,
                    letterSpacing: 0.14 * 10,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCheckInDate(lastRecord.sessionDate),
                  style: GoogleFonts.notoSerifJp(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _checkInMethodLabel(lastRecord.checkInMethod),
                  style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static int _calcAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  static String _formatCheckInDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) {
      return 'Today · ${DateFormat('HH:mm').format(d)}';
    }
    return DateFormat('d MMM · HH:mm').format(d);
  }

  static String _checkInMethodLabel(CheckInMethod m) => switch (m) {
    CheckInMethod.self => 'via tablet',
    CheckInMethod.coach => 'via coach',
  };
}

// ── Belt hero chip ────────────────────────────────────────────────────────────

class _BeltHeroChip extends ConsumerWidget {
  const _BeltHeroChip({required this.enrollment});

  final Enrollment enrollment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(
      disciplineProvider(enrollment.disciplineId),
    );
    final ranksAsync = ref.watch(rankListProvider(enrollment.disciplineId));

    final disciplineName =
        disciplineAsync.asData?.value?.name ?? enrollment.disciplineId;
    final rank = ranksAsync.asData?.value
        .where((r) => r.id == enrollment.currentRankId)
        .firstOrNull;
    final rankName = rank?.name ?? '…';
    final beltColor = _parseHex(rank?.colourHex);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 10,
          decoration: BoxDecoration(
            color: beltColor ?? AppColors.ink2,
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                offset: Offset(0, -1),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Color(0x1FFFFFFF),
                offset: Offset(0, 1),
                blurRadius: 0,
              ),
            ],
            border: beltColor == null
                ? null
                : beltColor == Colors.white
                ? Border.all(color: AppColors.hairline)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$rankName · $disciplineName',
          style: const TextStyle(fontSize: 13, color: AppColors.ink1),
        ),
      ],
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.length != 7) return null;
    final value = int.tryParse('FF${hex.substring(1)}', radix: 16);
    return value != null ? Color(value) : null;
  }
}

// ── Role badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _roleStyle(profile);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 10,
          letterSpacing: 0.1 * 10,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }

  static (String, Color, Color) _roleStyle(Profile p) {
    if (p.isCoach) {
      return ('COACH', AppColors.crimsonWash, AppColors.crimson);
    }
    if (p.isParentGuardian) {
      return ('PARENT', AppColors.ochreWash, AppColors.ochre);
    }
    if (p.isJunior) {
      return ('JUNIOR', AppColors.teaWash, AppColors.tea);
    }
    return ('ADULT', AppColors.indigoWash, AppColors.indigo);
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = isActive
        ? ('ACTIVE', AppColors.successWash, AppColors.success)
        : ('INACTIVE', AppColors.paper3, AppColors.ink3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg.withAlpha(153),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 10,
              letterSpacing: 0.1 * 10,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.profile, required this.ref});

  final Profile profile;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 700;

        final leftColumn = _OverviewLeft(profile: profile);
        final rightColumn = _OverviewRight(profile: profile, ref: ref);

        if (wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 13, child: leftColumn),
                  const SizedBox(width: 14),
                  Expanded(flex: 10, child: rightColumn),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [leftColumn, const SizedBox(height: 14), rightColumn],
          ),
        );
      },
    );
  }
}

// ── Overview — left column ────────────────────────────────────────────────────

class _OverviewLeft extends StatelessWidget {
  const _OverviewLeft({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final hasAllergies =
        !profile.isAnonymised &&
        profile.allergiesOrMedicalNotes != null &&
        profile.allergiesOrMedicalNotes!.isNotEmpty;

    return _Sheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal section
          const _EyebrowLabel('Personal'),
          const SizedBox(height: 16),
          if (!profile.isAnonymised) ...[
            _KvRow('Full name', profile.fullName),
            _KvRow(
              'DOB · age',
              '${DateFormat('d MMM yyyy').format(profile.dateOfBirth)} · '
                  '${_calcAge(profile.dateOfBirth)} years',
            ),
            if (profile.gender != null) _KvRow('Gender', profile.gender!),
            _KvRow('Phone', profile.phone, mono: true),
            _KvRow('Email', profile.email),
            _KvRow('Address', _formatAddress(profile)),
          ] else ...[
            _KvRow(
              'Profile types',
              profile.profileTypes.map(_typeLabel).join(', '),
            ),
            _KvRow(
              'Member since',
              DateFormat('d MMMM yyyy').format(profile.registrationDate),
            ),
          ],

          const _DottedDivider(),

          // Emergency contact
          const _EyebrowLabel('Emergency contact'),
          const SizedBox(height: 16),
          if (!profile.isAnonymised) ...[
            _KvRow(
              'Name',
              '${profile.emergencyContactName} (${profile.emergencyContactRelationship})',
            ),
            _KvRow('Phone', profile.emergencyContactPhone, mono: true),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Data erased.',
                style: TextStyle(color: AppColors.ink3, fontSize: 14),
              ),
            ),
          ],

          const _DottedDivider(),

          // Medical notes
          Row(
            children: [
              const _EyebrowLabel('Medical notes'),
              const SizedBox(width: 10),
              _BadgeChip(
                label: 'Sensitive',
                bg: AppColors.ochreWash,
                fg: AppColors.ochre,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasAllergies)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.ochreWash,
                border: const Border(
                  left: BorderSide(color: AppColors.ochre, width: 2),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                profile.allergiesOrMedicalNotes!,
                style: const TextStyle(fontSize: 14, color: AppColors.ink1),
              ),
            )
          else
            const Text(
              'No medical notes recorded.',
              style: TextStyle(fontSize: 14, color: AppColors.ink3),
            ),
        ],
      ),
    );
  }

  static int _calcAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  static String _formatAddress(Profile p) => [
    p.addressLine1,
    if (p.addressLine2 != null) p.addressLine2!,
    p.city,
    p.county,
    p.postcode,
    p.country,
  ].join(', ');

  static String _typeLabel(ProfileType t) => switch (t) {
    ProfileType.adultStudent => 'Adult Student',
    ProfileType.juniorStudent => 'Junior Student',
    ProfileType.coach => 'Coach',
    ProfileType.parentGuardian => 'Parent / Guardian',
  };
}

// ── Overview — right column ────────────────────────────────────────────────────

class _OverviewRight extends StatelessWidget {
  const _OverviewRight({required this.profile, required this.ref});

  final Profile profile;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status banners
        if (profile.requiresReConsent)
          _ReConsentBanner(profile: profile, ref: ref),
        if (profile.isAnonymised)
          _InfoBanner(
            color: AppColors.ink3,
            icon: Icons.manage_accounts_outlined,
            message:
                'Personal data erased'
                '${profile.anonymisedAt != null ? ' on ${DateFormat('d MMM yyyy').format(profile.anonymisedAt!)}' : ''}.'
                ' Historical records are retained.',
          ),
        if (!profile.isActive)
          _InfoBanner(
            color: AppColors.error,
            icon: Icons.block,
            message: 'This profile is inactive.',
          ),

        // Membership summary
        _MembershipSummarySection(profileId: profile.id),
        const SizedBox(height: 14),

        // Communication preferences
        _Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _EyebrowLabel('Communication preferences'),
              const SizedBox(height: 12),
              _CommPrefRow(
                label: 'Billing reminders',
                value:
                    profile.communicationPreferences.billingAndPaymentReminders,
              ),
              _CommPrefRow(
                label: 'Grading notifications',
                value: profile.communicationPreferences.gradingNotifications,
              ),
              _CommPrefRow(
                label: 'Trial expiry',
                value: profile.communicationPreferences.trialExpiryReminders,
              ),
              _CommPrefRow(
                label: 'General announcements',
                value:
                    profile.communicationPreferences.generalDojoAnnouncements,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Consent + GDPR
        _Sheet(
          topBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _EyebrowLabel('Consent'),
              const SizedBox(height: 10),
              const _ConsentRow(label: 'Data processing · v2.1 · 03 Feb 2023'),
              const SizedBox(height: 6),
              _ConsentRow(
                label:
                    'Photo & video consent · '
                    '${DateFormat('d MMM yyyy').format(profile.registrationDate)}',
                value: profile.photoVideoConsent,
              ),
              const _DottedDivider(padding: EdgeInsets.symmetric(vertical: 14)),
              if (!profile.isAnonymised)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    onPressed: () => _confirmAnonymise(context, ref),
                    child: const Text('Anonymise profile (GDPR)'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAnonymise(BuildContext context, WidgetRef ref) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erase Personal Data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently erase all personal data for '
              '${profile.fullName}:',
            ),
            const SizedBox(height: 8),
            const Text(
              '• Name, date of birth, address\n'
              '• Phone, email\n'
              '• Emergency contact details\n'
              '• Allergies / medical notes\n'
              '• Gender, PIN, device token',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Historical records (attendance, grading, payments) '
              'are retained but will no longer be linked to any '
              'personal information.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'This action is irreversible.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (proceed != true || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text('Are you absolutely sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, erase permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(anonymiseProfileUseCaseProvider).call(profile.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erasure failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ── Membership tab ───────────────────────────────────────────────────────────

class _MembershipTab extends StatelessWidget {
  const _MembershipTab({required this.profile, required this.ref});

  final Profile profile;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Full membership section
        _MembershipSummarySection(profileId: profile.id),
        const SizedBox(height: 12),

        // Family links (juniors)
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

        // Invite status
        if (!profile.isCoach && !profile.isParentGuardian) ...[
          _InviteSection(profile: profile, ref: ref),
          const SizedBox(height: 12),
        ],

        // Admin notes
        if (profile.notes != null && profile.notes!.isNotEmpty) ...[
          _SectionCard(
            title: 'Admin Notes',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(profile.notes!),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Reset PIN
        if (profile.pinHash != null && !profile.isAnonymised) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.pin_outlined),
            label: const Text('Reset PIN'),
            onPressed: () => _confirmResetPin(context, ref),
          ),
          const SizedBox(height: 12),
        ],

        // Deactivate
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
    );
  }

  Future<void> _confirmResetPin(BuildContext context, WidgetRef ref) async {
    final isOwner = ref.read(isOwnerProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset PIN?'),
        content: Text(
          'This will clear ${profile.firstName}\'s PIN. '
          'They will be unable to sign in until '
          '${isOwner ? 'you assign' : 'an owner assigns'} a new PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(resetPinUseCaseProvider).call(profile.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${profile.firstName}\'s PIN has been cleared.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset PIN: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
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
      await ref.read(deactivateProfileUseCaseProvider).call(profile.id);
      if (context.mounted) context.pop();
    }
  }
}

// ── Disciplines & Grading tab ────────────────────────────────────────────────

class _DisciplinesGradingTab extends ConsumerWidget {
  const _DisciplinesGradingTab({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(
      allEnrollmentsForStudentProvider(profile.id),
    );
    final attendanceAsync = ref.watch(
      attendanceHistoryForStudentProvider(profile.id),
    );
    final gradingRecordsAsync = ref.watch(
      gradingRecordsForStudentProvider(profile.id),
    );
    final disciplinesAsync = ref.watch(disciplineListProvider);

    return enrollmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (enrollments) {
        final active = enrollments.where((e) => e.isActive).toList();
        final inactive = enrollments.where((e) => !e.isActive).toList();

        final disciplineNames = <String, String>{
          for (final d in disciplinesAsync.asData?.value ?? []) d.id: d.name,
        };

        final attendanceRecords = attendanceAsync.asData?.value ?? [];
        final byDiscipline = <String, List<AttendanceRecord>>{};
        for (final r in attendanceRecords) {
          byDiscipline.putIfAbsent(r.disciplineId, () => []).add(r);
        }
        for (final list in byDiscipline.values) {
          list.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Active Enrolments',
              headerAction: FilledButton.icon(
                onPressed: () => context.pushNamed(
                  'adminProfileEnrol',
                  pathParameters: {'id': profile.id},
                  extra: profile,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Enrol in Discipline'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
              children: active.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No active enrolments.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ]
                  : active
                        .map(
                          (e) => _ActiveEnrolmentRow(
                            enrollment: e,
                            profile: profile,
                          ),
                        )
                        .toList(),
            ),
            const SizedBox(height: 12),

            if (inactive.isNotEmpty)
              _SectionCard(
                title: 'Inactive Enrolments',
                children: [
                  ExpansionTile(
                    title: Text(
                      '${inactive.length} inactive '
                      '${inactive.length == 1 ? 'enrolment' : 'enrolments'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding: EdgeInsets.zero,
                    children: inactive
                        .map(
                          (e) => _InactiveEnrolmentRow(
                            enrollment: e,
                            profile: profile,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            _AttendanceHistorySection(
              byDiscipline: byDiscipline,
              disciplineNames: disciplineNames,
              isLoading: attendanceAsync is AsyncLoading,
            ),
            const SizedBox(height: 12),

            _GradingHistorySection(
              records: gradingRecordsAsync.asData?.value ?? [],
              disciplineNames: disciplineNames,
              isLoading: gradingRecordsAsync is AsyncLoading,
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ── Payments tab ────────────────────────────────────────────────────────────

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashAsync = ref.watch(cashPaymentsForProfileProvider(profileId));
    final paytAsync = ref.watch(paytSessionsForProfileProvider(profileId));
    final balance = ref.watch(outstandingBalanceProvider(profileId));
    final pendingCount = ref.watch(pendingPaytSessionCountProvider(profileId));

    final isLoading = cashAsync is AsyncLoading || paytAsync is AsyncLoading;
    final hasError = cashAsync is AsyncError || paytAsync is AsyncError;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError) {
      return const Center(child: Text('Could not load payment history.'));
    }

    final cashPayments = cashAsync.asData?.value ?? [];
    final paytSessions = paytAsync.asData?.value ?? [];

    final entries = <_PaymentEntry>[
      for (final c in cashPayments) _PaymentEntry.fromCash(c),
      for (final p in paytSessions) _PaymentEntry.fromPayt(p),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withAlpha(100)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_actions_outlined,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$pendingCount unpaid '
                    '${pendingCount == 1 ? 'session' : 'sessions'} — '
                    '£${balance.toStringAsFixed(2)} outstanding',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No payment records yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          _SectionCard(
            title: 'Payment History',
            children: entries.map((e) => _PaymentEntryRow(entry: e)).toList(),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Overview sub-widgets ──────────────────────────────────────────────────────

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child, this.topBorder = false});

  final Widget child;
  final bool topBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.paper0,
        border: Border(
          top: topBorder
              ? const BorderSide(color: AppColors.ink1, width: 2)
              : const BorderSide(color: AppColors.hairline),
          left: const BorderSide(color: AppColors.hairline),
          right: const BorderSide(color: AppColors.hairline),
          bottom: const BorderSide(color: AppColors.hairline),
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1C1B18),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0F1C1B18),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EyebrowLabel extends StatelessWidget {
  const _EyebrowLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'IBM Plex Mono',
        fontSize: 11,
        letterSpacing: 0.14 * 11,
        color: AppColors.ink3,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider({this.padding});

  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 20),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DottedLinePainter(),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    double x = 0;
    while (x < size.width) {
      canvas.drawCircle(Offset(x, 0), 1, paint);
      x += 6;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KvRow extends StatelessWidget {
  const _KvRow(this.label, this.value, {this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 10,
                letterSpacing: 0.14 * 10,
                color: AppColors.ink3,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontFamily: mono ? 'IBM Plex Mono' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommPrefRow extends StatelessWidget {
  const _CommPrefRow({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          _ToggleIndicator(on: value),
        ],
      ),
    );
  }
}

class _ToggleIndicator extends StatelessWidget {
  const _ToggleIndicator({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        color: on ? AppColors.crimson : AppColors.paper3,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: on ? AppColors.crimsonInk : AppColors.hairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisAlignment: on
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.paper0,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A1C1B18),
                    blurRadius: 2,
                    offset: Offset(0, 1),
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

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({required this.label, this.value = true});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value ? '✓' : '✗',
          style: TextStyle(
            fontSize: 13,
            color: value ? AppColors.success : AppColors.ink3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 9,
          letterSpacing: 0.1 * 9,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

// ── Payment entry model ──────────────────────────────────────────────────────

class _PaymentEntry {
  const _PaymentEntry({
    required this.date,
    required this.amount,
    required this.typeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.methodLabel,
    required this.notes,
  });

  final DateTime date;
  final double amount;
  final String typeLabel;
  final String statusLabel;
  final Color statusColor;
  final String methodLabel;
  final String? notes;

  factory _PaymentEntry.fromCash(CashPayment c) {
    final typeLabel = switch (c.paymentType) {
      PaymentType.membership => 'Membership',
      PaymentType.payt => 'PAYT',
      PaymentType.other => 'Other',
    };
    return _PaymentEntry(
      date: c.recordedAt,
      amount: c.amount,
      typeLabel: typeLabel,
      statusLabel: 'Paid',
      statusColor: AppColors.success,
      methodLabel: _methodLabel(c.paymentMethod),
      notes: c.notes,
    );
  }

  factory _PaymentEntry.fromPayt(PaytSession p) {
    final (statusLabel, statusColor) = switch (p.paymentStatus) {
      PaytPaymentStatus.pending => ('Pending', AppColors.warning),
      PaytPaymentStatus.paid => ('Paid', AppColors.success),
      PaytPaymentStatus.writtenOff => ('Written off', AppColors.textSecondary),
    };
    return _PaymentEntry(
      date: p.sessionDate,
      amount: p.amount,
      typeLabel: 'PAYT session',
      statusLabel: statusLabel,
      statusColor: statusColor,
      methodLabel: p.isPending ? '—' : _methodLabel(p.paymentMethod),
      notes: p.writeOffReason ?? p.notes,
    );
  }

  static String _methodLabel(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.bankTransfer => 'Bank transfer',
    PaymentMethod.stripe => 'Stripe',
    PaymentMethod.writtenOff => 'Written off',
    PaymentMethod.none => '—',
  };
}

// ── Payment entry row ────────────────────────────────────────────────────────

class _PaymentEntryRow extends StatelessWidget {
  const _PaymentEntryRow({required this.entry});

  final _PaymentEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(entry.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.typeLabel} · ${entry.methodLabel}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.notes!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '£${entry.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: entry.statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.statusLabel,
                  style: TextStyle(
                    color: entry.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Attendance history section ───────────────────────────────────────────────

class _AttendanceHistorySection extends StatelessWidget {
  const _AttendanceHistorySection({
    required this.byDiscipline,
    required this.disciplineNames,
    required this.isLoading,
  });

  final Map<String, List<AttendanceRecord>> byDiscipline;
  final Map<String, String> disciplineNames;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _SectionCard(
        title: 'Attendance History',
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (byDiscipline.isEmpty) {
      return _SectionCard(
        title: 'Attendance History',
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No attendance records yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    final sortedEntries = byDiscipline.entries.toList()
      ..sort((a, b) {
        final nameA = disciplineNames[a.key] ?? a.key;
        final nameB = disciplineNames[b.key] ?? b.key;
        return nameA.compareTo(nameB);
      });

    return _SectionCard(
      title: 'Attendance History',
      children: sortedEntries.map((entry) {
        final disciplineName = disciplineNames[entry.key] ?? entry.key;
        final records = entry.value;
        final total = records.length;

        return ExpansionTile(
          title: Text(
            disciplineName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '$total session${total == 1 ? '' : 's'} attended',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          children: records.map((r) {
            final dateLabel = DateFormat(
              'EEE, d MMM yyyy',
            ).format(r.sessionDate);
            final methodLabel = r.checkInMethod == CheckInMethod.self
                ? 'Self'
                : 'Coach';
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Icon(
                    r.checkInMethod == CheckInMethod.self
                        ? Icons.phone_android_outlined
                        : Icons.sports_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    methodLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

// ── Grading history section ──────────────────────────────────────────────────

class _GradingHistorySection extends StatelessWidget {
  const _GradingHistorySection({
    required this.records,
    required this.disciplineNames,
    required this.isLoading,
  });

  final List<GradingRecord> records;
  final Map<String, String> disciplineNames;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _SectionCard(
        title: 'Grading History',
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (records.isEmpty) {
      return _SectionCard(
        title: 'Grading History',
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No grading records yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    final byDiscipline = <String, List<GradingRecord>>{};
    for (final r in records) {
      byDiscipline.putIfAbsent(r.disciplineId, () => []).add(r);
    }
    for (final list in byDiscipline.values) {
      list.sort((a, b) => b.gradingDate.compareTo(a.gradingDate));
    }
    final sortedEntries = byDiscipline.entries.toList()
      ..sort((a, b) {
        final nameA = disciplineNames[a.key] ?? a.key;
        final nameB = disciplineNames[b.key] ?? b.key;
        return nameA.compareTo(nameB);
      });

    return _SectionCard(
      title: 'Grading History',
      children: sortedEntries.map((entry) {
        final disciplineName = disciplineNames[entry.key] ?? entry.key;
        final recs = entry.value;
        return ExpansionTile(
          title: Text(
            disciplineName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '${recs.length} promotion${recs.length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          children: recs.map((r) => _GradingRecordRow(record: r)).toList(),
        );
      }).toList(),
    );
  }
}

class _GradingRecordRow extends ConsumerWidget {
  const _GradingRecordRow({required this.record});

  final GradingRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranksAsync = ref.watch(rankListProvider(record.disciplineId));
    final ranks = ranksAsync.asData?.value ?? [];
    final toRank = ranks
        .where((r) => r.id == record.rankAchievedId)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          const Icon(
            Icons.military_tech_outlined,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toRank?.name ?? record.rankAchievedId,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (record.gradingScore != null)
                  Text(
                    'Score: ${record.gradingScore!.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            DateFormat('d MMM yyyy').format(record.gradingDate),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active enrolment row ─────────────────────────────────────────────────────

class _ActiveEnrolmentRow extends ConsumerWidget {
  const _ActiveEnrolmentRow({required this.enrollment, required this.profile});

  final Enrollment enrollment;
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(
      disciplineProvider(enrollment.disciplineId),
    );
    final ranksAsync = ref.watch(rankListProvider(enrollment.disciplineId));

    final disciplineName = disciplineAsync.when(
      loading: () => '…',
      error: (_, _) => enrollment.disciplineId,
      data: (d) => d?.name ?? enrollment.disciplineId,
    );

    final currentRank = ranksAsync.when(
      loading: () => null,
      error: (_, _) => null,
      data: (ranks) =>
          ranks.where((r) => r.id == enrollment.currentRankId).firstOrNull,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _BeltSwatch(colourHex: currentRank?.colourHex),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disciplineName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentRank?.name ?? enrollment.currentRankId,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Since ${DateFormat('d MMM yyyy').format(enrollment.enrollmentDate)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => context.pushNamed(
              'adminGrading',
              extra: enrollment.disciplineId,
            ),
            child: const Text('Grading', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => _confirmDeactivate(context, ref, disciplineName),
            child: const Text('Deactivate', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    String disciplineName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate Enrolment'),
        content: Text(
          'Are you sure you want to deactivate ${profile.fullName}\'s '
          'enrolment in $disciplineName? '
          'Their rank and history will be preserved.',
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
      try {
        await ref.read(deactivateEnrollmentUseCaseProvider).call(enrollment.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to deactivate enrolment: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ── Inactive enrolment row ───────────────────────────────────────────────────

class _InactiveEnrolmentRow extends ConsumerWidget {
  const _InactiveEnrolmentRow({
    required this.enrollment,
    required this.profile,
  });

  final Enrollment enrollment;
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplineAsync = ref.watch(
      disciplineProvider(enrollment.disciplineId),
    );
    final ranksAsync = ref.watch(rankListProvider(enrollment.disciplineId));

    final disciplineName = disciplineAsync.when(
      loading: () => '…',
      error: (_, _) => enrollment.disciplineId,
      data: (d) => d?.name ?? enrollment.disciplineId,
    );

    final currentRank = ranksAsync.when(
      loading: () => null,
      error: (_, _) => null,
      data: (ranks) =>
          ranks.where((r) => r.id == enrollment.currentRankId).firstOrNull,
    );

    final rankMissing =
        ranksAsync.hasValue &&
        ranksAsync.value!.isNotEmpty &&
        currentRank == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _BeltSwatch(colourHex: currentRank?.colourHex, muted: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disciplineName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentRank?.name ?? enrollment.currentRankId,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (rankMissing)
                  Text(
                    'Rank no longer on current ladder',
                    style: TextStyle(
                      color: AppColors.error.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => context.pushNamed(
              'adminProfileEnrol',
              pathParameters: {'id': profile.id},
              extra: profile,
            ),
            child: const Text('Reactivate', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Belt swatch (circle) ─────────────────────────────────────────────────────

class _BeltSwatch extends StatelessWidget {
  const _BeltSwatch({this.colourHex, this.muted = false});

  final String? colourHex;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    Color? swatchColor;
    if (colourHex != null && colourHex!.length == 7) {
      final hex = colourHex!.replaceFirst('#', '');
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) swatchColor = Color(value);
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color:
            swatchColor?.withAlpha(muted ? 120 : 255) ??
            AppColors.textSecondary.withAlpha(60),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textSecondary.withAlpha(60),
          width: 1,
        ),
      ),
    );
  }
}

// ── Invite section ────────────────────────────────────────────────────────────

class _InviteSection extends StatelessWidget {
  const _InviteSection({required this.profile, required this.ref});

  final Profile profile;
  final WidgetRef ref;

  static const _inviteDuration = Duration(hours: 24);

  Future<void> _sendInvite(BuildContext context) async {
    final profileRepo = ref.read(profileRepositoryProvider);
    final now = DateTime.now();
    await profileRepo.updateInviteStatus(
      id: profile.id,
      status: InviteStatus.pending,
      sentAt: now,
      expiresAt: now.add(_inviteDuration),
      resendCount: profile.inviteStatus == InviteStatus.notSent
          ? 0
          : profile.inviteResendCount + 1,
    );

    try {
      await FirebaseFunctions.instance
          .httpsCallable('sendStudentInviteEmail')
          .call({'profileId': profile.id});
    } catch (_) {
      // Email delivery is deferred until Cloud Functions are deployed.
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invite sent.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = profile.inviteStatus;

    String statusLabel;
    Color statusColor;
    switch (status) {
      case InviteStatus.notSent:
        statusLabel = 'Not sent';
        statusColor = AppColors.textSecondary;
      case InviteStatus.pending:
        statusLabel = 'Pending';
        statusColor = AppColors.warning;
      case InviteStatus.accepted:
        statusLabel = 'Accepted';
        statusColor = AppColors.success;
      case InviteStatus.expired:
        statusLabel = 'Expired';
        statusColor = AppColors.error;
    }

    return _SectionCard(
      title: 'Invite',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Status: ',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (profile.inviteSentAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sent: ${DateFormat('d MMM yyyy, HH:mm').format(profile.inviteSentAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (profile.inviteResendCount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Resent ${profile.inviteResendCount} time${profile.inviteResendCount == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (status != InviteStatus.accepted)
                TextButton(
                  onPressed: () => _sendInvite(context),
                  child: Text(
                    status == InviteStatus.notSent
                        ? 'Send Invite'
                        : 'Resend Invite',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section card (legacy-style, used in Disciplines & Grading / Payments) ────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.headerAction,
  });

  final String title;
  final List<Widget> children;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ?headerAction,
              ],
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
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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

// ── Re-consent banner ────────────────────────────────────────────────────────

class _ReConsentBanner extends StatelessWidget {
  const _ReConsentBanner({required this.profile, required this.ref});

  final Profile profile;
  final WidgetRef ref;

  Future<void> _recordReConsent(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Re-Consent'),
        content: const Text(
          'Confirm that this member has been informed of the updated privacy '
          'policy and has given their consent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Record Re-Consent'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(recordReConsentUseCaseProvider).call(profile.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Re-consent recorded.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record re-consent: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.policy_outlined,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Re-consent required',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'This member has not consented to the updated privacy policy. '
            'Please obtain consent and record it below.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _recordReConsent(context),
              child: const Text('Record Re-Consent'),
            ),
          ),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 14),
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
          Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Membership summary section ────────────────────────────────────────────────

class _MembershipSummarySection extends ConsumerWidget {
  const _MembershipSummarySection({required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(
      activeMembershipForProfileProvider(profileId),
    );

    return _SectionCard(
      title: 'Membership',
      headerAction: membershipAsync.asData?.value == null
          ? TextButton(
              onPressed: () => context.push(
                RouteNames.adminMembershipsCreate,
                extra: profileId,
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: const Text('Create', style: TextStyle(fontSize: 13)),
            )
          : TextButton(
              onPressed: () {
                final m = membershipAsync.asData!.value!;
                context.pushNamed(
                  'adminMembershipsDetail',
                  pathParameters: {'membershipId': m.id},
                  extra: m,
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: const Text('View', style: TextStyle(fontSize: 13)),
            ),
      children: [
        membershipAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e'),
          ),
          data: (membership) {
            if (membership == null) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.card_membership_outlined,
                      size: 16,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'No active membership.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }
            return _MembershipSummaryContent(membership: membership);
          },
        ),
      ],
    );
  }
}

class _MembershipSummaryContent extends StatelessWidget {
  const _MembershipSummaryContent({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    final renewalStr = membership.subscriptionRenewalDate != null
        ? 'Renews ${dateFormat.format(membership.subscriptionRenewalDate!)}'
        : membership.isPayAsYouTrain
        ? 'Pay As You Train — no renewal'
        : membership.trialEndDate != null
        ? 'Trial ends ${dateFormat.format(membership.trialEndDate!)}'
        : '—';

    final (statusLabel, statusColor) = switch (membership.status) {
      MembershipStatus.trial => ('Trial', AppColors.info),
      MembershipStatus.active => ('Active', AppColors.success),
      MembershipStatus.gracePeriod => ('Grace Period', AppColors.warning),
      MembershipStatus.lapsed => ('Lapsed', AppColors.warning),
      MembershipStatus.cancelled => ('Cancelled', AppColors.textSecondary),
      MembershipStatus.expired => ('Expired', AppColors.error),
      MembershipStatus.payt => ('PAYT', AppColors.accent),
    };

    final planLabel = switch (membership.planType) {
      MembershipPlanType.trial => 'Free Trial',
      MembershipPlanType.monthlyAdult => 'Monthly Adult',
      MembershipPlanType.monthlyJunior => 'Monthly Junior',
      MembershipPlanType.annualAdult => 'Annual Adult',
      MembershipPlanType.annualJunior => 'Annual Junior',
      MembershipPlanType.familyMonthly => 'Family Monthly',
      MembershipPlanType.payAsYouTrainAdult => 'PAYT Adult',
      MembershipPlanType.payAsYouTrainJunior => 'PAYT Junior',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  planLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            renewalStr,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (!membership.isPayAsYouTrain && !membership.isTrial) ...[
            const SizedBox(height: 2),
            Text(
              '£${membership.monthlyAmount.toStringAsFixed(2)}${_frequency(membership.planType)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _frequency(MembershipPlanType p) => switch (p) {
    MembershipPlanType.annualAdult ||
    MembershipPlanType.annualJunior => '/year',
    _ => '/month',
  };
}
