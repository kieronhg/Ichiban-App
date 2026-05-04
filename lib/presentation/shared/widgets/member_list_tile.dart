import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'app_badge.dart';
import 'belt_strip.dart';
import 'member_avatar.dart';

// ── MemberListTile ────────────────────────────────────────────────────────────
// Row: [avatar] [name + belt rank] [role badge] [status badge]
//
// Spec: padding 14/20px, separator 1px hairline.

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.name,
    required this.initials,
    required this.role,
    required this.membershipStatus,
    this.statusLabel,
    this.beltColor,
    this.beltLabel,
    this.beltIsWhite = false,
    this.beltStripe = BeltStripe.none,
    this.onTap,
    this.showDivider = true,
    this.highlighted = false,
  });

  final String name;
  final String initials;
  final MemberRole role;
  final MembershipStatus membershipStatus;

  /// Override the auto-generated membership badge label.
  final String? statusLabel;

  final Color? beltColor;
  final String? beltLabel;
  final bool beltIsWhite;
  final BeltStripe beltStripe;
  final VoidCallback? onTap;
  final bool showDivider;

  /// Highlight row with paper-2 background (e.g. selected or trial).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    Widget tile = Material(
      color: highlighted ? AppColors.paper2 : AppColors.paper0,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.paper3,
        highlightColor: AppColors.paper3.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: 14,
          ),
          child: Row(
            children: [
              MemberAvatar(initials: initials, size: AvatarSize.sm),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink1,
                      ),
                    ),
                    if (beltColor != null || beltIsWhite) ...[
                      const SizedBox(height: 2),
                      BeltRankRow(
                        color: beltColor ?? AppColors.beltWhite,
                        label: beltLabel ?? '',
                        size: BeltSize.sm,
                        stripe: beltStripe,
                        isWhite: beltIsWhite,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              RoleBadge(role: role),
              const SizedBox(width: AppSpacing.s2),
              MembershipBadge(status: membershipStatus, label: statusLabel),
            ],
          ),
        ),
      ),
    );

    if (!showDivider) return tile;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        const Divider(height: 1, thickness: 1, color: AppColors.hairline),
      ],
    );
  }
}
