import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/kiosk_mode_provider.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/student_session_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/profile.dart';

class StudentSelectScreen extends ConsumerStatefulWidget {
  const StudentSelectScreen({super.key});

  @override
  ConsumerState<StudentSelectScreen> createState() =>
      _StudentSelectScreenState();
}

class _StudentSelectScreenState extends ConsumerState<StudentSelectScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showExitKioskDialog(BuildContext context) async {
    final pinController = TextEditingController();
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Exit Kiosk Mode'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter the admin exit PIN to leave kiosk mode.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    decoration: InputDecoration(
                      labelText: 'Exit PIN',
                      prefixIcon: const Icon(Icons.lock_open_outlined),
                      errorText: errorMessage,
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setDialogState(() => errorMessage = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final kiosk = ref.read(kioskModeProvider);
                    if (kiosk.checkPin(pinController.text)) {
                      ref.read(kioskModeProvider.notifier).deactivate();
                      Navigator.of(dialogContext).pop();
                      context.go(RouteNames.entry);
                    } else {
                      setDialogState(() => errorMessage = 'Incorrect PIN');
                      pinController.clear();
                    }
                  },
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        );
      },
    );

    pinController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);
    final isKioskMode = ref.watch(kioskModeProvider).isActive;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: isKioskMode
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(RouteNames.entry),
              ),
        automaticallyImplyLeading: false,
        title: const Text('Who are you?'),
        actions: [
          if (isKioskMode)
            IconButton(
              icon: const Icon(Icons.lock_outlined),
              tooltip: 'Exit Kiosk Mode',
              onPressed: () => _showExitKioskDialog(context),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
        ),
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profiles) {
          final active = profiles.where((p) => p.isActive).toList();
          final filtered =
              _searchQuery.isEmpty
                    ? active
                    : active
                          .where(
                            (p) =>
                                p.fullName.toLowerCase().contains(_searchQuery),
                          )
                          .toList()
                ..sort((a, b) => a.lastName.compareTo(b.lastName));

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'No members match your search.'
                    : 'No active members found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _ProfileCard(
              profile: filtered[i],
              onTap: () {
                ref
                    .read(studentSessionProvider.notifier)
                    .selectProfile(filtered[i].id);
                context.go(RouteNames.studentPin);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onTap});

  final Profile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Text(
                '${profile.firstName[0]}${profile.lastName[0]}',
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                profile.firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                profile.lastName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
