import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sign_up_provider.dart';

class SignUpStep3EmergencyContact extends ConsumerStatefulWidget {
  const SignUpStep3EmergencyContact({super.key});

  @override
  ConsumerState<SignUpStep3EmergencyContact> createState() =>
      _SignUpStep3EmergencyContactState();
}

class _SignUpStep3EmergencyContactState
    extends ConsumerState<SignUpStep3EmergencyContact> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(signUpProvider);
    _nameController = TextEditingController(text: s.emergencyContactName);
    _relationshipController = TextEditingController(
      text: s.emergencyContactRelationship,
    );
    _phoneController = TextEditingController(text: s.emergencyContactPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(signUpProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full name',
            prefixIcon: Icon(Icons.person_outlined),
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: notifier.setEmergencyContactName,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _relationshipController,
          decoration: const InputDecoration(
            labelText: 'Relationship (e.g. Spouse, Parent)',
            prefixIcon: Icon(Icons.people_outlined),
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: notifier.setEmergencyContactRelationship,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s+\-()]')),
          ],
          onChanged: notifier.setEmergencyContactPhone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (v.trim().replaceAll(RegExp(r'[\s\-+()]'), '').length < 7) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }
}
