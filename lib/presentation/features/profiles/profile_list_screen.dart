import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../dashboard/admin_drawer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/enums.dart' hide MembershipStatus;
import '../../../domain/entities/profile.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../shared/widgets/member_avatar.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/belt_strip.dart';

// ── ProfileListScreen ─────────────────────────────────────────────────────────

class ProfileListScreen extends ConsumerStatefulWidget {
  const ProfileListScreen({super.key});

  @override
  ConsumerState<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends ConsumerState<ProfileListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ProfileType? _typeFilter;
  RegistrationStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);

    return Scaffold(
      backgroundColor: AppColors.paper1,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: Text(
          'Members',
          style: GoogleFonts.notoSerifJp(fontWeight: FontWeight.w500),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink1,
              side: const BorderSide(color: AppColors.hairline),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              textStyle: GoogleFonts.ibmPlexSans(fontSize: 13),
            ),
            child: const Text('Export CSV'),
          ),
          const SizedBox(width: AppSpacing.s2),
          FilledButton.icon(
            onPressed: () => context.pushNamed('adminProfileCreate'),
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              'Add member',
              style: GoogleFonts.ibmPlexSans(fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: AppColors.paper0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
        ],
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profiles) {
          final filtered = _applyFilters(profiles);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterBar(
                searchController: _searchController,
                allProfiles: profiles,
                typeFilter: _typeFilter,
                statusFilter: _statusFilter,
                onSearch: (v) => setState(() => _searchQuery = v),
                onTypeChanged: (t) => setState(() => _typeFilter = t),
                onStatusChanged: (s) => setState(() => _statusFilter = s),
              ),
              const _TableHeaderRow(),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(
                        hasFilters: _hasActiveFilters,
                        onClearFilters: _clearFilters,
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          return _ProfileRow(
                            profile: p,
                            onTap: () => context.pushNamed(
                              'adminProfileDetail',
                              pathParameters: {'id': p.id},
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Profile> _applyFilters(List<Profile> profiles) {
    return profiles.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty || p.fullName.toLowerCase().contains(q);
      final matchesType =
          _typeFilter == null || p.profileTypes.contains(_typeFilter);
      final matchesStatus =
          _statusFilter == null || p.registrationStatus == _statusFilter;
      return matchesSearch && matchesType && matchesStatus;
    }).toList()..sort((a, b) => a.lastName.compareTo(b.lastName));
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _typeFilter != null || _statusFilter != null;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _typeFilter = null;
      _statusFilter = null;
    });
  }
}

// ── _FilterBar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.allProfiles,
    required this.typeFilter,
    required this.statusFilter,
    required this.onSearch,
    required this.onTypeChanged,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final List<Profile> allProfiles;
  final ProfileType? typeFilter;
  final RegistrationStatus? statusFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<ProfileType?> onTypeChanged;
  final ValueChanged<RegistrationStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final totalCount = allProfiles.length;
    final adultCount = allProfiles
        .where((p) => p.profileTypes.contains(ProfileType.adultStudent))
        .length;
    final juniorCount = allProfiles
        .where((p) => p.profileTypes.contains(ProfileType.juniorStudent))
        .length;
    final coachCount = allProfiles
        .where((p) => p.profileTypes.contains(ProfileType.coach))
        .length;
    final parentCount = allProfiles
        .where((p) => p.profileTypes.contains(ProfileType.parentGuardian))
        .length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper0,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s3,
        AppSpacing.s5,
        AppSpacing.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input
          SizedBox(
            height: 40,
            child: TextField(
              controller: searchController,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                color: AppColors.ink1,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name',
                hintStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 14,
                  color: AppColors.ink4,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.ink3,
                ),
                filled: true,
                fillColor: AppColors.paper0,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.crimson),
                ),
              ),
              onChanged: onSearch,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _IchibanChip(
                  'All $totalCount',
                  selected: typeFilter == null,
                  onTap: () => onTypeChanged(null),
                ),
                const SizedBox(width: 6),
                _IchibanChip(
                  'Adults $adultCount',
                  selected: typeFilter == ProfileType.adultStudent,
                  onTap: () => onTypeChanged(ProfileType.adultStudent),
                ),
                const SizedBox(width: 6),
                _IchibanChip(
                  'Juniors $juniorCount',
                  selected: typeFilter == ProfileType.juniorStudent,
                  onTap: () => onTypeChanged(ProfileType.juniorStudent),
                ),
                const SizedBox(width: 6),
                _IchibanChip(
                  'Coaches $coachCount',
                  selected: typeFilter == ProfileType.coach,
                  onTap: () => onTypeChanged(ProfileType.coach),
                ),
                const SizedBox(width: 6),
                _IchibanChip(
                  'Parents $parentCount',
                  selected: typeFilter == ProfileType.parentGuardian,
                  onTap: () => onTypeChanged(ProfileType.parentGuardian),
                ),
                const SizedBox(width: AppSpacing.s4),
                // Status filter — tap cycles through values
                _IchibanChip(
                  _statusLabel(statusFilter),
                  selected: statusFilter != null,
                  onTap: () => onStatusChanged(_nextStatus(statusFilter)),
                ),
                const SizedBox(width: 6),
                // Discipline filter — placeholder
                _IchibanChip('Discipline · Any', selected: false, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(RegistrationStatus? s) => switch (s) {
    null => 'Status · Any',
    RegistrationStatus.active => 'Status · Active',
    RegistrationStatus.trial => 'Status · Trial',
    RegistrationStatus.lapsed => 'Status · Lapsed',
    RegistrationStatus.pendingVerification => 'Status · Pending',
  };

  RegistrationStatus? _nextStatus(RegistrationStatus? current) =>
      switch (current) {
        null => RegistrationStatus.active,
        RegistrationStatus.active => RegistrationStatus.trial,
        RegistrationStatus.trial => RegistrationStatus.lapsed,
        RegistrationStatus.lapsed => null,
        RegistrationStatus.pendingVerification => null,
      };
}

