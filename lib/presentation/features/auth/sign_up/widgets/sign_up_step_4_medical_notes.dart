import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../sign_up_provider.dart';

class SignUpStep4MedicalNotes extends ConsumerStatefulWidget {
  const SignUpStep4MedicalNotes({super.key});

  @override
  ConsumerState<SignUpStep4MedicalNotes> createState() =>
      _SignUpStep4MedicalNotesState();
}

class _SignUpStep4MedicalNotesState
    extends ConsumerState<SignUpStep4MedicalNotes> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(signUpProvider).allergiesOrMedicalNotes ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(signUpProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'This information helps coaches and first-aiders keep everyone safe. '
          'Leave blank if there is nothing to declare.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Allergies or medical notes (optional)',
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          onChanged: notifier.setAllergiesOrMedicalNotes,
        ),
      ],
    );
  }
}
