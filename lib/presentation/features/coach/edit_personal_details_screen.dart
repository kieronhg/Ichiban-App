import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/coach_profile_providers.dart';
import '../../../core/theme/app_colors.dart';

class EditPersonalDetailsScreen extends ConsumerStatefulWidget {
  const EditPersonalDetailsScreen({super.key});

  @override
  ConsumerState<EditPersonalDetailsScreen> createState() =>
      _EditPersonalDetailsScreenState();
}

class _EditPersonalDetailsScreenState
    extends ConsumerState<EditPersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _qualifications;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final admin = ref.read(currentAdminUserProvider);
    _firstName = TextEditingController(text: admin?.firstName ?? '');
    _lastName = TextEditingController(text: admin?.lastName ?? '');

    final profile = ref
        .read(coachProfileProvider(admin?.firebaseUid ?? ''))
        .asData
        ?.value;
    _qualifications = TextEditingController(
      text: profile?.qualificationsNotes ?? '',
    );
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _qualifications.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = ref.read(currentAdminUserProvider);
    if (admin == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(updateCoachPersonalDetailsUseCaseProvider)
          .call(
            adminUserId: admin.firebaseUid,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            qualificationsNotes: _qualifications.text.trim().isEmpty
                ? null
                : _qualifications.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Details updated.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst(RegExp(r'^.*?: ?'), '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Personal Details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'First name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Last name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qualifications,
              decoration: const InputDecoration(
                labelText: 'Qualifications & certifications',
                hintText: 'e.g. 3rd Dan Black Belt, BJJA qualified instructor',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
