import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum AppButtonVariant { primary, secondary, destructive, text }

enum AppButtonSize { sm, md, lg }

// ── AppButton ─────────────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leading,
    this.trailing,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final Widget? trailing;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !loading;

    Widget child;
    if (loading) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: variant == AppButtonVariant.primary
                  ? AppColors.paper0
                  : AppColors.crimson,
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Text(label),
        ],
      );
    } else {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.s2),
          ],
          Text(label),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s2),
            trailing!,
          ],
        ],
      );
    }

    if (expand) {
      child = Center(child: child);
    }

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: SizedBox(
        height: _height,
        width: expand ? double.infinity : null,
        child: TextButton(
          onPressed: isDisabled || loading ? null : onPressed,
          style: _buildStyle(),
          child: DefaultTextStyle.merge(style: _textStyle, child: child),
        ),
      ),
    );
  }

  double get _height => switch (size) {
    AppButtonSize.sm => 32,
    AppButtonSize.md => 40,
    AppButtonSize.lg => 52,
  };

  EdgeInsets get _padding => switch (size) {
    AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    AppButtonSize.md => const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 10,
    ),
    AppButtonSize.lg => const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 14,
    ),
  };

  TextStyle get _textStyle => GoogleFonts.ibmPlexSans(
    fontSize: switch (size) {
      AppButtonSize.sm => 13.0,
      AppButtonSize.md => 15.0,
      AppButtonSize.lg => 16.0,
    },
    fontWeight: FontWeight.w500,
    letterSpacing: 0.01 * 15,
  );

  ButtonStyle _buildStyle() {
    switch (variant) {
      case AppButtonVariant.primary:
        return TextButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: AppColors.paper0,
          padding: _padding,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            side: BorderSide(color: AppColors.crimsonInk),
          ),
          overlayColor: AppColors.crimsonInk,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.crimsonInk;
            }
            return AppColors.crimson;
          }),
        );

      case AppButtonVariant.secondary:
        return TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.ink1,
          padding: _padding,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            side: BorderSide(color: AppColors.ink1),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return AppColors.ink1;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return AppColors.paper0;
            return AppColors.ink1;
          }),
        );

      case AppButtonVariant.destructive:
        return TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.error,
          padding: _padding,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            side: BorderSide(color: AppColors.error),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return AppColors.error;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return AppColors.paper0;
            return AppColors.error;
          }),
        );

      case AppButtonVariant.text:
        return TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.crimson,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
    }
  }
}

// ── AppIconButton ─────────────────────────────────────────────────────────────
// 40×40 square icon button — hairline border, ink-2 icon, hover → paper-3

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Tooltip(
        message: tooltip ?? '',
        child: TextButton(
          onPressed: onPressed,
          style:
              TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.ink2,
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
                  side: BorderSide(color: AppColors.hairline),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return AppColors.paper3;
                  }
                  return Colors.transparent;
                }),
              ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

// ── AppFab ────────────────────────────────────────────────────────────────────
// 56×56 circular FAB — crimson bg, sh-3 shadow

class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: AppColors.crimson,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppShadow.sh3,
            ),
            child: Center(
              child: IconTheme(
                data: const IconThemeData(color: AppColors.paper0, size: 24),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
