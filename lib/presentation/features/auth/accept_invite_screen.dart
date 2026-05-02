import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/use_cases/profile/set_pin_use_case.dart';

enum _InviteStep { loading, password, pin, activating }

class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  _InviteStep _step = _InviteStep.loading;

  String _profileEmail = '';
  String _profileFirstName = '';

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _pinControllers = List.generate(4, (_) => TextEditingController());
  final _pinFocusNodes = List.generate(4, (_) => FocusNode());

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvite();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInvite() async {
    final profileRepo = ref.read(profileRepositoryProvider);
    final profile = await profileRepo.getById(widget.profileId);

    if (!mounted) return;

    if (profile == null) {
      context.go(RouteNames.inviteExpired);
      return;
    }

    final now = DateTime.now();
    final isExpired =
        profile.inviteStatus == InviteStatus.expired ||
        (profile.inviteExpiresAt != null &&
            profile.inviteExpiresAt!.isBefore(now));
    if (isExpired) {
      context.go('${RouteNames.inviteExpired}?profileId=${widget.profileId}');
      return;
    }

    setState(() {
      _profileEmail = profile.email;
      _profileFirstName = profile.firstName;
      _step = _InviteStep.password;
    });
  }

  String get _pinValue => _pinControllers.map((c) => c.text).join();

  Future<void> _submitPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _step = _InviteStep.pin;
      _errorMessage = null;
    });
  }

  Future<void> _submitPin() async {
    if (_pinValue.length != 4) {
      setState(() => _errorMessage = 'Please enter a 4-digit PIN.');
      return;
    }

    setState(() {
      _step = _InviteStep.activating;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final uid = await authRepo.createUser(
        email: _profileEmail,
        password: _passwordController.text,
      );

      final profileRepo = ref.read(profileRepositoryProvider);

      await profileRepo.update(
        (await profileRepo.getById(widget.profileId))!.copyWith(
          uid: uid,
          inviteStatus: InviteStatus.accepted,
          emailVerified: true,
        ),
      );

      await SetPinUseCase(
        profileRepo,
      ).call(profileId: widget.profileId, pin: _pinValue);

      if (!mounted) return;
      context.go(RouteNames.studentPortalHome);
    } catch (e) {
      setState(() {
        _step = _InviteStep.password;
        _errorMessage = 'Activation failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set Up Your Account'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: switch (_step) {
          _InviteStep.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          _InviteStep.password => _PasswordStep(
            theme: theme,
            firstName: _profileFirstName,
            passwordController: _passwordController,
            confirmController: _confirmController,
            formKey: _passwordFormKey,
            obscurePassword: _obscurePassword,
            obscureConfirm: _obscureConfirm,
            errorMessage: _errorMessage,
            onTogglePassword: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onToggleConfirm: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            onSubmit: _submitPassword,
          ),
          _InviteStep.pin => _PinStep(
            theme: theme,
            controllers: _pinControllers,
            focusNodes: _pinFocusNodes,
            errorMessage: _errorMessage,
            onSubmit: _submitPin,
          ),
          _InviteStep.activating => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Activating your account…'),
              ],
            ),
          ),
        },
      ),
    );
  }
}

// ── Password step ───────────────────────────────────────────────────────────

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    required this.theme,
    required this.firstName,
    required this.passwordController,
    required this.confirmController,
    required this.formKey,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  final ThemeData theme;
  final String firstName;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final GlobalKey<FormState> formKey;
  final bool obscurePassword;
  final bool obscureConfirm;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, $firstName!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a password to secure your account.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmController,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onToggleConfirm,
                ),
              ),
              validator: (v) {
                if (v != passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(onPressed: onSubmit, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}

// ── PIN step ────────────────────────────────────────────────────────────────

class _PinStep extends StatelessWidget {
  const _PinStep({
    required this.theme,
    required this.controllers,
    required this.focusNodes,
    required this.errorMessage,
    required this.onSubmit,
  });

  final ThemeData theme;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set your PIN',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You'll use this 4-digit PIN to check in at the dojo.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              return Container(
                width: 56,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: TextFormField(
                  controller: controllers[i],
                  focusNode: focusNodes[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                  style: theme.textTheme.titleLarge,
                  onChanged: (v) {
                    if (v.length == 1 && i < 3) {
                      focusNodes[i + 1].requestFocus();
                    }
                    if (v.isEmpty && i > 0) {
                      focusNodes[i - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 40),
          FilledButton(
            onPressed: onSubmit,
            child: const Text('Activate account'),
          ),
        ],
      ),
    );
  }
}
