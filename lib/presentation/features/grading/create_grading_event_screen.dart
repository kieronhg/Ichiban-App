import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/grading_providers.dart';
import '../../../domain/entities/discipline.dart';

class CreateGradingEventScreen extends ConsumerStatefulWidget {
  const CreateGradingEventScreen({super.key, this.preselectedDisciplineId});

  /// When set, the discipline dropdown is pre-selected to this discipline.
  final String? preselectedDisciplineId;

  @override
  ConsumerState<CreateGradingEventScreen> createState() =>
      _CreateGradingEventScreenState();
}

class _CreateGradingEventScreenState
    extends ConsumerState<CreateGradingEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Discipline? _selectedDiscipline;
  DateTime? _selectedDate;
  bool _isSaving = false;
  bool _didPreselect = false;

  void _tryPreselect(List<Discipline> disciplines) {
    if (_didPreselect) return;
    if (widget.preselectedDisciplineId == null) {
      _didPreselect = true;
      return;
    }
    final match = disciplines
        .where((d) => d.id == widget.preselectedDisciplineId)
        .firstOrNull;
    if (match != null) {
      _didPreselect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDiscipline = match);
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDiscipline == null) {
      _showError('Please select a discipline.');
      return;
    }
    if (_selectedDate == null) {
      _showError('Please select a date.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final adminId = ref.read(currentAdminIdProvider) ?? '';
      await ref
          .read(createGradingEventUseCaseProvider)
          .call(
            disciplineId: _selectedDiscipline!.id,
            eventDate: _selectedDate!,
            adminId: adminId,
            title: _titleCtrl.text.trim().isEmpty
                ? null
                : _titleCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (mounted) context.pop();
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
    // Coaches see only their assigned disciplines; owners see all active ones.
    final disciplinesAsync = ref.watch(accessibleActiveDisciplineListProvider);
    final disciplines = disciplinesAsync.asData?.value ?? [];
    _tryPreselect(disciplines);

    return Scaffold(
      appBar: AppBar(title: const Text('New Grading Event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Discipline ──────────────────────────────────────────────
            _Section(
              title: 'Discipline',
              child: DropdownButtonFormField<Discipline>(
                initialValue: _selectedDiscipline,
                decoration: const InputDecoration(
                  labelText: 'Select discipline',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                items: disciplines
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.name)))
                    .toList(),
                onChanged: (d) => setState(() => _selectedDiscipline = d),
                validator: (_) =>
                    _selectedDiscipline == null ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),

            // ── Date ────────────────────────────────────────────────────
            _Section(
              title: 'Event Date',
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.background,
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Tap to select'
                        : DateFormat('EEE d MMM yyyy').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Optional fields ─────────────────────────────────────────
            _Section(
              title: 'Details (optional)',
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title (e.g. Spring Grading 2025)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Save ────────────────────────────────────────────────────
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
                  : const Text('Create Event'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

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
