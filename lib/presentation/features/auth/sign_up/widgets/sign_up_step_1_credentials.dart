import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sign_up_provider.dart';

class SignUpStep1Credentials extends ConsumerStatefulWidget {
  const SignUpStep1Credentials({super.key});

  @override
  ConsumerState<SignUpStep1Credentials> createState() =>
      _SignUpStep1CredentialsState();
}

class _SignUpStep1CredentialsState
    extends ConsumerState<SignUpStep1Credentials> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(signUpProvider);
    _emailController = TextEditingController(text: s.email);
    _passwordController = TextEditingController(text: s.password);
    _confirmController = TextEditingController(text: s.confirmPassword);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(signUpProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          onChanged: notifier.setEmail,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            if (!emailRe.hasMatch(v.trim())) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          onChanged: notifier.setPassword,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Password must be at least 8 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmController,
          decoration: InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          onChanged: notifier.setConfirmPassword,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != ref.read(signUpProvider).password) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }
}
