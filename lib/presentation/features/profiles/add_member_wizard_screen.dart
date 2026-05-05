import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_settings_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';

// ── Step indices ─────────────────────────────────────────────────────────────

const _kStepType = 0;
const _kStepPersonal = 1;
const _kStepEmergency = 2;
const _kStepMedical = 3;
const _kStepParent = 4;
const _kStepPrefs = 5;
const _kStepGdpr = 6;
const _kStepPin = 7;
const _kStepReview = 8;

const _kStepLabels = [
  'Type',
  'Personal',
  'Emergency',
  'Medical',
  'Parent',
  'Prefs',
  'GDPR',
  'PIN',
  'Review',
];

// ── Wizard screen ─────────────────────────────────────────────────────────────

class AddMemberWizardScreen extends ConsumerStatefulWidget {
  const AddMemberWizardScreen({super.key});

  @override
  ConsumerState<AddMemberWizardScreen> createState() =>
      _AddMemberWizardScreenState();
}

class _AddMemberWizardScreenState extends ConsumerState<AddMemberWizardScreen> {
  int _currentStep = _kStepType;

  // Per-step form keys for inline validation
  final _typeKey = GlobalKey<FormState>();
  final _personalKey = GlobalKey<FormState>();
  final _emergencyKey = GlobalKey<FormState>();
  final _medicalKey = GlobalKey<FormState>();
  final _parentKey = GlobalKey<FormState>();
  final _prefsKey = GlobalKey<FormState>();
  final _gdprKey = GlobalKey<FormState>();
  final _pinKey = GlobalKey<FormState>();

  // Text controllers
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
  late final TextEditingController _parentId;
  late final TextEditingController _secondParentId;
  late final TextEditingController _payingParentId;
  late final TextEditingController _pin;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _addressLine1 = TextEditingController();
    _addressLine2 = TextEditingController();
    _city = TextEditingController();
    _county = TextEditingController();
    _postcode = TextEditingController();
    _country = TextEditingController(text: 'United Kingdom');
    _emergencyName = TextEditingController();
    _emergencyRelationship = TextEditingController();
    _emergencyPhone = TextEditingController();
    _medicalNotes = TextEditingController();
    _parentId = TextEditingController();
    _secondParentId = TextEditingController();
    _payingParentId = TextEditingController();
    _pin = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _phone,
      _email,
      _addressLine1,
      _addressLine2,
      _city,
      _county,
      _postcode,
      _country,
      _emergencyName,
      _emergencyRelationship,
      _emergencyPhone,
      _medicalNotes,
      _parentId,
      _secondParentId,
      _payingParentId,
      _pin,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isJunior => ref
      .read(profileFormNotifierProvider)
      .profileTypes
      .contains(ProfileType.juniorStudent);

  GlobalKey<FormState>? _keyForStep(int step) => switch (step) {
    _kStepType => _typeKey,
    _kStepPersonal => _personalKey,
    _kStepEmergency => _emergencyKey,
    _kStepMedical => _medicalKey,
    _kStepParent => _parentKey,
    _kStepPrefs => _prefsKey,
    _kStepGdpr => _gdprKey,
    _kStepPin => _pinKey,
    _ => null,
  };

  // Returns the ordered list of step indices based on junior status
  List<int> get _steps {
    if (_isJunior) {
      return [0, 1, 2, 3, 4, 5, 6, 7, 8];
    }
    return [0, 1, 2, 3, 5, 6, 7, 8]; // skip Parent step
  }

  int get _stepPosition => _steps.indexOf(_currentStep);
  bool get _isFirstStep => _stepPosition == 0;
  bool get _isLastStep => _stepPosition == _steps.length - 1;

  void _goBack() {
    if (_isFirstStep) return;
    setState(() => _currentStep = _steps[_stepPosition - 1]);
  }

  void _goForward() {
    final key = _keyForStep(_currentStep);
    if (key != null && !(key.currentState?.validate() ?? true)) return;

    if (_isLastStep) {
      _save();
    } else {
      setState(() => _currentStep = _steps[_stepPosition + 1]);
    }
  }

