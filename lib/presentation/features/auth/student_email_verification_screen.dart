import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/student_auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class StudentEmailVerificationScreen extends ConsumerStatefulWidget {
  const StudentEmailVerificationScreen({super.key});

  @override
  ConsumerState<StudentEmailVerificationScreen> createState() =>
      _StudentEmailVerificationScreenState();
}

class _StudentEmailVerificationScreenState
    extends ConsumerState<StudentEmailVerificationScreen> {
  bool _resendInProgress = false;
  bool _checkInProgress = false;
  String? _statusMessage;
  bool _statusIsError = false;

  String get _email =>
      ref.read(currentStudentProfileProvider)?.email ?? 'your email address';

  Future<void> _resend() async {
    setState(() {
      _resendInProgress = true;
      _statusMessage = null;
    });
    try {
      await ref.read(studentAuthProvider.notifier).resendVerificationEmail();
      if (mounted) {
        setState(() {
          _statusMessage = 'Verification email sent.';
          _statusIsError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Could not resend email. Please try again.';
          _statusIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _resendInProgress = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _checkInProgress = true;
      _statusMessage = null;
    });
    try {
      await ref.read(studentAuthProvider.notifier).refreshEmailVerification();
      final isVerified = ref.read(studentAuthProvider).isEmailVerified;
      if (!isVerified && mounted) {
        setState(() {
          _statusMessage =
              'Email not yet verified. Please check your inbox and click the link.';
          _statusIsError = true;
        });
      }
      // If verified, the router redirect fires automatically.
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Could not check verification status. Please try again.';
          _statusIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _checkInProgress = false);
    }
  }

  Future<void> _signOut() async {
    ref.read(studentAuthProvider.notifier).signOut();
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: AppColors.accent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Check your inbox',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to\n$_email\n\nClick the link in the email to activate your account.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (_statusIsError
                                    ? AppColors.error
                                    : AppColors.success)
                                .withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _statusIsError
                              ? AppColors.error
                              : AppColors.success,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _statusIsError
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  FilledButton(
                    onPressed: _checkInProgress ? null : _checkVerification,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _checkInProgress
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("I've verified my email"),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _resendInProgress ? null : _resend,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _resendInProgress
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend verification email'),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'Sign out',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
