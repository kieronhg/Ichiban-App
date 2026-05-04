import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/rank.dart';
import 'belt_strip.dart';

// ── RankLadderRow ─────────────────────────────────────────────────────────────
// Single row in the rank ladder grid.
//
// Spec (5-column grid):
//   32px  position number   f-mono 11px ink-3
//   60px  belt strip (lg)   or KendoRankChip when isKendo
//   1fr   rank name         IBM Plex Sans 14px ink-1
//   80px  type label        f-mono 10px uppercase ink-3
//   60px  holder count      f-mono 11px ink-3 right-aligned
//
// Hover → paper-2 background.

class RankLadderRow extends StatefulWidget {
  const RankLadderRow({
    super.key,
    required this.rank,
    required this.position,
    this.holderCount,
    this.isKendo = false,
    this.onTap,
    this.trailing,
  });

  final Rank rank;
  final int position;
  final int? holderCount;
  final bool isKendo;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  State<RankLadderRow> createState() => _RankLadderRowState();
}

class _RankLadderRowState extends State<RankLadderRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = BeltColorResolver.fromHex(widget.rank.colourHex);
    final isWhite = BeltColorResolver.isWhiteBelt(widget.rank.colourHex);
    final stripe = BeltColorResolver.stripeFromRank(widget.rank);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.short,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.paper2 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              // Position number
              SizedBox(
                width: 32,
                child: Text(
                  '${widget.position}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
                ),
              ),
              // Belt strip or Kendo chip
              SizedBox(
                width: 60,
                child: widget.isKendo
                    ? null
                    : BeltStrip(
                        color: color,
                        size: BeltSize.lg,
                        stripe: stripe,
                        isWhite: isWhite,
                      ),
              ),
              // Rank name
              Expanded(
                child: widget.isKendo
                    ? KendoRankChip(label: widget.rank.name)
                    : Text(
                        widget.rank.name,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          color: AppColors.ink1,
                        ),
                      ),
              ),
              // Type label
              SizedBox(
                width: 80,
                child: Text(
                  _typeLabel(widget.rank.rankType),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: AppColors.ink3,
                  ),
                ),
              ),
              // Holder count
              SizedBox(
                width: 60,
                child: Text(
                  widget.holderCount != null ? '${widget.holderCount}' : '',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(RankType type) => switch (type) {
    RankType.kyu => 'KYU',
    RankType.dan => 'DAN',
    RankType.mon => 'MON',
    RankType.ungraded => 'UNGRADED',
  };
}
