import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../sign_up_provider.dart';

class SignUpStep9PinSetup extends ConsumerStatefulWidget {
  const SignUpStep9PinSetup({super.key});

  @override
  ConsumerState<SignUpStep9PinSetup> createState() =>
      _SignUpStep9PinSetupState();
}

class _SignUpStep9PinSetupState extends ConsumerState<SignUpStep9PinSetup> {
  late final TextEditingController _pinController;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(signUpProvider);
    _pinController = TextEditingController(text: s.pin);
    _confirmController = TextEditingController(text: s.confirmPin);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(signUpProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your PIN is used to check in at the dojo kiosk. Choose a 4-digit '
          'number that you will remember.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _pinController,
          decoration: const InputDecoration(
            labelText: 'PIN',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
          keyboardType: TextInputType.number,
          obscureText: true,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          onChanged: notifier.setPin,
          validator: (v) {
            if (v == null || v.isEmpty) return 'PIN is required';
            if (v.length != 4) return 'PIN must be exactly 4 digits';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmController,
          decoration: const InputDecoration(
            labelText: 'Confirm PIN',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
          keyboardType: TextInputType.number,
          obscureText: true,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          onChanged: notifier.setConfirmPin,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your PIN';
            if (v != ref.read(signUpProvider).pin) {
              return 'PINs do not match';
            }
            return null;
          },
        ),
      ],
    );
  }
}
