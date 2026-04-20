import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/attendance_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/student_session_provider.dart';
import '../../../domain/entities/attendance_session.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/use_cases/attendance/self_check_in_use_case.dart';
import '../../../domain/use_cases/attendance/queue_check_in_use_case.dart';

/// Multi-step self check-in flow for students.
///
/// Steps:
///   1 — Select discipline (active only, shows only those with enrollments
///       or all active disciplines)
///   2a — If session(s) exist for today: select session → check in
///   2b — If no session exists today: offer to queue or cancel
///
/// Handles all result cases:
///   - success / successWithAutoEnrol → success screen
///   - alreadyCheckedIn → inform user
///   - queued / alreadyQueued → inform user
///   - AgeRestrictionException → "speak to a coach" message
class SelfCheckInScreen extends ConsumerStatefulWidget {
  const SelfCheckInScreen({super.key});

  @override
  ConsumerState<SelfCheckInScreen> createState() => _SelfCheckInScreenState();
}

class _SelfCheckInScreenState extends ConsumerState<SelfCheckInScreen> {
  int _step = 1;

  Discipline? _selectedDiscipline;

  bool _isLoading = false;
  String? _errorMessage;

  // ── Navigation ─────────────────────────────────────────────────────────

  void _onDisciplineSelected(Discipline d) {
    setState(() {
      _selectedDiscipline = d;
      _errorMessage = null;
      _step = 2;
    });
  }

  void _goBack() {
    setState(() {
      _errorMessage = null;
      if (_step > 1) _step = 1;
    });
  }

  // ── Check-in actions ───────────────────────────────────────────────────

  Future<void> _checkIn(AttendanceSession session) async {
    final session_ = session;
    final profileId = ref.read(studentSessionProvider).profileId;
    if (profileId == null) return;

    final profileAsync = ref.read(profileProvider(profileId));
    final profile = profileAsync.asData?.value;
    if (profile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(selfCheckInUseCaseProvider)
          .call(
            studentId: profileId,
            sessionId: session_.id,
            disciplineId: session_.disciplineId,
            sessionDate: session_.sessionDate,
            studentDateOfBirth: profile.dateOfBirth,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      switch (result) {
        case SelfCheckInResult.success:
        case SelfCheckInResult.successWithAutoEnrol:
          _showOutcome(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: 'Checked in!',
            body: result == SelfCheckInResult.successWithAutoEnrol
                ? "You've been automatically enrolled and checked in. Welcome!"
                : "You're checked in for today's session.",
            autoEnrolled: result == SelfCheckInResult.successWithAutoEnrol,
          );
        case SelfCheckInResult.alreadyCheckedIn:
          setState(() {
            _errorMessage = "You're already checked in to this session.";
          });
      }
    } on StateError catch (e) {
      // No ranks found for discipline — cannot auto-enrol
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      final msg = e.toString();
      // AgeRestrictionException message
      if (msg.contains('age') || msg.contains('Age')) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to auto-enrol — please speak to a coach.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
      }
    }
  }

  Future<void> _queueCheckIn() async {
    final profileId = ref.read(studentSessionProvider).profileId;
    if (profileId == null || _selectedDiscipline == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(queueCheckInUseCaseProvider)
          .call(studentId: profileId, disciplineId: _selectedDiscipline!.id);

      if (!mounted) return;
      setState(() => _isLoading = false);

      switch (result) {
        case QueueCheckInResult.queued:
          _showOutcome(
            icon: Icons.schedule_outlined,
            iconColor: AppColors.accent,
            title: 'You\'re in the queue!',
            body:
                'No session exists yet for today. When the coach creates one, you\'ll be automatically checked in.',
          );
        case QueueCheckInResult.alreadyQueued:
          _showOutcome(
            icon: Icons.info_outline,
            iconColor: AppColors.textSecondary,
            title: 'Already queued',
            body:
                'You\'re already queued for this discipline today. You\'ll be checked in automatically when the session is created.',
          );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _showOutcome({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    bool autoEnrolled = false,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, color: iconColor, size: 48),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(body, textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Return to student home
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        leading: _step == 1 ? null : BackButton(onPressed: _goBack),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_step) {
          1 => _StepSelectDiscipline(
            key: const ValueKey(1),
            onSelected: _onDisciplineSelected,
          ),
          _ => _StepSelectSession(
            key: ValueKey(_selectedDiscipline?.id ?? 2),
            discipline: _selectedDiscipline!,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            onSessionSelected: _checkIn,
            onQueue: _queueCheckIn,
          ),
        },
      ),
    );
  }
}

// ── Step 1 — Select Discipline ───────────────────────────────────────────────

class _StepSelectDiscipline extends ConsumerWidget {
  const _StepSelectDiscipline({super.key, required this.onSelected});

  final void Function(Discipline) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplinesAsync = ref.watch(activeDisciplineListProvider);

    return disciplinesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (disciplines) {
        if (disciplines.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No active disciplines available.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: disciplines.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = disciplines[i];
            return Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.surfaceVariant),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.sports_martial_arts,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  d.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onSelected(d),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Step 2 — Select Session (or Queue) ───────────────────────────────────────

class _StepSelectSession extends ConsumerWidget {
  const _StepSelectSession({
    super.key,
    required this.discipline,
    required this.isLoading,
    required this.errorMessage,
    required this.onSessionSelected,
    required this.onQueue,
  });

  final Discipline discipline;
  final bool isLoading;
  final String? errorMessage;
  final void Function(AttendanceSession) onSessionSelected;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(
      todaySessionsForDisciplineProvider(discipline.id),
    );

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (sessions) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                discipline.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Today — ${DateFormat('d MMM yyyy').format(DateTime.now())}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              if (sessions.isEmpty) ...[
                // No sessions today
                _NoSessionContent(errorMessage: errorMessage, onQueue: onQueue),
              ] else ...[
                // Sessions available — pick one
                Text(
                  'Select your session:',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...sessions.map(
                  (s) => _SessionOption(
                    session: s,
                    onTap: () => onSessionSelected(s),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NoSessionContent extends StatelessWidget {
  const _NoSessionContent({required this.errorMessage, required this.onQueue});

  final String? errorMessage;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'No session yet today',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'The coach hasn\'t created today\'s session yet. You can join the queue and you\'ll be automatically checked in when the session is created.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onQueue,
          icon: const Icon(Icons.queue_outlined),
          label: const Text('Join the Queue'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _SessionOption extends StatelessWidget {
  const _SessionOption({required this.session, required this.onTap});

  final AttendanceSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeLabel = session.startTime.isNotEmpty
        ? '${session.startTime} – ${session.endTime}'
        : 'No time set';

    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.surfaceVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(Icons.access_time, color: AppColors.primary, size: 20),
        ),
        title: Text(
          timeLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: session.notes != null
            ? Text(
                session.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
