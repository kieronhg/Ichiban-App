import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'app_button.dart';

// ── EmptyState ────────────────────────────────────────────────────────────────
// Centred empty-state block.
//
// Spec:
//   Seal glyph (optional, shown in crimson stamp style) — 44×44px.
//   Title: f-display 20px.
//   Body: 13px ink-3, max-width ~280px.
//   Optional primary CTA button (sm).

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.sealGlyph,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;

  /// CJK glyph shown as a crimson woodblock-stamp tile (e.g. '空').
  final String? sealGlyph;

  /// Alternative icon widget if no seal glyph is needed.
  final Widget? icon;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sealGlyph != null) ...[
              _SealTile(glyph: sealGlyph!),
              const SizedBox(height: AppSpacing.s4),
            ] else if (icon != null) ...[
              IconTheme(
                data: const IconThemeData(color: AppColors.ink3, size: 44),
                child: icon!,
              ),
              const SizedBox(height: AppSpacing.s4),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifJp(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.ink1,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.s2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    color: AppColors.ink3,
                    height: 20 / 13,
                  ),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.s4),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                size: AppButtonSize.sm,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── _SealTile ─────────────────────────────────────────────────────────────────
// 44×44 crimson stamp block, rotated –3°.

class _SealTile extends StatelessWidget {
  const _SealTile({required this.glyph});

  final String glyph;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -3 * 3.141592653589793 / 180,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.crimson,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.15),
              blurRadius: 0,
              spreadRadius: -1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            glyph,
            style: GoogleFonts.notoSerifJp(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.paper0,
            ),
          ),
        ),
      ),
    );
  }
}
