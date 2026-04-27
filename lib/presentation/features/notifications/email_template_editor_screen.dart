import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/email_template.dart';

class EmailTemplateEditorScreen extends ConsumerStatefulWidget {
  const EmailTemplateEditorScreen({super.key, required this.template});

  final EmailTemplate template;

  @override
  ConsumerState<EmailTemplateEditorScreen> createState() =>
      _EmailTemplateEditorScreenState();
}

class _EmailTemplateEditorScreenState
    extends ConsumerState<EmailTemplateEditorScreen> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _bodyCtrl;
  bool _saving = false;
  String? _error;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _subjectCtrl = TextEditingController(text: widget.template.subject);
    _bodyCtrl = TextEditingController(text: widget.template.bodyHtml);
    _subjectCtrl.addListener(_markDirty);
    _bodyCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final adminUid = ref.read(currentAdminUserProvider)?.firebaseUid;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = widget.template.copyWith(
        subject: _subjectCtrl.text.trim(),
        bodyHtml: _bodyCtrl.text,
        lastEditedByAdminId: adminUid,
        lastEditedAt: DateTime.now(),
      );
      await ref.read(saveEmailTemplateUseCaseProvider).call(updated);
      if (mounted) {
        setState(() {
          _saving = false;
          _dirty = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Template saved.')));
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.key),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: AppColors.textOnPrimary),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SubstitutionHelp(),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Body HTML',
                alignLabelWithHint: true,
              ),
              maxLines: 20,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withAlpha(77)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubstitutionHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.info),
              const SizedBox(width: 6),
              Text(
                'Substitution variables',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '{{memberName}}  {{dojoName}}  {{renewalDate}}\n'
            '{{trialEndDate}}  {{amount}}  {{gradingDate}}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }
}
