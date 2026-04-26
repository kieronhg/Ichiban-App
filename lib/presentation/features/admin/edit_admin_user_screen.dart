import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_user.dart';

class EditAdminUserScreen extends ConsumerStatefulWidget {
  const EditAdminUserScreen({super.key, required this.adminUser});

  final AdminUser adminUser;

  @override
  ConsumerState<EditAdminUserScreen> createState() =>
      _EditAdminUserScreenState();
}

class _EditAdminUserScreenState extends ConsumerState<EditAdminUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;

  bool _isBusy = false;
  String? _errorMessage;
  late Set<String> _selectedDisciplineIds;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.adminUser.firstName);
    _lastNameCtrl = TextEditingController(text: widget.adminUser.lastName);
    _emailCtrl = TextEditingController(text: widget.adminUser.email);
    _selectedDisciplineIds = Set<String>.from(
      widget.adminUser.assignedDisciplineIds,
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.adminUser.isCoach && _selectedDisciplineIds.isEmpty) {
      setState(
        () => _errorMessage =
            'A coach must be assigned to at least one discipline.',
      );
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(updateAdminUserUseCaseProvider)
          .call(
            uid: widget.adminUser.firebaseUid,
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            assignedDisciplineIds: widget.adminUser.isCoach
                ? _selectedDisciplineIds.toList()
                : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isBusy = false;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^.*?: ?'), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final disciplinesAsync = ref.watch(activeDisciplineListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.adminUser.firstName}'),
        actions: [
          TextButton(
            onPressed: _isBusy ? null : _save,
            child: _isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Name row ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Email ────────────────────────────────────────────────────
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            // ── Disciplines (coaches only) ────────────────────────────────
            if (widget.adminUser.isCoach) ...[
              const SizedBox(height: 28),
              Text(
                'Assigned Disciplines',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'The coach will only see classes for these disciplines.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              disciplinesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (disciplines) => Column(
                  children: disciplines
                      .map(
                        (d) => CheckboxListTile(
                          value: _selectedDisciplineIds.contains(d.id),
                          onChanged: (checked) => setState(() {
                            if (checked == true) {
                              _selectedDisciplineIds.add(d.id);
                            } else {
                              _selectedDisciplineIds.remove(d.id);
                            }
                          }),
                          title: Text(d.name),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
