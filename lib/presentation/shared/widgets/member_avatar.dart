import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

// ── AvatarSize ────────────────────────────────────────────────────────────────

enum AvatarSize { sm, md, lg, xl }

// ── MemberAvatar ──────────────────────────────────────────────────────────────
// Circular initials avatar.
//
// Spec:
//   sm  32 × 32 px · 13 px text
//   md  40 × 40 px · 16 px text  (default)
//   lg  64 × 64 px · 22 px text
//   xl  96 × 96 px · 32 px text
//
// Background paper-3, border hairline, text ink-2, font Noto Serif JP w500.

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.initials,
    this.size = AvatarSize.md,
    this.imageUrl,
  });

  final String initials;
  final AvatarSize size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final (diameter, fontSize) = switch (size) {
      AvatarSize.sm => (32.0, 13.0),
      AvatarSize.md => (40.0, 16.0),
      AvatarSize.lg => (64.0, 22.0),
      AvatarSize.xl => (96.0, 32.0),
    };

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.paper3,
        border: Border.all(color: AppColors.hairline),
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                _safeInitials,
                style: GoogleFonts.notoSerifJp(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink2,
                ),
              ),
            )
          : null,
    );
  }

  String get _safeInitials {
    final trimmed = initials.trim().toUpperCase();
    if (trimmed.isEmpty) return '?';
    if (trimmed.length <= 2) return trimmed;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}';
    return trimmed.substring(0, 2);
  }
}
