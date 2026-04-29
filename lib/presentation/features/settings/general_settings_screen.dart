import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_providers.dart';
import '../../../core/theme/app_colors.dart';

class GeneralSettingsScreen extends ConsumerWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formAsync = ref.watch(generalSettingsFormProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('General Settings')),
      body: formAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (form) => _GeneralSettingsForm(form: form),
      ),
    );
  }
}

class _GeneralSettingsForm extends ConsumerStatefulWidget {
  const _GeneralSettingsForm({required this.form});

  final GeneralSettingsFormState form;

  @override
  ConsumerState<_GeneralSettingsForm> createState() =>
      _GeneralSettingsFormState();
}

class _GeneralSettingsFormState extends ConsumerState<_GeneralSettingsForm> {
  late final TextEditingController _dojoNameCtrl;
  late final TextEditingController _dojoEmailCtrl;
  late final TextEditingController _privacyVersionCtrl;

  @override
  void initState() {
    super.initState();
    _dojoNameCtrl = TextEditingController(text: widget.form.dojoName);
    _dojoEmailCtrl = TextEditingController(text: widget.form.dojoEmail);
    _privacyVersionCtrl = TextEditingController(
      text: widget.form.privacyPolicyVersion,
    );
  }

  @override
  void dispose() {
    _dojoNameCtrl.dispose();
    _dojoEmailCtrl.dispose();
    _privacyVersionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(generalSettingsFormProvider.notifier);
    notifier.setDojoName(_dojoNameCtrl.text.trim());
    notifier.setDojoEmail(_dojoEmailCtrl.text.trim());
    notifier.setPrivacyPolicyVersion(_privacyVersionCtrl.text.trim());

    final versionChanged =
        _privacyVersionCtrl.text.trim() !=
        ref
            .read(generalSettingsFormProvider)
            .asData
            ?.value
            .privacyPolicyVersion;

    if (versionChanged) {
      final confirmed = await _showVersionChangeDialog();
      if (!confirmed) return;
    }

    try {
      await notifier.save();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref
                      .read(generalSettingsFormProvider)
                      .asData
                      ?.value
                      .errorMessage ??
                  'Failed to save settings.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _showVersionChangeDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Privacy Policy Updated'),
            content: const Text(
              'Changing the privacy policy version will flag all active '
              'members as requiring re-consent. You will be prompted to '
              'record re-consent the next time you visit each member\'s profile.\n\n'
              'Proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(generalSettingsFormProvider);
    final isSaving = formAsync.asData?.value.isSaving ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _dojoNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Dojo Name',
              hintText: 'e.g. Ichiban Judo',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dojoEmailCtrl,
            decoration: const InputDecoration(
              labelText: 'Dojo Email Address',
              hintText: 'Used as the Gmail sender address',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Privacy Policy',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _privacyVersionCtrl,
            decoration: const InputDecoration(
              labelText: 'Privacy Policy Version',
              hintText: 'e.g. 1.0',
              helperText:
                  'Changing this version will require all active members to re-consent.',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
