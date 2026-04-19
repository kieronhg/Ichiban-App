import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/rank.dart';

class RankFormScreen extends ConsumerStatefulWidget {
  const RankFormScreen({
    super.key,
    required this.disciplineId,

    /// Null for create mode. Pass existing [Rank] for edit mode.
    this.existingRank,

    /// The next [displayOrder] value to assign on create.
    /// Ignored when [existingRank] is provided.
    this.nextDisplayOrder = 0,
  });

  final String disciplineId;
  final Rank? existingRank;
  final int nextDisplayOrder;

  @override
  ConsumerState<RankFormScreen> createState() => _RankFormScreenState();
}

class _RankFormScreenState extends ConsumerState<RankFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _colourCtrl;
  late final TextEditingController _monCountCtrl;
  late final TextEditingController _minAttendanceCtrl;

  bool get _isEditing => widget.existingRank != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRank;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _colourCtrl = TextEditingController(
      text: r?.colourHex?.replaceAll('#', '') ?? '',
    );
    _monCountCtrl = TextEditingController(text: r?.monCount?.toString() ?? '');
    _minAttendanceCtrl = TextEditingController(
      text: r?.minAttendanceForGrading?.toString() ?? '',
    );

    // Initialise the form notifier synchronously so the first build already
    // has the correct rankType (needed for DropdownButtonFormField.initialValue).
    final notifier = ref.read(rankFormNotifierProvider.notifier);
    if (r != null) {
      notifier.load(r);
    } else {
      notifier.init(
        disciplineId: widget.disciplineId,
        nextDisplayOrder: widget.nextDisplayOrder,
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _colourCtrl.dispose();
    _monCountCtrl.dispose();
    _minAttendanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(rankFormNotifierProvider.notifier).save();
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
    final formState = ref.watch(rankFormNotifierProvider);
    final notifier = ref.read(rankFormNotifierProvider.notifier);

    // Show mon count field only when rankType == mon
    final showMonCount = formState.rankType == RankType.mon;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Rank' : 'New Rank')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Rank details ─────────────────────────────────────────────
            _FormSection(
              title: 'Rank Details',
              children: [
                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.background,
                    hintText: 'e.g. 1st Kyu, 3rd Dan, 7th Mon',
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: notifier.setName,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Rank type
                DropdownButtonFormField<RankType>(
                  initialValue: formState.rankType,
                  decoration: const InputDecoration(
                    labelText: 'Rank Type',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  items: RankType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_rankTypeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      notifier.setRankType(v);
                      // Clear monCount when switching away from 'mon'
                      if (v != RankType.mon) {
                        notifier.setMonCount(null);
                        _monCountCtrl.clear();
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Mon count (visible only for mon ranks)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: showMonCount
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Column(
                    children: [
                      TextFormField(
                        controller: _monCountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mon / Tab Count (optional)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.background,
                          hintText:
                              '0 = pass, 1 = good, 2 = excellent, 3 = exceptional',
                          helperText:
                              'Number of mons / tabs shown on the belt.',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (v) => notifier.setMonCount(
                          v.isEmpty ? null : int.tryParse(v),
                        ),
                        validator: (v) {
                          if (!showMonCount) return null;
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null || n < 0) return 'Must be 0 or more';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Belt colour ──────────────────────────────────────────────
            _FormSection(
              title: 'Belt Colour',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _colourCtrl,
                        decoration: InputDecoration(
                          labelText: 'Hex colour (optional)',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.background,
                          hintText: 'e.g. FF0000',
                          prefixText: '#',
                          helperText:
                              'Leave blank if this rank has no belt colour.',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9a-fA-F]'),
                          ),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (v) =>
                            notifier.setColourHex(v.isEmpty ? null : '#$v'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (v.length != 6) {
                            return 'Must be exactly 6 hex characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Live colour preview
                    _ColourPreview(colourHex: formState.colourHex),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Grading requirements ─────────────────────────────────────
            _FormSection(
              title: 'Grading Requirements',
              children: [
                TextFormField(
                  controller: _minAttendanceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Min sessions before grading (optional)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.background,
                    hintText: 'e.g. 12',
                    helperText:
                        'Leave blank to set no minimum. Admin can update later.',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => notifier.setMinAttendanceForGrading(
                    v.isEmpty ? null : int.tryParse(v),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = int.tryParse(v);
                    if (n == null || n < 0) return 'Must be 0 or more';
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                  : Text(_isEditing ? 'Save Changes' : 'Add Rank'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _rankTypeLabel(RankType t) => switch (t) {
    RankType.kyu => 'Kyu',
    RankType.dan => 'Dan',
    RankType.mon => 'Mon / Tab',
    RankType.ungraded => 'Ungraded',
  };
}

// ── Colour preview swatch ──────────────────────────────────────────────────

class _ColourPreview extends StatelessWidget {
  const _ColourPreview({required this.colourHex});

  final String? colourHex;

  @override
  Widget build(BuildContext context) {
    final colour = _parseHex(colourHex);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colour ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: colour == null
          ? const Icon(Icons.format_color_reset, color: AppColors.textSecondary)
          : null,
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length != 6) return null;
    final value = int.tryParse('FF$clean', radix: 16);
    return value != null ? Color(value) : null;
  }
}

// ── Form section card ──────────────────────────────────────────────────────

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
