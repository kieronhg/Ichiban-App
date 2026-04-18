import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/profile.dart';
import '../../../core/providers/profile_providers.dart';

class ProfileListScreen extends ConsumerStatefulWidget {
  const ProfileListScreen({super.key});

  @override
  ConsumerState<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends ConsumerState<ProfileListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ProfileType? _typeFilter; // null = show all

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _TypeChip(
                      label: 'All',
                      selected: _typeFilter == null,
                      onTap: () => setState(() => _typeFilter = null),
                    ),
                    ...ProfileType.values.map((t) => _TypeChip(
                          label: _typelabel(t),
                          selected: _typeFilter == t,
                          onTap: () => setState(() => _typeFilter = t),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profiles) {
          final filtered = _applyFilters(profiles);
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty || _typeFilter != null
                        ? 'No profiles match your filters.'
                        : 'No profiles yet.\nTap + to add the first one.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            separatorBuilder: (_, i) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _ProfileTile(
              profile: filtered[i],
              onTap: () => context.pushNamed(
                'adminProfileDetail',
                pathParameters: {'id': filtered[i].id},
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('adminProfileCreate'),
        icon: const Icon(Icons.person_add),
        label: const Text('New Profile'),
      ),
    );
  }

  List<Profile> _applyFilters(List<Profile> profiles) {
    return profiles.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.fullName.toLowerCase().contains(_searchQuery);
      final matchesType =
          _typeFilter == null || p.profileTypes.contains(_typeFilter);
      return matchesSearch && matchesType;
    }).toList()
      ..sort((a, b) => a.lastName.compareTo(b.lastName));
  }

  String _typelabel(ProfileType t) => switch (t) {
        ProfileType.adultStudent => 'Adult',
        ProfileType.juniorStudent => 'Junior',
        ProfileType.coach => 'Coach',
        ProfileType.parentGuardian => 'Parent',
      };
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.accent,
        labelStyle: TextStyle(
          color: selected ? AppColors.textOnAccent : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile, required this.onTap});

  final Profile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          '${profile.firstName[0]}${profile.lastName[0]}',
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        profile.fullName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(_typeLabels(profile.profileTypes)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!profile.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Inactive',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }

  String _typeLabels(List<ProfileType> types) {
    return types.map((t) => switch (t) {
          ProfileType.adultStudent => 'Adult Student',
          ProfileType.juniorStudent => 'Junior Student',
          ProfileType.coach => 'Coach',
          ProfileType.parentGuardian => 'Parent / Guardian',
        }).join(' · ');
  }
}
