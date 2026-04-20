import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/grading_event.dart';
import '../../../domain/entities/grading_event_student.dart';
import '../../../domain/entities/rank.dart';

class RecordResultsScreen extends ConsumerStatefulWidget {
  const RecordResultsScreen({
    super.key,
    required this.event,
    required this.eventStudent,
  });

  final GradingEvent event;
  final GradingEventStudent eventStudent;

  @override
  ConsumerState<RecordResultsScreen> createState() =>
      _RecordResultsScreenState();
}

class _RecordResultsScreenState extends ConsumerState<RecordResultsScreen> {
  GradingOutcome? _outcome;
  Rank? _selectedRank;
  final _scoreCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isPromoted => _outcome == GradingOutcome.promoted;

  Future<void> _save() async {
    if (_outcome == null) {
      _showError('Please select an outcome.');
      return;
    }
    if (_isPromoted && _selectedRank == null) {
      _showError('Please select the rank achieved.');
      return;
    }

    double? score;
    if (_isPromoted && _scoreCtrl.text.trim().isNotEmpty) {
      score = double.tryParse(_scoreCtrl.text.trim());
      if (score == null || score < 0 || score > 100) {
        _showError('Score must be a number between 0 and 100.');
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final adminId = ref.read(currentAdminIdProvider) ?? '';
      await ref
          .read(recordGradingResultsUseCaseProvider)
          .call(
            eventStudent: widget.eventStudent,
            eventDate: widget.event.eventDate,
            outcome: _outcome!,
            rankAchievedId: _isPromoted ? _selectedRank!.id : null,
            gradingScore: score,
            adminId: adminId,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Result recorded.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(
      profileProvider(widget.eventStudent.studentId),
    );
    final ranksAsync = ref.watch(
      rankListProvider(widget.eventStudent.disciplineId),
    );
    final disciplineAsync = ref.watch(
      disciplineProvider(widget.eventStudent.disciplineId),
    );

    final profile = profileAsync.asData?.value;
    final studentName = profile != null
        ? '${profile.firstName} ${profile.lastName}'
        : 'Student';

    final discipline = disciplineAsync.asData?.value;
    final hasGradingScore = discipline?.hasGradingScore ?? false;

    final ranks = ranksAsync.asData?.value ?? <Rank>[];
    // Ranks eligible for promotion: those with a higher displayOrder than
    // the current rank (i.e. next belt up).
    final currentRankOrder = ranks
        .where((r) => r.id == widget.eventStudent.currentRankId)
        .map((r) => r.displayOrder)
        .firstOrNull;
    final promotionRanks = currentRankOrder != null
        ? ranks.where((r) => r.displayOrder > currentRankOrder).toList()
        : ranks;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Student info ────────────────────────────────────────────
          _InfoCard(studentName: studentName, event: widget.event),
          const SizedBox(height: 16),

          // ── Outcome ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Outcome',
            child: SegmentedButton<GradingOutcome>(
              segments: GradingOutcome.values
                  .map(
                    (o) => ButtonSegment<GradingOutcome>(
                      value: o,
                      label: Text(_outcomeLabel(o)),
                    ),
                  )
                  .toList(),
              selected: _outcome != null ? {_outcome!} : {},
              emptySelectionAllowed: true,
              onSelectionChanged: (Set<GradingOutcome> v) {
                if (v.isEmpty) return;
                setState(() {
                  _outcome = v.first;
                  if (_outcome != GradingOutcome.promoted) {
                    _selectedRank = null;
                  }
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.accent,
                selectedForegroundColor: AppColors.textOnAccent,
              ),
            ),
          ),

          // ── Rank achieved (promoted only) ────────────────────────────
          if (_isPromoted) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Rank Achieved',
              child: DropdownButtonFormField<Rank>(
                initialValue: _selectedRank,
                decoration: const InputDecoration(
                  labelText: 'Select new rank',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                items: promotionRanks
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (r) => setState(() => _selectedRank = r),
              ),
            ),
          ],

          // ── Score (promoted + hasGradingScore only) ──────────────────
          if (_isPromoted && hasGradingScore) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Grading Score',
              child: TextFormField(
                controller: _scoreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Score (0–100)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],

          // ── Notes ────────────────────────────────────────────────────
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Notes (optional)',
            child: TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.background,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 24),

          // ── Save ─────────────────────────────────────────────────────
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size.fromHeight(50),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnAccent,
                    ),
                  )
                : const Text('Save Result'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _outcomeLabel(GradingOutcome o) => switch (o) {
    GradingOutcome.promoted => 'Promoted',
    GradingOutcome.failed => 'Not promoted',
    GradingOutcome.absent => 'Absent',
  };
}

// ── Info card ──────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.studentName, required this.event});

  final String studentName;
  final GradingEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, color: AppColors.textOnAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    event.title ?? 'Grading Event',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
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

// ── Section card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
