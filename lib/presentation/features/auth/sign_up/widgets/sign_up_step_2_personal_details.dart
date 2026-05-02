import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../sign_up_provider.dart';

const _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
final _dobFormat = DateFormat('dd/MM/yyyy');

class SignUpStep2PersonalDetails extends ConsumerStatefulWidget {
  const SignUpStep2PersonalDetails({super.key});

  @override
  ConsumerState<SignUpStep2PersonalDetails> createState() =>
      _SignUpStep2PersonalDetailsState();
}

class _SignUpStep2PersonalDetailsState
    extends ConsumerState<SignUpStep2PersonalDetails> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _countyController;
  late final TextEditingController _postcodeController;
  late final TextEditingController _countryController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(signUpProvider);
    _firstNameController = TextEditingController(text: s.firstName);
    _lastNameController = TextEditingController(text: s.lastName);
    _dobController = TextEditingController(
      text: s.dateOfBirth != null ? _dobFormat.format(s.dateOfBirth!) : '',
    );
    _addressLine1Controller = TextEditingController(text: s.addressLine1);
    _addressLine2Controller = TextEditingController(text: s.addressLine2 ?? '');
    _cityController = TextEditingController(text: s.city);
    _countyController = TextEditingController(text: s.county);
    _postcodeController = TextEditingController(text: s.postcode);
    _countryController = TextEditingController(text: s.country);
    _phoneController = TextEditingController(text: s.phone);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _postcodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDob(BuildContext context, DateTime? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = _dobFormat.format(picked);
      ref.read(signUpProvider.notifier).setDateOfBirth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First name'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: notifier.setFirstName,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last name'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: notifier.setLastName,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _pickDob(context, s.dateOfBirth),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _dobController,
              decoration: const InputDecoration(
                labelText: 'Date of birth',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: s.gender,
          decoration: const InputDecoration(labelText: 'Gender (optional)'),
          items: _genderOptions
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: notifier.setGender,
        ),
        const SizedBox(height: 24),
        const _SectionHeading('Address'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressLine1Controller,
          decoration: const InputDecoration(labelText: 'Address line 1'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: notifier.setAddressLine1,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressLine2Controller,
          decoration: const InputDecoration(
            labelText: 'Address line 2 (optional)',
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: notifier.setAddressLine2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Town / City'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: notifier.setCity,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _countyController,
                decoration: const InputDecoration(labelText: 'County'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: notifier.setCounty,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _postcodeController,
                decoration: const InputDecoration(labelText: 'Postcode'),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                onChanged: notifier.setPostcode,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: notifier.setCountry,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ],
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
          onChanged: notifier.setPhone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (v.trim().replaceAll(RegExp(r'[\s\-+()]'), '').length < 7) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        const _SectionHeading('Children'),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('I have children to register too'),
          value: s.hasJuniors,
          onChanged: notifier.setHasJuniors,
        ),
        if (s.hasJuniors) ...[
          const SizedBox(height: 8),
          ...List.generate(
            s.children.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChildFormCard(key: ValueKey(i), index: i),
            ),
          ),
          TextButton.icon(
            onPressed: notifier.addChild,
            icon: const Icon(Icons.add),
            label: const Text('Add another child'),
          ),
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ChildFormCard extends ConsumerStatefulWidget {
  const _ChildFormCard({required super.key, required this.index});
  final int index;

  @override
  ConsumerState<_ChildFormCard> createState() => _ChildFormCardState();
}

class _ChildFormCardState extends ConsumerState<_ChildFormCard> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _dobController;

  @override
  void initState() {
    super.initState();
    final children = ref.read(signUpProvider).children;
    final child = widget.index < children.length
        ? children[widget.index]
        : const ChildData();
    _firstNameController = TextEditingController(text: child.firstName);
    _lastNameController = TextEditingController(text: child.lastName);
    _dobController = TextEditingController(
      text: child.dateOfBirth != null
          ? _dobFormat.format(child.dateOfBirth!)
          : '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDob(BuildContext context, DateTime? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(DateTime.now().year - 10),
      firstDate: DateTime(DateTime.now().year - 18),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = _dobFormat.format(picked);
      final children = ref.read(signUpProvider).children;
      final current = widget.index < children.length
          ? children[widget.index]
          : const ChildData();
      ref
          .read(signUpProvider.notifier)
          .updateChild(widget.index, current.copyWith(dateOfBirth: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(signUpProvider).children;
    final child = widget.index < children.length
        ? children[widget.index]
        : const ChildData();
    final notifier = ref.read(signUpProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Child ${widget.index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remove child',
                onPressed: () => notifier.removeChild(widget.index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First name'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) => notifier.updateChild(
                    widget.index,
                    child.copyWith(firstName: v),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) => notifier.updateChild(
                    widget.index,
                    child.copyWith(lastName: v),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _pickDob(context, child.dateOfBirth),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of birth',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: child.gender,
            decoration: const InputDecoration(labelText: 'Gender (optional)'),
            items: _genderOptions
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) =>
                notifier.updateChild(widget.index, child.copyWith(gender: v)),
          ),
        ],
      ),
    );
  }
}