  void _jumpToStep(int step) {
    if (_steps.contains(step) && _steps.indexOf(step) <= _stepPosition) {
      setState(() => _currentStep = step);
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(profileFormNotifierProvider.notifier);
    try {
      final id = await notifier.save();
      // Set PIN if provided
      final pinValue = _pin.text.trim();
      if (pinValue.length == 4 && mounted) {
        await ref
            .read(setPinUseCaseProvider)
            .call(profileId: id, pin: pinValue);
      }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add member'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Stepper
          Container(
            color: AppColors.paper1,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: _WizardStepper(
              currentStep: _currentStep,
              completedSteps: _steps.sublist(0, _stepPosition).toSet(),
              onTap: _jumpToStep,
            ),
          ),
          const Divider(height: 1),

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _buildStepContent(formState),
                ),
              ),
            ),
          ),

          // Footer
          _WizardFooter(
            isFirstStep: _isFirstStep,
            isLastStep: _isLastStep,
            isSaving: formState.isSaving,
            onCancel: () => context.pop(),
            onBack: _isFirstStep ? null : _goBack,
            onContinue: _goForward,
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(ProfileFormState formState) {
    final notifier = ref.read(profileFormNotifierProvider.notifier);

    return switch (_currentStep) {
      _kStepType => _StepType(
        formKey: _typeKey,
        formState: formState,
        notifier: notifier,
      ),
      _kStepPersonal => _StepPersonal(
        formKey: _personalKey,
        formState: formState,
        notifier: notifier,
        firstName: _firstName,
        lastName: _lastName,
        phone: _phone,
        email: _email,
        addressLine1: _addressLine1,
        addressLine2: _addressLine2,
        city: _city,
        county: _county,
        postcode: _postcode,
        country: _country,
      ),
      _kStepEmergency => _StepEmergency(
        formKey: _emergencyKey,
        notifier: notifier,
        name: _emergencyName,
        relationship: _emergencyRelationship,
        phone: _emergencyPhone,
      ),
      _kStepMedical => _StepMedical(
        formKey: _medicalKey,
        formState: formState,
        notifier: notifier,
        medicalNotes: _medicalNotes,
      ),
      _kStepParent => _StepParent(
        formKey: _parentKey,
        notifier: notifier,
        parentId: _parentId,
        secondParentId: _secondParentId,
        payingParentId: _payingParentId,
      ),
      _kStepPrefs => _StepPrefs(
        formKey: _prefsKey,
        formState: formState,
        notifier: notifier,
      ),
      _kStepGdpr => _StepGdpr(
        formKey: _gdprKey,
        formState: formState,
        notifier: notifier,
      ),
      _kStepPin => _StepPin(formKey: _pinKey, pin: _pin),
      _kStepReview => _StepReview(
        formState: formState,
        pin: _pin.text,
        isJunior: _isJunior,
        onEdit: _jumpToStep,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ── Wizard stepper ────────────────────────────────────────────────────────────

class _WizardStepper extends StatelessWidget {
  const _WizardStepper({
    required this.currentStep,
    required this.completedSteps,
    required this.onTap,
  });

  final int currentStep;
  final Set<int> completedSteps;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(9 * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            return Container(width: 24, height: 1, color: AppColors.hairline);
          }
          final step = i ~/ 2;
          final isCurrent = step == currentStep;
          final isDone = completedSteps.contains(step);

          final circleColor = isCurrent
              ? AppColors.crimson
              : isDone
              ? AppColors.ink1
              : Colors.transparent;
          final circleBorderColor = isCurrent
              ? AppColors.crimson
              : isDone
              ? AppColors.ink1
              : AppColors.hairline;
          final labelColor = isCurrent
              ? AppColors.ink1
              : isDone
              ? AppColors.ink2
              : AppColors.ink4;

          return GestureDetector(
            onTap: () => onTap(step),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: circleBorderColor),
                  ),
                  child: Center(
                    child: isDone && !isCurrent
                        ? Icon(Icons.check, size: 12, color: AppColors.paper0)
                        : Text(
                            '${step + 1}',
                            style: TextStyle(
                              fontFamily: 'IBM Plex Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isCurrent ? AppColors.paper0 : labelColor,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _kStepLabels[step],
                  style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 10,
                    letterSpacing: 0.1 * 10,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Wizard footer ─────────────────────────────────────────────────────────────

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({
    required this.isFirstStep,
    required this.isLastStep,
    required this.isSaving,
    required this.onCancel,
    required this.onBack,
    required this.onContinue,
  });

  final bool isFirstStep;
  final bool isLastStep;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback? onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.paper1,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: AppColors.ink3),
            child: const Text('Cancel'),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink1,
                  side: const BorderSide(color: AppColors.hairline),
                  minimumSize: const Size(0, 40),
                ),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isSaving ? null : onContinue,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.paper0,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isLastStep ? 'Create profile' : 'Continue'),
                          const SizedBox(width: 6),
                          Icon(
                            isLastStep ? Icons.check : Icons.arrow_forward,
                            size: 16,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared step card ──────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.heading,
    required this.lede,
    required this.child,
  });

  final String heading;
  final String lede;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.paper0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: GoogleFonts.notoSerifJp(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: AppColors.ink1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lede,
              style: const TextStyle(fontSize: 14, color: AppColors.ink2),
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Type ───────────────────────────────────────────────────────────────

class _StepType extends StatelessWidget {
  const _StepType({
    required this.formKey,
    required this.formState,
    required this.notifier,
  });

  final GlobalKey<FormState> formKey;
  final ProfileFormState formState;
  final ProfileFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: _StepCard(
        heading: 'Who are we adding?',
        lede:
            'Pick one or more. Junior adds a parent-linking step automatically.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoleGrid(
              selected: formState.profileTypes,
              onChanged: notifier.setProfileTypes,
            ),
            if (formState.profileTypes.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'At least one type is required.',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            // Inline FormField for validation
            FormField<List<ProfileType>>(
              initialValue: formState.profileTypes,
              validator: (v) => (v == null || v.isEmpty) ? 'required' : null,
              builder: (_) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleGrid extends StatelessWidget {
  const _RoleGrid({required this.selected, required this.onChanged});

  final List<ProfileType> selected;
  final void Function(List<ProfileType>) onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _RoleCard(
          type: ProfileType.juniorStudent,
          label: 'Junior',
          title: 'Junior student',
          description: 'Under-18. Requires a linked parent or guardian.',
          labelColor: AppColors.tea,
          labelBg: AppColors.teaWash,
          selected: selected.contains(ProfileType.juniorStudent),
          onTap: () => _toggle(ProfileType.juniorStudent),
        ),
        _RoleCard(
          type: ProfileType.adultStudent,
          label: 'Adult',
          title: 'Adult student',
          description: '18+. Can manage their own membership.',
          labelColor: AppColors.indigo,
          labelBg: AppColors.indigoWash,
          selected: selected.contains(ProfileType.adultStudent),
          onTap: () => _toggle(ProfileType.adultStudent),
        ),
        _RoleCard(
          type: ProfileType.parentGuardian,
          label: 'Parent',
          title: 'Parent / guardian',
          description: 'Linked to one or more junior students.',
          labelColor: AppColors.ochre,
          labelBg: AppColors.ochreWash,
          selected: selected.contains(ProfileType.parentGuardian),
          onTap: () => _toggle(ProfileType.parentGuardian),
        ),
        _RoleCard(
          type: ProfileType.coach,
          label: 'Coach',
          title: 'Coach / instructor',
          description: 'Admin access to the app. Assigned to disciplines.',
          labelColor: AppColors.crimson,
          labelBg: AppColors.crimsonWash,
          selected: selected.contains(ProfileType.coach),
          onTap: () => _toggle(ProfileType.coach),
        ),
      ],
    );
  }

  void _toggle(ProfileType type) {
    final updated = List<ProfileType>.from(selected);
    if (updated.contains(type)) {
      updated.remove(type);
    } else {
      updated.add(type);
    }
    onChanged(updated);
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.type,
    required this.label,
    required this.title,
    required this.description,
    required this.labelColor,
    required this.labelBg,
    required this.selected,
    required this.onTap,
  });

  final ProfileType type;
  final String label;
  final String title;
  final String description;
  final Color labelColor;
  final Color labelBg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.all(selected ? 19 : 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.crimsonWash : AppColors.paper0,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.crimson : AppColors.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: labelBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 10,
                      letterSpacing: 0.1 * 10,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.notoSerifJp(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink1,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            // Checkmark indicator (top-right)
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.crimson : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.crimson : AppColors.ink4,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 12, color: AppColors.paper0)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Personal ──────────────────────────────────────────────────────────

class _StepPersonal extends StatelessWidget {
  const _StepPersonal({
    required this.formKey,
    required this.formState,
    required this.notifier,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.county,
    required this.postcode,
    required this.country,
  });

  final GlobalKey<FormState> formKey;
  final ProfileFormState formState;
  final ProfileFormNotifier notifier;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController addressLine1;
  final TextEditingController addressLine2;
  final TextEditingController city;
  final TextEditingController county;
  final TextEditingController postcode;
  final TextEditingController country;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _StepCard(
        heading: 'Personal details',
        lede: 'Name, date of birth, address and contact.',
        child: Column(
          children: [
            _Row2(
              left: _WizField(
                controller: firstName,
                label: 'First name',
                required: true,
                onChanged: notifier.setFirstName,
              ),
              right: _WizField(
                controller: lastName,
                label: 'Last name',
                required: true,
                onChanged: notifier.setLastName,
              ),
            ),
            const SizedBox(height: 14),
            _DateField(
              label: 'Date of birth',
              value: formState.dateOfBirth,
              onChanged: notifier.setDateOfBirth,
            ),
            const SizedBox(height: 14),
            _GenderDropdown(
              value: formState.gender,
              onChanged: notifier.setGender,
            ),
            const SizedBox(height: 14),
            _WizField(
              controller: addressLine1,
              label: 'Address line 1',
              required: true,
              onChanged: notifier.setAddressLine1,
            ),
            const SizedBox(height: 14),
            _WizField(
              controller: addressLine2,
              label: 'Address line 2 (optional)',
              onChanged: (v) => notifier.setAddressLine2(v.isEmpty ? null : v),
            ),
            const SizedBox(height: 14),
            _Row2(
              left: _WizField(
                controller: city,
                label: 'City',
                required: true,
                onChanged: notifier.setCity,
              ),
              right: _WizField(
                controller: county,
                label: 'County',
                required: true,
                onChanged: notifier.setCounty,
              ),
            ),
            const SizedBox(height: 14),
            _Row2(
              left: _WizField(
                controller: postcode,
                label: 'Postcode',
                required: true,
                textCapitalization: TextCapitalization.characters,
                onChanged: notifier.setPostcode,
              ),
              right: _WizField(
                controller: country,
                label: 'Country',
                required: true,
                onChanged: notifier.setCountry,
              ),
            ),
            const SizedBox(height: 14),
            _WizField(
              controller: phone,
              label: 'Phone',
              required: true,
              keyboardType: TextInputType.phone,
              onChanged: notifier.setPhone,
            ),
            const SizedBox(height: 14),
            _WizField(
              controller: email,
              label: 'Email',
              required: true,
              keyboardType: TextInputType.emailAddress,
              onChanged: notifier.setEmail,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 3: Emergency ─────────────────────────────────────────────────────────

class _StepEmergency extends StatelessWidget {
  const _StepEmergency({
    required this.formKey,
    required this.notifier,
    required this.name,
    required this.relationship,
    required this.phone,
  });

  final GlobalKey<FormState> formKey;
  final ProfileFormNotifier notifier;
  final TextEditingController name;
  final TextEditingController relationship;
  final TextEditingController phone;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _StepCard(
        heading: 'Emergency contact',
        lede: 'Someone we can contact if needed during training.',
        child: Column(
          children: [
            _WizField(
              controller: name,
              label: 'Full name',
              required: true,
              onChanged: notifier.setEmergencyContactName,
            ),
            const SizedBox(height: 14),
            _Row2(
              left: _WizField(
                controller: relationship,
                label: 'Relationship',
                required: true,
                onChanged: notifier.setEmergencyContactRelationship,
              ),
              right: _WizField(
                controller: phone,
                label: 'Phone',
                required: true,
                keyboardType: TextInputType.phone,
                onChanged: notifier.setEmergencyContactPhone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 4: Medical ───────────────────────────────────────────────────────────

class _StepMedical extends StatelessWidget {
  const _StepMedical({
    required this.formKey,
    required this.formState,
    required this.notifier,
    required this.medicalNotes,
  });

  final GlobalKey<FormState> formKey;
  final ProfileFormState formState;
  final ProfileFormNotifier notifier;
  final TextEditingController medicalNotes;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: _StepCard(
        heading: 'Medical notes',
        lede:
            'Allergies, conditions, and any information coaches need to know.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WizField(
              controller: medicalNotes,
              label: 'Allergies / medical notes (optional)',
              maxLines: 4,
              onChanged: (v) =>
                  notifier.setAllergiesOrMedicalNotes(v.isEmpty ? null : v),
            ),
            const SizedBox(height: 20),
            const Text(
              'Photo & video consent',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Permission to use images and video for dojo promotion.',
              style: TextStyle(fontSize: 13, color: AppColors.ink3),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ToggleSwitch(
                  value: formState.photoVideoConsent,
                  onChanged: notifier.setPhotoVideoConsent,
                ),
                const SizedBox(width: 12),
                Text(
                  formState.photoVideoConsent ? 'Given' : 'Not given',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 5: Parent ────────────────────────────────────────────────────────────

class _StepParent extends StatelessWidget {
  const _StepParent({
    required this.formKey,
    required this.notifier,
    required this.parentId,
    required this.secondParentId,
    required this.payingParentId,
  });

  final GlobalKey<FormState> formKey;
  final ProfileFormNotifier notifier;
  final TextEditingController parentId;
  final TextEditingController secondParentId;
  final TextEditingController payingParentId;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _StepCard(
        heading: 'Parent or guardian',
        lede:
            'Link this junior to their parent\'s profile. If the parent is new, create their profile first.',
        child: Column(
          children: [
            _WizField(
              controller: parentId,
              label: 'Parent / guardian profile ID',
              onChanged: (v) =>
                  notifier.setParentProfileId(v.isEmpty ? null : v),
            ),
            const SizedBox(height: 14),
            _WizField(
              controller: secondParentId,
              label: 'Second parent / guardian profile ID (optional)',
              onChanged: (v) =>
                  notifier.setSecondParentProfileId(v.isEmpty ? null : v),
            ),
            const SizedBox(height: 14),
            _WizField(
              controller: payingParentId,
              label: 'Paying parent profile ID (optional)',
              onChanged: (v) =>
                  notifier.setPayingParentId(v.isEmpty ? null : v),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 6: Prefs ─────────────────────────────────────────────────────────────

class _StepPrefs extends StatelessWidget {
  const _StepPrefs({
    required this.formKey,
    required this.formState,
    required this.notifier,
  });

  final GlobalKey<FormState> formKey;
  final ProfileFormState formState;
  final ProfileFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final prefs = formState.communicationPreferences;
    return _StepCard(
      heading: 'Communication preferences',
      lede: 'Choose which notifications this member should receive.',
      child: Column(
        children: [
          _PrefRow(
            label: 'Billing reminders',
            description: 'Renewal and overdue payment reminders.',
            value: prefs.billingAndPaymentReminders,
            onChanged: (v) => notifier.setCommunicationPreferences(
              prefs.copyWith(billingAndPaymentReminders: v),
            ),
          ),
          const _PrefDivider(),
          _PrefRow(
            label: 'Grading notifications',
            description: 'Eligibility selections and promotion results.',
            value: prefs.gradingNotifications,
            onChanged: (v) => notifier.setCommunicationPreferences(
              prefs.copyWith(gradingNotifications: v),
            ),
          ),
          const _PrefDivider(),
          _PrefRow(
            label: 'Trial expiry reminders',
            description: 'Upcoming trial end notifications.',
            value: prefs.trialExpiryReminders,
            onChanged: (v) => notifier.setCommunicationPreferences(
              prefs.copyWith(trialExpiryReminders: v),
            ),
          ),
          const _PrefDivider(),
          _PrefRow(
            label: 'General announcements',
            description: 'News and messages from the dojo.',
            value: prefs.generalDojoAnnouncements,
            onChanged: (v) => notifier.setCommunicationPreferences(
              prefs.copyWith(generalDojoAnnouncements: v),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _ToggleSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PrefDivider extends StatelessWidget {
  const _PrefDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.hairline);
  }
}

// ── Step 7: GDPR ──────────────────────────────────────────────────────────────

class _StepGdpr extends ConsumerWidget {
  const _StepGdpr({
    required this.formKey,
    required this.formState,
    required this.notifier,
  });

  final GlobalKey<FormState> formKey;
  final ProfileFormState formState;
  final ProfileFormNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyVersionAsync = ref.watch(privacyPolicyVersionProvider);
    final currentVersion = policyVersionAsync.value ?? '…';

    return Form(
      key: formKey,
      child: _StepCard(
        heading: 'Data processing consent',
        lede:
            'The member must give explicit consent before their profile can be created.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm that consent has been obtained before continuing.',
              style: const TextStyle(fontSize: 13, color: AppColors.ink3),
            ),
            const SizedBox(height: 16),
            FormField<bool>(
              initialValue: formState.dataProcessingConsent,
              validator: (v) => (v == null || !v)
                  ? 'Consent is required to create a profile.'
                  : null,
              builder: (state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: formState.dataProcessingConsent,
                        activeColor: AppColors.crimson,
                        onChanged: (v) {
                          final checked = v ?? false;
                          notifier.setDataProcessingConsent(checked);
                          notifier.setDataProcessingConsentVersion(
                            checked ? policyVersionAsync.value : null,
                          );
                          state.didChange(checked);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Member has given data processing consent',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Privacy policy version $currentVersion will be recorded.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (state.hasError && state.errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        state.errorText!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 8: PIN ───────────────────────────────────────────────────────────────

class _StepPin extends StatelessWidget {
  const _StepPin({required this.formKey, required this.pin});

  final GlobalKey<FormState> formKey;
  final TextEditingController pin;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: _StepCard(
        heading: 'Set a PIN',
        lede:
            'The member uses this 4-digit PIN to check in on the tablet. You can skip this and set it later.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: TextFormField(
                controller: pin,
                decoration: const InputDecoration(
                  labelText: '4-digit PIN (optional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.paper1,
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // optional
                  if (v.length != 4) return 'PIN must be exactly 4 digits';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.indigoWash,
                borderRadius: BorderRadius.circular(4),
                border: const Border(
                  left: BorderSide(color: AppColors.indigo, width: 2),
                ),
              ),
              child: const Text(
                'The PIN is hashed before storage — it cannot be viewed, only reset.',
                style: TextStyle(fontSize: 13, color: AppColors.ink2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 9: Review ────────────────────────────────────────────────────────────

class _StepReview extends StatelessWidget {
  const _StepReview({
    required this.formState,
    required this.pin,
    required this.isJunior,
    required this.onEdit,
  });

  final ProfileFormState formState;
  final String pin;
  final bool isJunior;
  final void Function(int) onEdit;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');

    final personalSummary = [
      if (formState.firstName.isNotEmpty || formState.lastName.isNotEmpty)
        '${formState.firstName} ${formState.lastName}'.trim(),
      if (formState.dateOfBirth != null)
        dateFormat.format(formState.dateOfBirth!),
      if (formState.addressLine1.isNotEmpty)
        '${formState.addressLine1}, ${formState.city} ${formState.postcode}',
    ].join(' · ');

    final emergencySummary = [
      if (formState.emergencyContactName.isNotEmpty)
        formState.emergencyContactName,
      if (formState.emergencyContactRelationship.isNotEmpty)
        formState.emergencyContactRelationship,
      if (formState.emergencyContactPhone.isNotEmpty)
        formState.emergencyContactPhone,
    ].join(' · ');

    final medicalSummary = formState.allergiesOrMedicalNotes?.isNotEmpty == true
        ? formState.allergiesOrMedicalNotes!
        : 'No medical notes';

    final typeLabels = formState.profileTypes.map(_typeLabel).join(', ');

    return _StepCard(
      heading: 'Review before creating',
      lede:
          'Check each section. Use Edit to jump back. Creating saves all steps as a single transaction.',
      child: Column(
        children: [
          _ReviewRow(
            eyebrow: 'Type',
            content: typeLabels.isEmpty ? '—' : typeLabels,
            onEdit: () => onEdit(_kStepType),
          ),
          _ReviewRow(
            eyebrow: 'Personal',
            content: personalSummary.isEmpty ? '—' : personalSummary,
            onEdit: () => onEdit(_kStepPersonal),
          ),
          _ReviewRow(
            eyebrow: 'Emergency contact',
            content: emergencySummary.isEmpty ? '—' : emergencySummary,
            onEdit: () => onEdit(_kStepEmergency),
          ),
          _ReviewRow(
            eyebrow: 'Medical',
            content: medicalSummary,
            onEdit: () => onEdit(_kStepMedical),
          ),
          if (isJunior) ...[
            _ReviewRow(
              eyebrow: 'Parent linked',
              content: formState.parentProfileId?.isNotEmpty == true
                  ? formState.parentProfileId!
                  : '—',
              onEdit: () => onEdit(_kStepParent),
            ),
          ],
          _ReviewRow(
            eyebrow: 'Preferences',
            content: _prefsSummary(formState),
            onEdit: () => onEdit(_kStepPrefs),
          ),
          _ReviewRow(
            eyebrow: 'Consent',
            content: formState.dataProcessingConsent
                ? 'GDPR v${formState.dataProcessingConsentVersion ?? '?'} given · '
                      'Photo & video ${formState.photoVideoConsent ? 'given' : 'not given'}'
                : 'Consent not recorded',
            onEdit: () => onEdit(_kStepGdpr),
          ),
          _ReviewRow(
            eyebrow: 'PIN',
            content: pin.length == 4
                ? '4-digit PIN set · • • • •'
                : 'No PIN — can be set later',
            onEdit: () => onEdit(_kStepPin),
            isLast: true,
          ),
        ],
      ),
    );
  }

  static String _prefsSummary(ProfileFormState s) {
    final on = <String>[];
    final p = s.communicationPreferences;
    if (p.billingAndPaymentReminders) on.add('billing');
    if (p.gradingNotifications) on.add('grading');
    if (p.trialExpiryReminders) on.add('trial');
    if (p.generalDojoAnnouncements) on.add('announcements');
    return on.isEmpty ? 'All off' : on.join(', ');
  }

  static String _typeLabel(ProfileType t) => switch (t) {
    ProfileType.adultStudent => 'Adult student',
    ProfileType.juniorStudent => 'Junior student',
    ProfileType.coach => 'Coach',
    ProfileType.parentGuardian => 'Parent / guardian',
  };
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.eyebrow,
    required this.content,
    required this.onEdit,
    this.isLast = false,
  });

  final String eyebrow;
  final String content;
  final VoidCallback onEdit;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 10,
                    letterSpacing: 0.14 * 10,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(content, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.crimson,
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('Edit →'),
          ),
        ],
      ),
    );
  }
}

// ── Shared field helpers ──────────────────────────────────────────────────────

class _WizField extends StatelessWidget {
  const _WizField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.words,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.paper1,
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
}

class _Row2 extends StatelessWidget {
  const _Row2({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
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
      builder: (state) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.paper1,
          errorText: state.errorText,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              locale: const Locale('en', 'GB'),
              initialDate:
                  value ??
                  DateTime.now().subtract(const Duration(days: 365 * 10)),
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
              fontSize: 14,
              color: value != null ? AppColors.ink1 : AppColors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.value, required this.onChanged});

  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Gender (optional)',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.paper1,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Prefer not to say')),
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Non-binary', child: Text('Non-binary')),
      ],
      onChanged: onChanged,
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.value, required this.onChanged});

  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.crimson : AppColors.paper3,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? AppColors.crimsonInk : AppColors.hairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisAlignment: value
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.paper0,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A1C1B18),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
