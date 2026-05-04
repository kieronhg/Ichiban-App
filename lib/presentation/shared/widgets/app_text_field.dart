import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ── AppTextField ──────────────────────────────────────────────────────────────
// Label above field (mono eyebrow style), then input, then optional error/help.

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.helpText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.autofocus = false,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.textInputAction,
    this.initialValue,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final String? helpText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final bool autofocus;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final TextInputAction? textInputAction;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.12 * 11,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          readOnly: readOnly,
          autofocus: autofocus,
          enabled: enabled,
          textInputAction: textInputAction,
          initialValue: controller == null ? initialValue : null,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.ink1,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.ibmPlexSans(
              fontSize: 15,
              color: AppColors.ink4,
            ),
            filled: true,
            fillColor: enabled ? AppColors.paper0 : AppColors.paper3,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
              borderSide: BorderSide(color: AppColors.hairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.sm),
              ),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.hairline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.sm),
              ),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.crimson,
                width: 1.5,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            disabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
              borderSide: BorderSide(color: AppColors.paper4),
            ),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            errorText: null, // we render error manually below
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.s1),
          Text(
            errorText!,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: AppColors.error,
            ),
          ),
        ] else if (helpText != null) ...[
          const SizedBox(height: AppSpacing.s1),
          Text(
            helpText!,
            style: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.ink3),
          ),
        ],
      ],
    );
  }
}

// ── AppTextArea ───────────────────────────────────────────────────────────────
// Multi-line variant — min 3 rows, vertically resizable content.

class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.errorText,
    this.helpText,
    this.minLines = 3,
    this.maxLines = 8,
    this.enabled = true,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? helpText;
  final int minLines;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      onChanged: onChanged,
      errorText: errorText,
      helpText: helpText,
      minLines: minLines,
      maxLines: maxLines,
      enabled: enabled,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}

// ── AppSearchField ────────────────────────────────────────────────────────────
// Search input with leading magnifier icon.

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.hint = 'Search',
    this.controller,
    this.onChanged,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        style: GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.ink1),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.ibmPlexSans(
            fontSize: 15,
            color: AppColors.ink4,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, size: 18, color: AppColors.ink3),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          filled: true,
          fillColor: AppColors.paper0,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            borderSide: BorderSide(color: AppColors.hairline),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            borderSide: BorderSide(color: AppColors.hairline),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            borderSide: BorderSide(color: AppColors.crimson, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── AppToggle ─────────────────────────────────────────────────────────────────
// 44×24 pill toggle. Pass [value] + [onChanged] for controlled state.

class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final toggle = GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.crimson : AppColors.paper3,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? AppColors.crimsonInk : AppColors.hairline,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.paper0,
              shape: BoxShape.circle,
              boxShadow: AppShadow.sh1,
            ),
          ),
        ),
      ),
    );

    if (label == null) return toggle;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          toggle,
          const SizedBox(width: AppSpacing.s2 + 2),
          Text(
            label!,
            style: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

// ── AppCheckbox ───────────────────────────────────────────────────────────────
// 20×20 square checkbox with 3px border radius.

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final box = GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? AppColors.ink1 : AppColors.paper0,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: value ? AppColors.ink1 : AppColors.ink2,
            width: 1.5,
          ),
        ),
        child: value
            ? const Center(
                child: Icon(Icons.check, size: 14, color: AppColors.paper0),
              )
            : null,
      ),
    );

    if (label == null) return box;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          box,
          const SizedBox(width: AppSpacing.s2 + 2),
          Text(
            label!,
            style: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}
