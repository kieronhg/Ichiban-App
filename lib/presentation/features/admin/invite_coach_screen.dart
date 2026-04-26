import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/discipline_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/enums.dart';

class InviteCoachScreen extends ConsumerStatefulWidget {
  const InviteCoachScreen({super.key});

  @override
  ConsumerState<InviteCoachScreen> createState() => _InviteCoachScreenState();
}

class _InviteCoachScreenState extends ConsumerState<InviteCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isBusy = false;
  String? _errorMessage;
  final Set<String> _selectedDisciplineIds = {};

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Discipline> disciplines) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDisciplineIds.isEmpty) {
      setState(() => _errorMessage = 'Please assign at least one discipline.');
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final currentAdmin = ref.read(currentAdminUserProvider);
      if (currentAdmin == null) throw StateError('Not signed in');

      // Create Firebase Auth account without displacing the current admin.
      final uid = await ref
          .read(authRepositoryProvider)
          .createUserWithoutSignIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );

      // Write the adminUsers Firestore document.
      await ref
          .read(createAdminUserUseCaseProvider)
          .call(
            firebaseUid: uid,
            email: _emailCtrl.text.trim(),
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            role: AdminRole.coach,
            assignedDisciplineIds: _selectedDisciplineIds.toList(),
            createdByAdminId: currentAdmin.firebaseUid,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()} '
              'has been added as a coach.',
            ),
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
      appBar: AppBar(title: const Text('Invite Coach')),
      body: disciplinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (disciplines) => _buildForm(context, disciplines),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Discipline> disciplines) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Name row ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _firstNameCtrl,
                  label: 'First Name',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _lastNameCtrl,
                  label: 'Last Name',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Email ──────────────────────────────────────────────────────
          _Field(
            controller: _emailCtrl,
            label: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Temporary password ─────────────────────────────────────────
          _Field(
            controller: _passwordCtrl,
            label: 'Temporary Password',
            obscureText: _obscurePassword,
            helperText: 'Share this with the coach so they can sign in.',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 8) return 'Minimum 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // ── Discipline assignment ─────────────────────────────────────
          Text(
            'Assign Disciplines',
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

          if (disciplines.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withAlpha(77)),
              ),
              child: const Text(
                'No active disciplines found. '
                'Add disciplines before inviting coaches.',
                style: TextStyle(color: AppColors.warning),
              ),
            )
          else
            ...disciplines.map(
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
            ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: _errorMessage!),
          ],

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: (_isBusy || disciplines.isEmpty)
                ? null
                : () => _submit(disciplines),
            child: _isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnAccent,
                    ),
                  )
                : const Text('Create Coach Account'),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.helperText,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? helperText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        helperText: helperText,
        helperMaxLines: 2,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
