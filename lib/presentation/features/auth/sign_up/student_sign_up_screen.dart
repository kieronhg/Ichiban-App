import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import 'sign_up_provider.dart';
import 'widgets/sign_up_step_1_credentials.dart';
import 'widgets/sign_up_step_2_personal_details.dart';
import 'widgets/sign_up_step_3_emergency_contact.dart';
import 'widgets/sign_up_step_4_medical_notes.dart';
import 'widgets/sign_up_step_5_disciplines.dart';
import 'widgets/sign_up_step_6_gdpr_consent.dart';
import 'widgets/sign_up_step_7_photo_consent.dart';
import 'widgets/sign_up_step_8_membership_plan.dart';
import 'widgets/sign_up_step_9_pin_setup.dart';
import 'widgets/sign_up_step_10_review.dart';

const _stepTitles = [
  'Account details',
  'Personal details',
  'Emergency contact',
  'Medical information',
  'Disciplines',
  'Privacy policy',
  'Photo & video',
  'Membership',
  'Set your PIN',
  'Review & submit',
];

class StudentSignUpScreen extends ConsumerStatefulWidget {
  const StudentSignUpScreen({super.key});

  @override
  ConsumerState<StudentSignUpScreen> createState() =>
      _StudentSignUpScreenState();
}

class _StudentSignUpScreenState extends ConsumerState<StudentSignUpScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _tryAdvance() {
    final state = ref.read(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    final formValid = _formKey.currentState?.validate() ?? true;
    if (!formValid) return;

    if (state.currentStep == 5 && state.selectedDisciplineIds.isEmpty) {
      notifier.setError('Please select at least one discipline.');
      return;
    }
    if (state.currentStep == 6 && !state.dataProcessingConsent) {
      notifier.setError('You must agree to the privacy policy to continue.');
      return;
    }

    if (state.currentStep == SignUpState.totalSteps) {
      notifier.submitRegistration();
    } else {
      notifier.nextStep();
      setState(() => _formKey = GlobalKey<FormState>());
    }
  }

  void _goBack() {
    ref.read(signUpProvider.notifier).prevStep();
    setState(() => _formKey = GlobalKey<FormState>());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpProvider);

    return PopScope(
      canPop: state.currentStep == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && state.currentStep > 1) _goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: state.currentStep > 1
              ? BackButton(onPressed: _goBack)
              : CloseButton(onPressed: () => context.pop()),
          title: Text(_stepTitles[state.currentStep - 1]),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _ProgressBar(
                  current: state.currentStep,
                  total: SignUpState.totalSteps,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStep(state.currentStep),
                            const SizedBox(height: 16),
                            if (state.errorMessage != null)
                              _ErrorBanner(message: state.errorMessage!),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomBar(
                isLastStep: state.currentStep == SignUpState.totalSteps,
                isSubmitting: state.isSubmitting,
                onNext: _tryAdvance,
              ),
            ),
            if (state.isSubmitting)
              const ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    return switch (step) {
      1 => const SignUpStep1Credentials(),
      2 => const SignUpStep2PersonalDetails(),
      3 => const SignUpStep3EmergencyContact(),
      4 => const SignUpStep4MedicalNotes(),
      5 => const SignUpStep5Disciplines(),
      6 => const SignUpStep6GdprConsent(),
      7 => const SignUpStep7PhotoConsent(),
      8 => const SignUpStep8MembershipPlan(),
      9 => const SignUpStep9PinSetup(),
      10 => const SignUpStep10Review(),
      _ => const SizedBox.shrink(),
    };
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: current / total,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 3,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Step $current of $total',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isLastStep,
    required this.isSubmitting,
    required this.onNext,
  });

  final bool isLastStep;
  final bool isSubmitting;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: FilledButton(
        onPressed: isSubmitting ? null : onNext,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(isLastStep ? 'Create account' : 'Next'),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
        textAlign: TextAlign.center,
      ),
    );
  }
}
