import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/rank.dart';

// ── BeltSize ──────────────────────────────────────────────────────────────────

enum BeltSize { sm, md, lg }

// ── BeltStripe ────────────────────────────────────────────────────────────────

enum BeltStripe { none, single, double_ }

// ── BeltStrip ─────────────────────────────────────────────────────────────────
// Horizontal belt colour indicator.
//
// Spec:
//   sm  22 × 7 px
//   md  32 × 10 px (default)
//   lg  48 × 14 px
//
// White belt uses a hairline border instead of the inset sheen.
// Striped belts add a coloured tab on the right (yellow by default).

class BeltStrip extends StatelessWidget {
  const BeltStrip({
    super.key,
    required this.color,
    this.size = BeltSize.md,
    this.stripe = BeltStripe.none,
    this.stripeColor = AppColors.beltYellow,
    this.isWhite = false,
  });

  final Color color;
  final BeltSize size;
  final BeltStripe stripe;
  final Color stripeColor;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final (w, h) = switch (size) {
      BeltSize.sm => (22.0, 7.0),
      BeltSize.md => (32.0, 10.0),
      BeltSize.lg => (48.0, 14.0),
    };

    final stripeW = switch (size) {
      BeltSize.sm => 3.0,
      BeltSize.md => 4.0,
      BeltSize.lg => 6.0,
    };

    final stripeRight = switch (size) {
      BeltSize.sm => 1.0,
      BeltSize.md => 2.0,
      BeltSize.lg => 3.0,
    };

    final stripePad = switch (size) {
      BeltSize.sm => 1.0,
      BeltSize.md => 1.0,
      BeltSize.lg => 2.0,
    };

    return SizedBox(
      width: w,
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Stack(
          children: [
            // Belt base
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: isWhite ? Colors.white : color,
                  border: isWhite
                      ? Border.all(color: AppColors.hairline)
                      : null,
                ),
              ),
            ),

            // Inset sheen (not on white belt)
            if (!isWhite)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ),

            // Single stripe tab
            if (stripe == BeltStripe.single)
              Positioned(
                right: stripeRight,
                top: stripePad,
                bottom: stripePad,
                width: stripeW,
                child: Container(
                  decoration: BoxDecoration(
                    color: stripeColor,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 0,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),

            // Double stripe — two adjacent tabs
            if (stripe == BeltStripe.double_)
              Positioned(
                right: stripeRight,
                top: stripePad,
                bottom: stripePad,
                width: stripeW * 2 + 1,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: stripeColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 1),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: stripeColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── BeltColorResolver ─────────────────────────────────────────────────────────
// Converts Rank domain fields to BeltStrip presentation parameters.

class BeltColorResolver {
  const BeltColorResolver._();

  static Color fromHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.paper3;
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length != 6) return AppColors.paper3;
    final value = int.tryParse('FF$clean', radix: 16);
    return value != null ? Color(value) : AppColors.paper3;
  }

  static bool isWhiteBelt(String? hex) {
    if (hex == null) return false;
    return hex.replaceAll('#', '').trim().toUpperCase() == 'FFFFFF';
  }

  static BeltStripe stripeFromRank(Rank rank) {
    if (rank.rankType == RankType.mon) {
      return switch (rank.monCount ?? 0) {
        >= 2 => BeltStripe.double_,
        1 => BeltStripe.single,
        _ => BeltStripe.none,
      };
    }
    return BeltStripe.none;
  }
}

// ── KendoRankChip ─────────────────────────────────────────────────────────────
// Dashed-border chip used in place of a belt strip for Kendo ranks.
//
// Spec:
//   padding 2px 8px; border 1px dashed hairline; border-radius r-xs (2px);
//   f-mono 13px; ink-2. Prefixed with 剣 ideogram.

class KendoRankChip extends StatelessWidget {
  const KendoRankChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedBorderPainter(
        color: AppColors.hairline,
        radius: AppRadius.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '剣',
              style: GoogleFonts.notoSerifJp(
                fontSize: 11,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 13,
                color: AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          Radius.circular(radius),
        ),
      );

    const dashLength = 4.0;
    const gapLength = 3.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        final segLen = drawing ? dashLength : gapLength;
        if (drawing) {
          canvas.drawPath(
            metric.extractPath(distance, distance + segLen),
            paint,
          );
        }
        distance += segLen;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

// ── BeltRankRow ───────────────────────────────────────────────────────────────
// Strip + rank label side by side.

class BeltRankRow extends StatelessWidget {
  const BeltRankRow({
    super.key,
    required this.color,
    required this.label,
    this.size = BeltSize.md,
    this.stripe = BeltStripe.none,
    this.stripeColor = AppColors.beltYellow,
    this.isWhite = false,
  });

  final Color color;
  final String label;
  final BeltSize size;
  final BeltStripe stripe;
  final Color stripeColor;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BeltStrip(
          color: color,
          size: size,
          stripe: stripe,
          stripeColor: stripeColor,
          isWhite: isWhite,
        ),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