// ── _IchibanChip ──────────────────────────────────────────────────────────────
// Mono pill chip — ink-1 bg when active, paper-2 with hairline border inactive.

class _IchibanChip extends StatelessWidget {
  const _IchibanChip(this.label, {required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.short,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink1 : AppColors.paper2,
          border: Border.all(
            color: selected ? AppColors.ink1 : AppColors.hairline,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            letterSpacing: 0.1 * 11,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.paper0 : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

// ── _TableHeaderRow ───────────────────────────────────────────────────────────
// Column labels matching the grid of _ProfileRow.

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paper2,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: 10,
      ),
      child: Row(
        children: [
          // 32px avatar + 12px gap = 44px total placeholder
          const SizedBox(width: 44),
          Expanded(flex: 3, child: _col('Name')),
          Expanded(flex: 3, child: _col('Discipline · Rank')),
          Expanded(flex: 2, child: _col('Role')),
          Expanded(flex: 2, child: _col('Status')),
          const SizedBox(width: 20), // arrow placeholder
        ],
      ),
    );
  }

  Widget _col(String text) => Text(
    text.toUpperCase(),
    style: GoogleFonts.ibmPlexMono(
      fontSize: 10,
      letterSpacing: 0.12 * 10,
      fontWeight: FontWeight.w500,
      color: AppColors.ink3,
    ),
  );
}

// ── _ProfileRow ───────────────────────────────────────────────────────────────
// Dense tabular row: avatar | name+sub | rank | role badge | status badge | →

class _ProfileRow extends ConsumerWidget {
  const _ProfileRow({required this.profile, required this.onTap});

  final Profile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load enrollment + discipline + rank data
    final enrollmentsAsync = ref.watch(
      allEnrollmentsForStudentProvider(profile.id),
    );
    final disciplines = ref.watch(disciplineListProvider).asData?.value ?? [];

    final enrollment = enrollmentsAsync.asData?.value
        .where((e) => e.isActive)
        .firstOrNull;

    Widget rankCell = const SizedBox.shrink();
    if (enrollment != null) {
      final discipline = disciplines
          .where((d) => d.id == enrollment.disciplineId)
          .firstOrNull;
      final ranks =
          ref.watch(rankListProvider(enrollment.disciplineId)).asData?.value ??
          [];
      final rank = ranks
          .where((r) => r.id == enrollment.currentRankId)
          .firstOrNull;

      if (rank != null && discipline != null) {
        if (discipline.name.toLowerCase() == 'kendo') {
          rankCell = Align(
            alignment: Alignment.centerLeft,
            child: KendoRankChip(label: rank.name),
          );
        } else {
          final beltColor = BeltColorResolver.fromHex(rank.colourHex);
          final isWhite = BeltColorResolver.isWhiteBelt(rank.colourHex);
          final stripe = BeltColorResolver.stripeFromRank(rank);
          rankCell = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BeltStrip(
                color: beltColor,
                size: BeltSize.sm,
                stripe: stripe,
                isWhite: isWhite,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${rank.name} · ${discipline.name}',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    color: AppColors.ink2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }
      }
    }

    final age = _computeAge(profile.dateOfBirth);
    final joined = DateFormat('MMM yyyy').format(profile.registrationDate);
    final role = _primaryRole(profile);
    final status = _membershipStatus(profile);

    return Material(
      color: AppColors.paper0,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.paper3,
        highlightColor: AppColors.paper3.withValues(alpha: 0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s5,
                vertical: 14,
              ),
              child: Row(
                children: [
                  MemberAvatar(
                    initials: '${profile.firstName[0]}${profile.lastName[0]}',
                    size: AvatarSize.sm,
                  ),
                  const SizedBox(width: 12), // 32 + 12 = 44 aligns with header
                  // Name + subtitle
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profile.fullName,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$age y · joined $joined',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Discipline + rank
                  Expanded(flex: 3, child: rankCell),
                  // Role badge
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: RoleBadge(role: role),
                    ),
                  ),
                  // Status badge
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: MembershipBadge(status: status),
                    ),
                  ),
                  // Arrow indicator
                  Text(
                    '→',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.hairline),
          ],
        ),
      ),
    );
  }

  int _computeAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  MemberRole _primaryRole(Profile p) {
    if (p.isCoach) return MemberRole.coach;
    if (p.isJunior) return MemberRole.junior;
    if (p.isAdult) return MemberRole.adult;
    return MemberRole.parent;
  }

  MembershipStatus _membershipStatus(Profile p) =>
      switch (p.registrationStatus) {
        RegistrationStatus.active => MembershipStatus.active,
        RegistrationStatus.trial => MembershipStatus.trial,
        RegistrationStatus.lapsed => MembershipStatus.lapsed,
        RegistrationStatus.pendingVerification => MembershipStatus.trial,
      };
}

// ── _EmptyState ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters, required this.onClearFilters});

  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.filter_list_off : Icons.people_outline,
              size: 48,
              color: AppColors.ink4,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              hasFilters
                  ? 'No members match your filters.'
                  : 'No members yet.\nTap + to add the first one.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 15,
                color: AppColors.ink3,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: AppSpacing.s4),
              TextButton(
                onPressed: onClearFilters,
                child: Text(
                  'Clear filters',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    color: AppColors.crimson,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
