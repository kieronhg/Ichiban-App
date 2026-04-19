import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../domain/entities/discipline.dart';

class DisciplineFormScreen extends ConsumerStatefulWidget {
  const DisciplineFormScreen({super.key, this.existingDiscipline});

  /// Null for create mode; existing [Discipline] for edit mode.
  final Discipline? existingDiscipline;

  @override
  ConsumerState<DisciplineFormScreen> createState() =>
      _DisciplineFormScreenState();
}

class _DisciplineFormScreenState extends ConsumerState<DisciplineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  bool get _isEditing => widget.existingDiscipline != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existingDiscipline;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _descCtrl = TextEditingController(text: d?.description ?? '');

    if (d != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(disciplineFormNotifierProvider.notifier).load(d);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(disciplineFormNotifierProvider.notifier).save();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(disciplineFormNotifierProvider);
    final notifier = ref.read(disciplineFormNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Discipline' : 'New Discipline'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Details ──────────────────────────────────────────────────
            _FormSection(
              title: 'Details',
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: notifier.setName,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  onChanged: (v) =>
                      notifier.setDescription(v.isEmpty ? null : v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Status (edit mode only) ───────────────────────────────────
            if (_isEditing) ...[
              _FormSection(
                title: 'Status',
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    subtitle: Text(
                      formState.isActive
                          ? 'Visible to students. New enrolments allowed.'
                          : 'Hidden from students. No new enrolments or sessions.',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: formState.isActive,
                    activeThumbColor: AppColors.accent,
                    onChanged: notifier.setActive,
                  ),
                  if (!formState.isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withAlpha(100),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Existing enrolments are preserved. '
                              'Re-activate to restore full functionality.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Error & Save ─────────────────────────────────────────────
            if (formState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  formState.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: formState.isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size.fromHeight(50),
              ),
              child: formState.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnAccent,
                      ),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Create Discipline'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Shared form section card ───────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
            ...children,
          ],
        ),
      ),
    );
  }
}
