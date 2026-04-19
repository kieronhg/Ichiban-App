import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_providers.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(signInNotifierProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  Future<void> _forgotPassword() async {
    await ref
        .read(signInNotifierProvider.notifier)
        .sendPasswordReset(email: _emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final signInState = ref.watch(signInNotifierProvider);

    // Show banner if reset email was sent
    if (signInState.resetEmailSent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
          ),
        );
        ref.read(signInNotifierProvider.notifier).clearErrors();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo / title ─────────────────────────────────────
                  const _Logo(),
                  const SizedBox(height: 40),

                  // ── Global error ─────────────────────────────────────
                  if (signInState.errorMessage != null) ...[
                    _ErrorBanner(signInState.errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  // ── Email ────────────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.surface,
                      errorText: signInState.emailError,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    onChanged: (_) =>
                        ref.read(signInNotifierProvider.notifier).clearErrors(),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Email is required.'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Password ─────────────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.surface,
                      errorText: signInState.passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    onChanged: (_) =>
                        ref.read(signInNotifierProvider.notifier).clearErrors(),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password is required.'
                        : null,
                  ),
                  const SizedBox(height: 8),

                  // ── Forgot password ───────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: signInState.isLoading ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Sign in button ────────────────────────────────────
                  FilledButton(
                    onPressed: signInState.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: signInState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnAccent,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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

// ── Supporting widgets ─────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              '一',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Ichiban',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Admin Portal',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
