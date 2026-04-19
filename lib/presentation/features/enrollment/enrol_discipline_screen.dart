import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/enrollment_providers.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/rank.dart';
import '../../../domain/use_cases/enrollment/enrol_student_use_case.dart';

/// Multi-step wizard screen for enrolling a student into a discipline.
///
/// Steps:
///   1 — Select discipline
///   2 — Select starting rank  (skipped for reactivation)
///   3 — Confirm
///
/// Handles both new enrolment and reactivation of a previous enrolment.
class EnrolDisciplineScreen extends ConsumerStatefulWidget {
  const EnrolDisciplineScreen({super.key, required this.profile});

  final Profile profile;

  @override
  ConsumerState<EnrolDisciplineScreen> createState() =>
      _EnrolDisciplineScreenState();
}

class _EnrolDisciplineScreenState extends ConsumerState<EnrolDisciplineScreen> {
  int _step = 1;

  // Selected values across steps
  Discipline? _selectedDiscipline;
  Rank? _selectedRank;

  // Whether the selected discipline has an existing inactive enrolment
  // (drives the reactivation path vs new-enrolment path)
  bool _isReactivation = false;
  Enrollment? _existingInactiveEnrollment;

  bool _isSaving = false;
  String? _errorMessage;

  // ── Step navigation ────────────────────────────────────────────────────

  void _onDisciplineSelected(
    Discipline discipline,
    bool isReactivation,
    Enrollment? existing,
  ) {
    setState(() {
      _selectedDiscipline = discipline;
      _isReactivation = isReactivation;
      _existingInactiveEnrollment = existing;
      _selectedRank = null;
      _errorMessage = null;
      _step = isReactivation ? 3 : 2; // skip rank step for reactivation
    });
  }

  void _onRankSelected(Rank rank) {
    setState(() {
      _selectedRank = rank;
      _errorMessage = null;
      _step = 3;
    });
  }

  void _goBack() {
    setState(() {
      _errorMessage = null;
      if (_step == 3 && !_isReactivation) {
        _step = 2;
      } else {
        _step = 1;
      }
    });
  }

  // ── Confirm ────────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_isReactivation) {
        await ref
            .read(reactivateEnrollmentUseCaseProvider)
            .call(
              studentId: widget.profile.id,
              disciplineId: _selectedDiscipline!.id,
            );
      } else {
        await ref
            .read(enrolStudentUseCaseProvider)
            .call(
              studentId: widget.profile.id,
              disciplineId: _selectedDiscipline!.id,
              startingRankId: _selectedRank!.id,
              dateOfBirth: widget.profile.dateOfBirth,
            );
      }

      if (mounted) context.pop();
    } on AgeRestrictionException catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enrol ${widget.profile.firstName}'),
        leading: _step == 1 ? null : BackButton(onPressed: _goBack),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_step) {
          1 => _StepSelectDiscipline(
            key: const ValueKey(1),
            profile: widget.profile,
            onSelected: _onDisciplineSelected,
          ),
          2 => _StepSelectRank(
            key: const ValueKey(2),
            discipline: _selectedDiscipline!,
            onSelected: _onRankSelected,
          ),
          _ => _StepConfirm(
            key: const ValueKey(3),
            profile: widget.profile,
            discipline: _selectedDiscipline!,
            rank: _selectedRank,
            isReactivation: _isReactivation,
            existingEnrollment: _existingInactiveEnrollment,
            isSaving: _isSaving,
            errorMessage: _errorMessage,
            onConfirm: _confirm,
          ),
        },
      ),
    );
  }
}

// ── Step 1 — Select Discipline ───────────────────────────────────────────────

class _StepSelectDiscipline extends ConsumerWidget {
  const _StepSelectDiscipline({
    super.key,
    required this.profile,
    required this.onSelected,
  });

  final Profile profile;
  final void Function(Discipline, bool isReactivation, Enrollment?) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDisciplinesAsync = ref.watch(activeDisciplineListProvider);
    final allEnrollmentsAsync = ref.watch(
      allEnrollmentsForStudentProvider(profile.id),
    );

