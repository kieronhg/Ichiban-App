import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_settings_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/profile.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key, this.existingProfile});

  /// Null for create mode; existing [Profile] for edit mode.
  final Profile? existingProfile;

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers — all initialised in initState
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _city;
  late final TextEditingController _county;
  late final TextEditingController _postcode;
  late final TextEditingController _country;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyRelationship;
  late final TextEditingController _emergencyPhone;
  late final TextEditingController _medicalNotes;
  late final TextEditingController _notes;
  late final TextEditingController _parentId;
  late final TextEditingController _secondParentId;
  late final TextEditingController _payingParentId;

  bool get _isEditing => widget.existingProfile != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _firstName = TextEditingController(text: p?.firstName ?? '');
    _lastName = TextEditingController(text: p?.lastName ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _addressLine1 = TextEditingController(text: p?.addressLine1 ?? '');
    _addressLine2 = TextEditingController(text: p?.addressLine2 ?? '');
    _city = TextEditingController(text: p?.city ?? '');
    _county = TextEditingController(text: p?.county ?? '');
    _postcode = TextEditingController(text: p?.postcode ?? '');
    _country = TextEditingController(text: p?.country ?? 'United Kingdom');
    _emergencyName =
        TextEditingController(text: p?.emergencyContactName ?? '');
    _emergencyRelationship =
        TextEditingController(text: p?.emergencyContactRelationship ?? '');
    _emergencyPhone =
        TextEditingController(text: p?.emergencyContactPhone ?? '');
    _medicalNotes =
        TextEditingController(text: p?.allergiesOrMedicalNotes ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
    _parentId = TextEditingController(text: p?.parentProfileId ?? '');
    _secondParentId =
        TextEditingController(text: p?.secondParentProfileId ?? '');
    _payingParentId = TextEditingController(text: p?.payingParentId ?? '');

    // Load existing profile into the notifier after first frame
    if (p != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileFormNotifierProvider.notifier).load(p);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstName, _lastName, _phone, _email,
      _addressLine1, _addressLine2, _city, _county, _postcode, _country,
      _emergencyName, _emergencyRelationship, _emergencyPhone,
      _medicalNotes, _notes, _parentId, _secondParentId, _payingParentId,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(profileFormNotifierProvider.notifier).save();
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
    final formState = ref.watch(profileFormNotifierProvider);
    final notifier = ref.read(profileFormNotifierProvider.notifier);
    final isJunior =
        formState.profileTypes.contains(ProfileType.juniorStudent);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'New Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Personal ────────────────────────────────────────────────
            _FormSection(
              title: 'Personal',
              children: [
                _row(
                  left: _field(
                    controller: _firstName,
                    label: 'First name',
                    required: true,
                    onChanged: notifier.setFirstName,
                  ),
                  right: _field(
                    controller: _lastName,
                    label: 'Last name',
                    required: true,
                    onChanged: notifier.setLastName,
                  ),
                ),
                const SizedBox(height: 12),
                _DatePickerField(
                  label: 'Date of birth',
                  value: formState.dateOfBirth,
                  onChanged: notifier.setDateOfBirth,
                ),
                const SizedBox(height: 12),
                _DropdownField<String?>(
                  label: 'Gender (optional)',
                  value: formState.gender,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Prefer not to say')),
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(
                        value: 'Non-binary', child: Text('Non-binary')),
                  ],
                  onChanged: notifier.setGender,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Profile types ────────────────────────────────────────────
            _FormSection(
              title: 'Profile Types',
              children: [
                const Text(
                  'Select one or more roles for this person.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ProfileType.values.map((t) {
                    final selected =
                        formState.profileTypes.contains(t);
                    return FilterChip(
                      label: Text(_typeLabel(t)),
                      selected: selected,
                      onSelected: (v) {
                        final updated =
                            List<ProfileType>.from(formState.profileTypes);
                        v ? updated.add(t) : updated.remove(t);
                        notifier.setProfileTypes(updated);
                      },
                      selectedColor: AppColors.accent,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.textOnAccent
                            : AppColors.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                if (formState.profileTypes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'At least one type is required.',
                      style: TextStyle(
                          color: AppColors.error, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Address ──────────────────────────────────────────────────
            _FormSection(
              title: 'Address',
              children: [
                _field(
                  controller: _addressLine1,
                  label: 'Address line 1',
                  required: true,
                  onChanged: notifier.setAddressLine1,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _addressLine2,
                  label: 'Address line 2 (optional)',
                  onChanged: (v) =>
                      notifier.setAddressLine2(v.isEmpty ? null : v),
                ),
                const SizedBox(height: 12),
                _row(
                  left: _field(
                    controller: _city,
                    label: 'City',
                    required: true,
                    onChanged: notifier.setCity,
                  ),
                  right: _field(
                    controller: _county,
                    label: 'County',
                    required: true,
                    onChanged: notifier.setCounty,
                  ),
                ),
                const SizedBox(height: 12),
                _row(
                  left: _field(
                    controller: _postcode,
                    label: 'Postcode',
                    required: true,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: notifier.setPostcode,
                  ),
                  right: _field(
                    controller: _country,
                    label: 'Country',
                    required: true,
                    onChanged: notifier.setCountry,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Contact ──────────────────────────────────────────────────
            _FormSection(
              title: 'Contact',
              children: [
                _field(
                  controller: _phone,
                  label: 'Phone',
                  required: true,
                  keyboardType: TextInputType.phone,
                  onChanged: notifier.setPhone,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _email,
                  label: 'Email',
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: notifier.setEmail,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Emergency contact ────────────────────────────────────────
            _FormSection(
              title: 'Emergency Contact',
              children: [
                _field(
                  controller: _emergencyName,
                  label: 'Name',
                  required: true,
                  onChanged: notifier.setEmergencyContactName,
                ),
                const SizedBox(height: 12),
                _row(
                  left: _field(
                    controller: _emergencyRelationship,
                    label: 'Relationship',
                    required: true,
                    onChanged: notifier.setEmergencyContactRelationship,
                  ),
                  right: _field(
                    controller: _emergencyPhone,
                    label: 'Phone',
                    required: true,
                    keyboardType: TextInputType.phone,
                    onChanged: notifier.setEmergencyContactPhone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Medical & consent ────────────────────────────────────────
            _FormSection(
              title: 'Medical & Consent',
              children: [
                _field(
                  controller: _medicalNotes,
                  label: 'Allergies / medical notes (optional)',
                  maxLines: 3,
                  onChanged: (v) => notifier
                      .setAllergiesOrMedicalNotes(v.isEmpty ? null : v),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Photo / video consent'),
                  subtitle: const Text(
                    'Permission to use images and video for dojo promotion.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: formState.photoVideoConsent,
                  activeThumbColor: AppColors.accent,
                  onChanged: notifier.setPhotoVideoConsent,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Family links (juniors only) ──────────────────────────────
            if (isJunior) ...[
              _FormSection(
                title: 'Family Links',
                children: [
                  _field(
                    controller: _parentId,
                    label: 'Parent / Guardian profile ID',
                    onChanged: (v) =>
                        notifier.setParentProfileId(v.isEmpty ? null : v),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _secondParentId,
                    label: 'Second Parent / Guardian profile ID (optional)',
                    onChanged: (v) => notifier
                        .setSecondParentProfileId(v.isEmpty ? null : v),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _payingParentId,
                    label: 'Paying Parent profile ID (optional)',
                    onChanged: (v) =>
                        notifier.setPayingParentId(v.isEmpty ? null : v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Data processing consent ──────────────────────────────────
            _GdprConsentSection(
              isEditing: _isEditing,
              formState: formState,
              notifier: notifier,
            ),
            const SizedBox(height: 16),

            // ── Communication preferences ────────────────────────────────
            _FormSection(
              title: 'Communication Preferences',
              children: [
                ...NotificationChannel.values.map((channel) {
                  final selected = formState.communicationPreferences
                      .contains(channel);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_channelLabel(channel)),
                    value: selected,
                    activeColor: AppColors.accent,
                    onChanged: (v) {
                      final updated = List<NotificationChannel>.from(
                          formState.communicationPreferences);
                      (v ?? false)
                          ? updated.add(channel)
                          : updated.remove(channel);
                      notifier.setCommunicationPreferences(updated);
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // ── Admin notes ──────────────────────────────────────────────
            _FormSection(
              title: 'Admin Notes',
              children: [
                _field(
                  controller: _notes,
                  label: 'Internal notes (not visible to member)',
                  maxLines: 4,
                  onChanged: (v) =>
                      notifier.setNotes(v.isEmpty ? null : v),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Save ─────────────────────────────────────────────────────
            if (formState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  formState.errorMessage!,
                  style:
                      const TextStyle(color: AppColors.error, fontSize: 13),
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
                          color: AppColors.textOnAccent),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Create Profile'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _typeLabel(ProfileType t) => switch (t) {
        ProfileType.adultStudent => 'Adult Student',
        ProfileType.juniorStudent => 'Junior Student',
        ProfileType.coach => 'Coach',
        ProfileType.parentGuardian => 'Parent / Guardian',
      };

  String _channelLabel(NotificationChannel c) => switch (c) {
        NotificationChannel.push => 'Push notifications',
        NotificationChannel.email => 'Email',
      };
}

// ── Form helpers ───────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

Widget _field({
  required TextEditingController controller,
  required String label,
  bool required = false,
  TextInputType keyboardType = TextInputType.text,
  TextCapitalization textCapitalization = TextCapitalization.words,
  int maxLines = 1,
  required void Function(String) onChanged,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: AppColors.background,
    ),
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    maxLines: maxLines,
    onChanged: onChanged,
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
        : null,
  );
}

Widget _row({required Widget left, required Widget right}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 12),
      Expanded(child: right),
    ],
  );
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final void Function(DateTime) onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) => v == null ? 'Required' : null,
      builder: (state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.background,
            errorText: state.errorText,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ??
                    DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                state.didChange(picked);
                onChanged(picked);
              }
            },
            child: Text(
              value != null
                  ? DateFormat('d MMMM yyyy').format(value!)
                  : 'Select date',
              style: TextStyle(
                color: value != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.background,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

// ── GDPR consent section ───────────────────────────────────────────────────

class _GdprConsentSection extends ConsumerWidget {
  const _GdprConsentSection({
    required this.isEditing,
    required this.formState,
    required this.notifier,
  });

  final bool isEditing;
  final ProfileFormState formState;
  final ProfileFormNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyVersionAsync = ref.watch(privacyPolicyVersionProvider);
    final currentVersion =
        policyVersionAsync.value ?? '…';

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Processing Consent',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 10),

            // Edit mode — consent already given: show read-only status
            if (isEditing && formState.dataProcessingConsent) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.success.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined,
                        size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consent given'
                        '${formState.dataProcessingConsentVersion != null ? ' — policy v${formState.dataProcessingConsentVersion}' : ''}.',
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To withdraw consent use the Right to Erasure process, '
                'not this form.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ]

            // Create mode (or edit with no consent yet): show checkbox
            else ...[
              Text(
                'The member must give explicit consent before their '
                'profile can be created. Confirm below that consent has '
                'been obtained.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: formState.dataProcessingConsent,
                activeColor: AppColors.accent,
                title: const Text(
                  'Member has given data processing consent',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Privacy policy version $currentVersion will be recorded.',
                  style: const TextStyle(fontSize: 12),
                ),
                onChanged: (v) {
                  final checked = v ?? false;
                  notifier.setDataProcessingConsent(checked);
                  // Stamp the current policy version when consent is given;
                  // clear it if the checkbox is unchecked
                  notifier.setDataProcessingConsentVersion(
                      checked ? policyVersionAsync.value : null);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (!formState.dataProcessingConsent)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    'Consent is required to create a profile.',
                    style: TextStyle(
                        color: AppColors.error, fontSize: 12),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
