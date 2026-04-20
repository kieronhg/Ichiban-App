import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/queued_check_in.dart';

/// Displays all pending queued check-ins, grouped by discipline + date.
/// Admins can discard individual check-ins or all check-ins for a group.
class QueuedCheckInsScreen extends ConsumerWidget {
  const QueuedCheckInsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(pendingQueuedCheckInsProvider);
    final disciplinesAsync = ref.watch(disciplineListProvider);
    final adultProfilesAsync = ref.watch(
      profilesByTypeProvider(ProfileType.adultStudent),
    );
    final juniorProfilesAsync = ref.watch(
      profilesByTypeProvider(ProfileType.juniorStudent),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Queued Check-ins')),
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (queue) {
          if (queue.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 56,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No pending check-ins.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          // Build lookups
          final disciplineNames = <String, String>{
            for (final d in disciplinesAsync.asData?.value ?? []) d.id: d.name,
          };
          final adultProfiles = adultProfilesAsync.asData?.value ?? [];
          final juniorProfiles = juniorProfilesAsync.asData?.value ?? [];
          final profileMap = {
            for (final p in [...adultProfiles, ...juniorProfiles]) p.id: p,
          };

          // Group by disciplineId + queueDate
          final grouped = _group(queue);
          final keys = grouped.keys.toList()
            ..sort((a, b) {
              // Sort by date descending, then discipline name ascending
              final dateCmp = b.$2.compareTo(a.$2);
              if (dateCmp != 0) return dateCmp;
              final nameA = disciplineNames[a.$1] ?? a.$1;
              final nameB = disciplineNames[b.$1] ?? b.$1;
              return nameA.compareTo(nameB);
            });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: keys.length,
            itemBuilder: (context, i) {
              final key = keys[i];
              final items = grouped[key]!;
              return _QueueGroup(
                disciplineId: key.$1,
                date: key.$2,
                items: items,
                disciplineNames: disciplineNames,
                profileMap: profileMap,
              );
            },
          );
        },
      ),
    );
  }

  /// Groups queued check-ins by (disciplineId, queueDate).
  Map<(String, DateTime), List<QueuedCheckIn>> _group(
    List<QueuedCheckIn> items,
  ) {
    final map = <(String, DateTime), List<QueuedCheckIn>>{};
    for (final item in items) {
      final key = (item.disciplineId, item.queueDate);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}

// ── Queue group ───────────────────────────────────────────────────────────────

class _QueueGroup extends ConsumerWidget {
  const _QueueGroup({
    required this.disciplineId,
    required this.date,
    required this.items,
    required this.disciplineNames,
    required this.profileMap,
  });

  final String disciplineId;
  final DateTime date;
  final List<QueuedCheckIn> items;
  final Map<String, String> disciplineNames;
  final Map<String, Profile> profileMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminId = ref.watch(currentAdminIdProvider);
    final disciplineName = disciplineNames[disciplineId] ?? disciplineId;
    final dateLabel = _dateLabel(date);
    final discardUseCase = ref.read(discardQueuedCheckInUseCaseProvider);

    Future<void> discardOne(String id) async {
      if (adminId == null) return;
      try {
        await discardUseCase.discardOne(id, adminId: adminId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }

    Future<void> discardAll() async {
      if (adminId == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard all?'),
          content: Text(
            'Discard all ${items.length} pending check-in${items.length == 1 ? '' : 's'} for $disciplineName on $dateLabel?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Discard all'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await discardUseCase.discardAll(disciplineId, date, adminId: adminId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Discarded ${items.length} check-in${items.length == 1 ? '' : 's'}.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disciplineName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: discardAll,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Discard all'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),

        // Queued check-in tiles
        ...items.map(
          (q) => _QueuedCheckInTile(
            item: q,
            profile: profileMap[q.studentId],
            onDiscard: () => discardOne(q.id),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    if (d == today) return 'Today';
    return DateFormat('EEE, d MMM yyyy').format(d);
  }
}

// ── Queued check-in tile ──────────────────────────────────────────────────────

class _QueuedCheckInTile extends StatelessWidget {
  const _QueuedCheckInTile({
    required this.item,
    required this.profile,
    required this.onDiscard,
  });

  final QueuedCheckIn item;
  final Profile? profile;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName ?? item.studentId;
    final timeLabel = DateFormat('HH:mm').format(item.queuedAt.toLocal());

    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.surfaceVariant),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(Icons.person_outline, size: 18, color: AppColors.primary),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          'Queued at $timeLabel',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: IconButton(
          tooltip: 'Discard',
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
          onPressed: onDiscard,
        ),
      ),
    );
  }
}