    return activeDisciplinesAsync.when(
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

        final enrollments = allEnrollmentsAsync.asData?.value ?? [];
        final activeEnrollmentDisciplineIds = enrollments
            .where((e) => e.isActive)
            .map((e) => e.disciplineId)
            .toSet();
        final inactiveEnrollments = {
          for (final e in enrollments.where((e) => !e.isActive))
            e.disciplineId: e,
        };

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Select a discipline to enrol ${profile.firstName} in:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...disciplines.map((discipline) {
              final isActivelyEnrolled = activeEnrollmentDisciplineIds.contains(
                discipline.id,
              );
              final inactiveEnrollment = inactiveEnrollments[discipline.id];
              final isReactivation = inactiveEnrollment != null;

              return Card(
                elevation: 0,
                color: isActivelyEnrolled
                    ? AppColors.surface
                    : AppColors.surface,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isActivelyEnrolled
                        ? AppColors.textSecondary.withAlpha(60)
                        : AppColors.accent.withAlpha(60),
                  ),
                ),
                child: ListTile(
                  enabled: !isActivelyEnrolled,
                  title: Text(discipline.name),
                  subtitle: isActivelyEnrolled
                      ? Text(
                          'Already enrolled',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        )
                      : isReactivation
                      ? Text(
                          'Previously enrolled — tap to reactivate',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  trailing: isReactivation
                      ? Chip(
                          label: const Text(
                            'Reactivate',
                            style: TextStyle(fontSize: 11),
                          ),
                          backgroundColor: AppColors.accent.withAlpha(30),
                          side: BorderSide(
                            color: AppColors.accent.withAlpha(80),
                          ),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                        )
                      : isActivelyEnrolled
                      ? Icon(
                          Icons.check_circle_outline,
                          color: AppColors.textSecondary,
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: isActivelyEnrolled
                      ? null
                      : () => onSelected(
                          discipline,
                          isReactivation,
                          inactiveEnrollment,
                        ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Step 2 — Select Starting Rank ────────────────────────────────────────────

class _StepSelectRank extends ConsumerStatefulWidget {
  const _StepSelectRank({
    super.key,
    required this.discipline,
    required this.onSelected,
  });

  final Discipline discipline;
  final void Function(Rank) onSelected;

  @override
  ConsumerState<_StepSelectRank> createState() => _StepSelectRankState();
}

class _StepSelectRankState extends ConsumerState<_StepSelectRank> {
  Rank? _highlighted; // track selection before confirming

  @override
  Widget build(BuildContext context) {
    final ranksAsync = ref.watch(rankListProvider(widget.discipline.id));

    return ranksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (ranks) {
        if (ranks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No ranks found for ${widget.discipline.name}.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        // Default to bottom rank (highest displayOrder index = last in list
        // since list is ordered by displayOrder ascending)
        final defaultRank = ranks.last;
        final selected = _highlighted ?? defaultRank;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Select the starting rank for ${widget.discipline.name}:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ranks.length,
                itemBuilder: (context, index) {
                  final rank = ranks[index];
                  final isSelected = rank.id == selected.id;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 6),
                    color: isSelected
                        ? AppColors.accent.withAlpha(20)
                        : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.accent.withAlpha(150)
                            : AppColors.surface,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: _BeltSwatchSmall(colourHex: rank.colourHex),
                      title: Text(
                        rank.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: index == ranks.length - 1
                          ? Text(
                              'Bottom rank — default',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(
                              Icons.radio_button_checked,
                              color: AppColors.accent,
                            )
                          : const Icon(Icons.radio_button_unchecked),
                      onTap: () => setState(() => _highlighted = rank),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => widget.onSelected(selected),
                child: const Text('Continue'),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Step 3 — Confirm ─────────────────────────────────────────────────────────

class _StepConfirm extends StatelessWidget {
  const _StepConfirm({
    super.key,
    required this.profile,
    required this.discipline,
    required this.rank,
    required this.isReactivation,
    required this.existingEnrollment,
    required this.isSaving,
    required this.errorMessage,
    required this.onConfirm,
  });

  final Profile profile;
  final Discipline discipline;
  final Rank? rank; // null for reactivation path
  final bool isReactivation;
  final Enrollment? existingEnrollment;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('d MMMM yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            isReactivation ? 'Reactivate Enrolment' : 'Confirm Enrolment',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isReactivation
                ? 'This student was previously enrolled. '
                      'Reactivating will restore their enrolment at their '
                      'previously held rank.'
                : 'Please review the details below before confirming.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Summary card
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ConfirmRow('Student', profile.fullName),
                  const Divider(height: 24),
                  _ConfirmRow('Discipline', discipline.name),
                  const Divider(height: 24),
                  _ConfirmRow(
                    'Starting rank',
                    rank?.name ?? '(retained from previous enrolment)',
                  ),
                  const Divider(height: 24),
                  _ConfirmRow('Enrolment date', today),
                  if (isReactivation) ...[
                    const Divider(height: 24),
                    _ConfirmRow(
                      'Action',
                      'Reactivate existing record',
                      valueColor: AppColors.accent,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Error message (age restriction or other)
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Actions
          FilledButton(
            onPressed: isSaving ? null : onConfirm,
            child: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isReactivation
                        ? 'Reactivate Enrolment'
                        : 'Confirm Enrolment',
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared local widget ──────────────────────────────────────────────────────

class _BeltSwatchSmall extends StatelessWidget {
  const _BeltSwatchSmall({this.colourHex});

  final String? colourHex;

  @override
  Widget build(BuildContext context) {
    Color? swatchColor;
    if (colourHex != null && colourHex!.length == 7) {
      final hex = colourHex!.replaceFirst('#', '');
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) swatchColor = Color(value);
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: swatchColor ?? AppColors.textSecondary.withAlpha(60),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textSecondary.withAlpha(60),
          width: 1,
        ),
      ),
    );
  }
}
