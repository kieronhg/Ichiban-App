import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/student_auth_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _unrecognisedError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(isAccountUnrecognisedProvider, (prev, next) async {
        if (next) {
          await ref.read(authRepositoryProvider).signOut();
          if (mounted) {
            setState(() {
              _unrecognisedError =
                  'Account not recognised. Please contact your dojo.';
            });
          }
        }
      });
    });
  }

  Future<void> _submit() async {
    setState(() {
      _obscurePassword = true;
      _unrecognisedError = null;
    });
    await ref
        .read(signInNotifierProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  void _clearErrors() =>
      ref.read(signInNotifierProvider.notifier).clearErrors();

  void _showForgotPassword() {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _ForgotPasswordDialog(initialEmail: _emailController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInNotifierProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _WideLogin(
            emailController: _emailController,
            passwordController: _passwordController,
            obscurePassword: _obscurePassword,
            onObscureToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onSubmit: _submit,
            onForgotPassword: _showForgotPassword,
            onChanged: _clearErrors,
            state: state,
            unrecognisedError: _unrecognisedError,
          );
        }
        return _NarrowLogin(
          emailController: _emailController,
          passwordController: _passwordController,
          obscurePassword: _obscurePassword,
          onObscureToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onSubmit: _submit,
          onForgotPassword: _showForgotPassword,
          onChanged: _clearErrors,
          state: state,
          unrecognisedError: _unrecognisedError,
        );
      },
    );
  }
}

// ── Wide (two-panel) layout ───────────────────────────────────────────────────

