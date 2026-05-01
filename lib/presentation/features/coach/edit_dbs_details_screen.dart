import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/coach_profile_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';

class EditDbsDetailsScreen extends ConsumerStatefulWidget {
  const EditDbsDetailsScreen({super.key});

  @override
  ConsumerState<EditDbsDetailsScreen> createState() =>
      _EditDbsDetailsScreenState();
}

class _EditDbsDetailsScreenState extends ConsumerState<EditDbsDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  DbsStatus _status = DbsStatus.notSubmitted;
  late final TextEditingController _certNumber;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _saving = false;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _certNumber = TextEditingController();
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
          _status = profile.dbs.status;
          _certNumber.text = profile.dbs.certificateNumber ?? '';
          _issueDate = profile.dbs.issueDate;
          _expiryDate = profile.dbs.expiryDate;
        }
      }
      _initialised = true;
    }
  }

  @override
  void dispose() {
    _certNumber.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, {required bool isExpiry}) async {
    final initial = (isExpiry ? _expiryDate : _issueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('en', 'GB'),
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
          .read(coachUpdateDbsUseCaseProvider)
          .call(
            adminUserId: admin.firebaseUid,
            status: _status,
            certificateNumber: _certNumber.text.trim().isEmpty
                ? null
                : _certNumber.text.trim(),
            issueDate: _issueDate,
            expiryDate: _expiryDate,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'DBS details updated. The owner has been notified to verify.',
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
      appBar: AppBar(title: const Text('Update DBS Details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<DbsStatus>(
              // ignore: deprecated_member_use
              value: _status,
              decoration: const InputDecoration(labelText: 'DBS status'),
              items: DbsStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(_dbsStatusLabel(s)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _certNumber,
              decoration: const InputDecoration(
                labelText: 'Certificate number',
              ),
              keyboardType: TextInputType.number,
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
                  : const Text('Save DBS Details'),
            ),
          ],
        ),
      ),
    );
  }
}

String _dbsStatusLabel(DbsStatus s) => switch (s) {
  DbsStatus.notSubmitted => 'Not Submitted',
  DbsStatus.pending => 'Pending',
  DbsStatus.clear => 'Clear',
  DbsStatus.expired => 'Expired',
};

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
