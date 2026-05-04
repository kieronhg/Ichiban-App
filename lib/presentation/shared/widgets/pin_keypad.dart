import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ── PinDots ───────────────────────────────────────────────────────────────────
// Row of PIN indicator dots — filled for entered digits.

class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.hasError = false,
  });

  final int length;
  final int filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: i == 0 ? 0 : AppSpacing.s4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasError
                  ? AppColors.error
                  : isFilled
                  ? AppColors.ink1
                  : Colors.transparent,
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : isFilled
                    ? AppColors.ink1
                    : AppColors.ink2,
                width: 1.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── PinKeypad ─────────────────────────────────────────────────────────────────
// 3×4 keypad grid. [onDigit] fires with '0'–'9'. [onDelete] fires on backspace.
// [onClear] fires on the CLEAR key (optional).

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onClear,
    this.disabled = false,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onClear;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _KeyRow(keys: ['1', '2', '3'], onDigit: onDigit, disabled: disabled),
        const SizedBox(height: 12),
        _KeyRow(keys: ['4', '5', '6'], onDigit: onDigit, disabled: disabled),
        const SizedBox(height: 12),
        _KeyRow(keys: ['7', '8', '9'], onDigit: onDigit, disabled: disabled),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ClearKey(onClear: onClear, disabled: disabled),
            const SizedBox(width: 12),
            _DigitKey(digit: '0', onDigit: onDigit, disabled: disabled),
            const SizedBox(width: 12),
            _DeleteKey(onDelete: onDelete, disabled: disabled),
          ],
        ),
      ],
    );
  }
}

// ── Private key widgets ───────────────────────────────────────────────────────

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.keys,
    required this.onDigit,
    required this.disabled,
  });

  final List<String> keys;
  final ValueChanged<String> onDigit;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: keys
          .expand(
            (k) => [
              if (k != keys.first) const SizedBox(width: 12),
              _DigitKey(digit: k, onDigit: onDigit, disabled: disabled),
            ],
          )
          .toList(),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({
    required this.digit,
    required this.onDigit,
    required this.disabled,
  });

  final String digit;
  final ValueChanged<String> onDigit;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return _RoundKey(
      onTap: disabled ? null : () => onDigit(digit),
      child: Text(
        digit,
        style: GoogleFonts.notoSerifJp(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: disabled ? AppColors.ink4 : AppColors.ink1,
        ),
      ),
    );
  }
}

class _ClearKey extends StatelessWidget {
  const _ClearKey({this.onClear, required this.disabled});

  final VoidCallback? onClear;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return _RoundKey(
      onTap: (disabled || onClear == null) ? null : onClear,
      hasBorder: false,
      child: Text(
        'CLEAR',
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          letterSpacing: 0.1 * 11,
          color: disabled ? AppColors.ink4 : AppColors.ink2,
        ),
      ),
    );
  }
}

class _DeleteKey extends StatelessWidget {
  const _DeleteKey({required this.onDelete, required this.disabled});

  final VoidCallback onDelete;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return _RoundKey(
      onTap: disabled ? null : onDelete,
      hasBorder: false,
      child: Icon(
        Icons.backspace_outlined,
        size: 22,
        color: disabled ? AppColors.ink4 : AppColors.ink2,
      ),
    );
  }
}

class _RoundKey extends StatelessWidget {
  const _RoundKey({required this.child, this.onTap, this.hasBorder = true});

  final Widget child;
  final VoidCallback? onTap;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: hasBorder ? AppColors.paper0 : Colors.transparent,
      shape: hasBorder
          ? CircleBorder(
              side: BorderSide(
                color: onTap == null ? AppColors.paper4 : AppColors.hairline,
              ),
            )
          : const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 64, height: 64, child: Center(child: child)),
      ),
    );
  }
}
