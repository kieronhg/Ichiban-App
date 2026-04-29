import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_providers.dart';
import '../../../core/theme/app_colors.dart';

class NotificationTimingsScreen extends ConsumerWidget {
  const NotificationTimingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formAsync = ref.watch(notificationTimingsFormProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Timings')),
      body: formAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (form) => _TimingsForm(form: form),
      ),
    );
  }
}

class _TimingsForm extends ConsumerStatefulWidget {
  const _TimingsForm({required this.form});

  final NotificationTimingsFormState form;

  @override
  ConsumerState<_TimingsForm> createState() => _TimingsFormState();
}

class _TimingsFormState extends ConsumerState<_TimingsForm> {
  static const _fields = [
    _TimingField(
      key: 'renewalReminderDays',
      label: 'Renewal reminder',
      description: 'Days before renewal date to send reminder',
    ),
    _TimingField(
      key: 'lapseReminderPreDueDays',
      label: 'Lapse reminder — pre due (working days)',
      description: 'Working days before renewal to send pre-lapse email',
    ),
    _TimingField(
      key: 'lapseReminderPostDueDays',
      label: 'Lapse reminder — post due (working days)',
      description: 'Working days after renewal date if still lapsed',
    ),
    _TimingField(
      key: 'trialExpiryReminderDays',
      label: 'Trial expiry reminder',
      description: 'Days before trial end to send expiry reminder',
    ),
    _TimingField(
      key: 'dbsExpiryAlertDays',
      label: 'DBS expiry alert',
      description: 'Days before DBS expiry to alert coach and owners',
    ),
    _TimingField(
      key: 'firstAidExpiryAlertDays',
      label: 'First aid expiry alert',
      description: 'Days before first aid expiry to alert coach and owners',
    ),
    _TimingField(
      key: 'licenceReminderDays',
      label: 'Licence reminder',
      description: 'Reserved for future licence renewal feature',
    ),
  ];

  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'renewalReminderDays': TextEditingController(
        text: widget.form.renewalReminderDays.toString(),
      ),
      'lapseReminderPreDueDays': TextEditingController(
        text: widget.form.lapseReminderPreDueDays.toString(),
      ),
      'lapseReminderPostDueDays': TextEditingController(
        text: widget.form.lapseReminderPostDueDays.toString(),
      ),
      'trialExpiryReminderDays': TextEditingController(
        text: widget.form.trialExpiryReminderDays.toString(),
      ),
      'dbsExpiryAlertDays': TextEditingController(
        text: widget.form.dbsExpiryAlertDays.toString(),
      ),
      'firstAidExpiryAlertDays': TextEditingController(
        text: widget.form.firstAidExpiryAlertDays.toString(),
      ),
      'licenceReminderDays': TextEditingController(
        text: widget.form.licenceReminderDays.toString(),
      ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate(String? text) {
    final v = int.tryParse(text ?? '');
    if (v == null) return 'Enter a whole number';
    if (v < 1) return 'Minimum 1';
    if (v > 365) return 'Maximum 365';
    return null;
  }

  bool get _allValid =>
      _controllers.values.every((c) => _validate(c.text) == null);

  Future<void> _save() async {
    final notifier = ref.read(notificationTimingsFormProvider.notifier);
    for (final entry in _controllers.entries) {
      final value = int.tryParse(entry.value.text);
      if (value != null) notifier.setField(entry.key, value);
    }

    try {
      await notifier.save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification timings saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(notificationTimingsFormProvider);
    final isSaving = formAsync.asData?.value.isSaving ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'All values must be whole numbers between 1 and 365.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          for (final field in _fields) ...[
            _TimingFieldWidget(
              field: field,
              controller: _controllers[field.key]!,
              validate: _validate,
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          // Rebuild button whenever controllers change via setState
          StatefulBuilder(
            builder: (ctx, setInner) => FilledButton(
              onPressed: (!_allValid || isSaving)
                  ? null
                  : () {
                      setInner(() {});
                      _save();
                    },
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
          ),
        ],
      ),
    );
  }
}

class _TimingField {
  const _TimingField({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;
}

class _TimingFieldWidget extends StatefulWidget {
  const _TimingFieldWidget({
    required this.field,
    required this.controller,
    required this.validate,
  });

  final _TimingField field;
  final TextEditingController controller;
  final String? Function(String?) validate;

  @override
  State<_TimingFieldWidget> createState() => _TimingFieldWidgetState();
}

class _TimingFieldWidgetState extends State<_TimingFieldWidget> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: (v) => setState(() => _error = widget.validate(v)),
      decoration: InputDecoration(
        labelText: widget.field.label,
        helperText: widget.field.description,
        helperMaxLines: 2,
        suffixText: 'days',
        errorText: _error,
      ),
      keyboardType: TextInputType.number,
    );
  }
}
