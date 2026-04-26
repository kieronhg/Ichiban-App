import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/coach_profile_providers.dart';
import '../../../core/theme/app_colors.dart';

class EditFirstAidDetailsScreen extends ConsumerStatefulWidget {
  const EditFirstAidDetailsScreen({super.key});

  @override
  ConsumerState<EditFirstAidDetailsScreen> createState() =>
      _EditFirstAidDetailsScreenState();
}

class _EditFirstAidDetailsScreenState
    extends ConsumerState<EditFirstAidDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _certName;
  late final TextEditingController _issuingBody;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _saving = false;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _certName = TextEditingController();
    _issuingBody = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      final admin = ref.read(currentAdminUserProvider);
      if (admin != null) {
        final profile = ref
            .read(coachProfileProvider(admin.firebaseUid))
            .asData
            ?.value;
        if (profile != null) {
          _certName.text = profile.firstAid.certificationName ?? '';
          _issuingBody.text = profile.firstAid.issuingBody ?? '';
          _issueDate = profile.firstAid.issueDate;
          _expiryDate = profile.firstAid.expiryDate;
        }
      }
      _initialised = true;
    }
  }

  @override
  void dispose() {
    _certName.dispose();
    _issuingBody.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, {required bool isExpiry}) async {
    final initial = (isExpiry ? _expiryDate : _issueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _issueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = ref.read(currentAdminUserProvider);
    if (admin == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(coachUpdateFirstAidUseCaseProvider)
          .call(
            adminUserId: admin.firebaseUid,
            certificationName: _certName.text.trim().isEmpty
                ? null
                : _certName.text.trim(),
            issuingBody: _issuingBody.text.trim().isEmpty
                ? null
                : _issuingBody.text.trim(),
            issueDate: _issueDate,
            expiryDate: _expiryDate,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'First aid details updated. The owner has been notified to verify.',
            ),
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
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Update First Aid Details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _certName,
              decoration: const InputDecoration(
                labelText: 'Certification name',
                hintText: 'e.g. Emergency First Aid at Work',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _issuingBody,
              decoration: const InputDecoration(
                labelText: 'Issuing body',
                hintText: 'e.g. St John Ambulance',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _DateTile(
              label: 'Issue date',
              date: _issueDate,
              fmt: fmt,
              onTap: () => _pickDate(context, isExpiry: false),
            ),
            const SizedBox(height: 8),
            _DateTile(
              label: 'Expiry date',
              date: _expiryDate,
              fmt: fmt,
              onTap: () => _pickDate(context, isExpiry: true),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withAlpha(60)),
              ),
              child: const Text(
                'Your details will be saved immediately. The dojo owner will '
                'be notified to verify your submission.',
                style: TextStyle(fontSize: 13, color: AppColors.warning),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save First Aid Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.fmt,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final DateFormat fmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        date != null ? fmt.format(date!) : 'Not set',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: date != null ? null : AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.calendar_today_outlined, size: 20),
      onTap: onTap,
    );
  }
}
