import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/coach_profile_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';

class OwnerEditCoachComplianceScreen extends ConsumerStatefulWidget {
  const OwnerEditCoachComplianceScreen({
    super.key,
    required this.adminUserId,
    required this.type,
  });

  final String adminUserId;
  final CoachComplianceType type;

  @override
  ConsumerState<OwnerEditCoachComplianceScreen> createState() =>
      _OwnerEditCoachComplianceScreenState();
}

class _OwnerEditCoachComplianceScreenState
    extends ConsumerState<OwnerEditCoachComplianceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _initialised = false;

  // DBS fields
  DbsStatus _dbsStatus = DbsStatus.notSubmitted;
  late final TextEditingController _certNumber;

  // First aid fields
  late final TextEditingController _certName;
  late final TextEditingController _issuingBody;

  // Shared date fields
  DateTime? _issueDate;
  DateTime? _expiryDate;

  bool get _isDbs => widget.type == CoachComplianceType.dbs;

  @override
  void initState() {
    super.initState();
    _certNumber = TextEditingController();
    _certName = TextEditingController();
    _issuingBody = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      final profile = ref
          .read(coachProfileProvider(widget.adminUserId))
          .asData
          ?.value;
      if (profile != null) {
        if (_isDbs) {
          _dbsStatus = profile.dbs.status;
          _certNumber.text = profile.dbs.certificateNumber ?? '';
          _issueDate = profile.dbs.issueDate;
          _expiryDate = profile.dbs.expiryDate;
        } else {
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
    _certNumber.dispose();
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
    final owner = ref.read(currentAdminUserProvider);
    if (owner == null) return;

    setState(() => _saving = true);
    try {
      final useCase = ref.read(ownerUpdateCoachComplianceUseCaseProvider);
      if (_isDbs) {
        await useCase.updateDbs(
          adminUserId: widget.adminUserId,
          ownerAdminId: owner.firebaseUid,
          status: _dbsStatus,
          certificateNumber: _certNumber.text.trim().isEmpty
              ? null
              : _certNumber.text.trim(),
          issueDate: _issueDate,
          expiryDate: _expiryDate,
        );
      } else {
        await useCase.updateFirstAid(
          adminUserId: widget.adminUserId,
          ownerAdminId: owner.firebaseUid,
          certificationName: _certName.text.trim().isEmpty
              ? null
              : _certName.text.trim(),
          issuingBody: _issuingBody.text.trim().isEmpty
              ? null
              : _issuingBody.text.trim(),
          issueDate: _issueDate,
          expiryDate: _expiryDate,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compliance details updated.'),
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
    final title = _isDbs ? 'Edit DBS Details' : 'Edit First Aid Details';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_isDbs) ...[
              DropdownButtonFormField<DbsStatus>(
                // ignore: deprecated_member_use
                value: _dbsStatus,
                decoration: const InputDecoration(labelText: 'DBS status'),
                items: DbsStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(_dbsStatusLabel(s)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _dbsStatus = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _certNumber,
                decoration: const InputDecoration(
                  labelText: 'Certificate number',
                ),
                keyboardType: TextInputType.number,
              ),
            ] else ...[
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
            ],
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
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
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