class _WideLogin extends StatelessWidget {
  const _WideLogin({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onObscureToggle,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onChanged,
    required this.state,
    this.unrecognisedError,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onObscureToggle;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onChanged;
  final SignInState state;
  final String? unrecognisedError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandSurface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 680),
          child: Row(
            children: [
              const Expanded(flex: 10, child: _BrandPanel()),
              Expanded(
                flex: 11,
                child: _FormPanel(
                  emailController: emailController,
                  passwordController: passwordController,
                  obscurePassword: obscurePassword,
                  onObscureToggle: onObscureToggle,
                  onSubmit: onSubmit,
                  onForgotPassword: onForgotPassword,
                  onChanged: onChanged,
                  state: state,
                  unrecognisedError: unrecognisedError,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Brand panel ───────────────────────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brandSurface,
      child: Stack(
        children: [
          // Watermark
          Positioned(
            right: -36,
            bottom: -72,
            child: Text(
              '壱',
              style: TextStyle(
                fontSize: 280,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(10),
                height: 0.8,
              ),
            ),
          ),

          // Seal stamp (top-right, rotated)
          Positioned(
            top: 48,
            right: 40,
            child: Transform.rotate(
              angle: -0.07,
              child: _SealStamp(character: '番'),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: mark + name
                _Mark(size: 44, fontSize: 22),
                const SizedBox(height: 18),
                const Text(
                  'Ichiban',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'MEANWOOD DOJO · EST. 2009',
                  style: TextStyle(
                    color: Colors.white.withAlpha(140),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(),

                // Bottom: tagline + disciplines
                const Text(
                  'A working tool\nfor a working dojo.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'KARATE · JUDO · JUJITSU · AIKIDO · KENDO',
                  style: TextStyle(
                    color: Colors.white.withAlpha(115),
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form panel (wide) ─────────────────────────────────────────────────────────

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onObscureToggle,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onChanged,
    required this.state,
    this.unrecognisedError,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onObscureToggle;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onChanged;
  final SignInState state;
  final String? unrecognisedError;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.warmPaper,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          _Eyebrow(label: 'Sign in to continue'),
          const SizedBox(height: 18),

          // Heading
          const Text(
            'Welcome back.',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              height: 1.05,
              color: AppColors.brandSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in with your registered email address.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),

          // Unrecognised account banner
          if (unrecognisedError != null) ...[
            _ErrorBanner(
              title: 'Account not recognised',
              body: unrecognisedError!,
            ),
            const SizedBox(height: 20),
          ],

          // Error banner
          if (state.errorMessage != null) ...[
            _ErrorBanner(
              title: 'We couldn\'t sign you in',
              body: state.errorMessage!,
            ),
            const SizedBox(height: 20),
          ],

          // Fields
          _LabeledField(
            label: 'Email',
            controller: emailController,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            enabled: !state.isLoading,
          ),
          const SizedBox(height: 20),
          _LabeledField(
            label: 'Password',
            controller: passwordController,
            icon: Icons.lock_outline,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            onChanged: (_) => onChanged(),
            hasError: state.passwordError != null,
            enabled: !state.isLoading,
            suffix: TextButton(
              onPressed: state.isLoading ? null : onObscureToggle,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: const TextStyle(fontSize: 10, letterSpacing: 1.2),
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
              child: Text(obscurePassword ? 'SHOW' : 'HIDE'),
            ),
          ),
          if (state.passwordError != null) ...[
            const SizedBox(height: 6),
            Text(
              state.passwordError!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],

          // Actions
          const SizedBox(height: 28),
          _SignInButton(onPressed: onSubmit, isLoading: state.isLoading),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: state.isLoading
                      ? null
                      : () => context.push(RouteNames.studentSignUp),
                  child: const Text(
                    'Create an account',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.crimson,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.crimson,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: state.isLoading ? null : onForgotPassword,
                child: const Text(
                  'Forgot password',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.crimson,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.crimson,
                  ),
                ),
              ),
            ],
          ),

          // Footer
          const Spacer(),
          Divider(color: AppColors.hairline.withAlpha(180), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Privacy policy v3.1',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                'v1.0.0 · Build 1',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Narrow (mobile) layout ────────────────────────────────────────────────────

class _NarrowLogin extends StatelessWidget {
  const _NarrowLogin({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onObscureToggle,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onChanged,
    required this.state,
    this.unrecognisedError,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onObscureToggle;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onChanged;
  final SignInState state;
  final String? unrecognisedError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmPaper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  _Mark(size: 36, fontSize: 18),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome back.',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      height: 1.05,
                      color: AppColors.brandSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to continue.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (unrecognisedError != null) ...[
                    _ErrorBanner(
                      title: 'Account not recognised',
                      body: unrecognisedError!,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (state.errorMessage != null) ...[
                    _ErrorBanner(
                      title: 'We couldn\'t sign you in',
                      body: state.errorMessage!,
                    ),
                    const SizedBox(height: 20),
                  ],

                  _LabeledField(
                    label: 'Email',
                    controller: emailController,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => onChanged(),
                    enabled: !state.isLoading,
                  ),
                  const SizedBox(height: 20),
                  _LabeledField(
                    label: 'Password',
                    controller: passwordController,
                    icon: Icons.lock_outline,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmit(),
                    onChanged: (_) => onChanged(),
                    hasError: state.passwordError != null,
                    enabled: !state.isLoading,
                    suffix: TextButton(
                      onPressed: state.isLoading ? null : onObscureToggle,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        textStyle: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(obscurePassword ? 'SHOW' : 'HIDE'),
                    ),
                  ),
                  if (state.passwordError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      state.passwordError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _SignInButton(
                    onPressed: onSubmit,
                    isLoading: state.isLoading,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: state.isLoading
                              ? null
                              : () => context.push(RouteNames.studentSignUp),
                          child: const Text(
                            'Create an account',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.crimson,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.crimson,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: state.isLoading ? null : onForgotPassword,
                        child: const Text(
                          'Forgot password',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.crimson,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.crimson,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'V1.0.0 · BUILD 1',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Forgot password dialog ────────────────────────────────────────────────────

class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    // Clear any stale resetEmailSent from a prior session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(signInNotifierProvider);
      if (state.resetEmailSent) {
        ref.read(signInNotifierProvider.notifier).clearErrors();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInNotifierProvider);

    if (state.resetEmailSent) {
      return _dialogShell(
        child: _ForgotSuccess(
          onBack: () {
            ref.read(signInNotifierProvider.notifier).clearErrors();
            Navigator.of(context).pop();
          },
        ),
      );
    }

    return _dialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESET PASSWORD',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.crimson,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll send you a link.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: AppColors.brandSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the email you signed up with. The reset link expires in one hour.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _LabeledField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _sendReset(state),
            enabled: !state.isLoading,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: state.isLoading ? null : () => _sendReset(state),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandSurface,
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send reset link'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendReset(SignInState state) {
    if (state.isLoading) return;
    ref
        .read(signInNotifierProvider.notifier)
        .sendPasswordReset(email: _emailController.text);
  }

  Widget _dialogShell({required Widget child}) {
    return Dialog(
      backgroundColor: AppColors.warmPaper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(padding: const EdgeInsets.all(32), child: child),
      ),
    );
  }
}

class _ForgotSuccess extends StatelessWidget {
  const _ForgotSuccess({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: AppColors.success, size: 22),
        ),
        const SizedBox(height: 18),
        const Text(
          'Check your inbox.',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: AppColors.brandSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'If we have an account for that email, a reset link is on its way. The link expires in one hour.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onBack,
            child: const Text('Back to sign in'),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Mark extends StatelessWidget {
  const _Mark({required this.size, required this.fontSize});

  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white.withAlpha(64), width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Text(
          '壱',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SealStamp extends StatelessWidget {
  const _SealStamp({required this.character});

  final String character;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.crimson, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        children: [
          // Inner border
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.crimson.withAlpha(140),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              character,
              style: const TextStyle(
                color: AppColors.crimson,
                fontSize: 26,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: AppColors.hairline)),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.suffix,
    this.hasError = false,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final bool hasError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fillColor = hasError
        ? const Color(0xFF9A2E20).withAlpha(10)
        : AppColors.warmField;
    final borderColor = hasError ? AppColors.error : AppColors.hairline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  onChanged: onChanged,
                  enabled: enabled,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.brandSurface,
                  ),
                ),
              ),
              if (suffix != null) ...[suffix!, const SizedBox(width: 14)],
            ],
          ),
        ),
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.onPressed, required this.isLoading});

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandSurface,
          foregroundColor: AppColors.warmPaper,
          disabledBackgroundColor: AppColors.brandSurface.withAlpha(160),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Signing you in…',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign in',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, size: 14),
                ],
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF9A2E20).withAlpha(15),
        border: const Border(
          left: BorderSide(color: AppColors.error, width: 2),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠', style: TextStyle(fontSize: 14, height: 1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
