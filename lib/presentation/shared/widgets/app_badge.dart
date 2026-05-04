import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ── MembershipStatus ──────────────────────────────────────────────────────────

enum MembershipStatus {
  active,
  lapsed,
  trial,
  expiringSoon,
  expired,
  cancelled,
}

// ── MemberRole ────────────────────────────────────────────────────────────────

enum MemberRole { adult, junior, coach, parent }

// ── Discipline ────────────────────────────────────────────────────────────────

enum Discipline { karate, judo, jujitsu, aikido, kendo }

// ── MembershipBadge ───────────────────────────────────────────────────────────
// Mono eyebrow-style badge with a leading 6px dot.
// Spec: f-mono 11px, letter-spacing 0.1em, uppercase, padding 3/8px, r-xs (2px).

class MembershipBadge extends StatelessWidget {
  const MembershipBadge({super.key, required this.status, this.label});

  final MembershipStatus status;

  /// Override the auto-generated label (e.g. "Expires in 3 d").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (text, fg, bg) = _resolve();
    final isStrikethrough = status == MembershipStatus.cancelled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            (label ?? text).toUpperCase(),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1 * 11,
              color: fg,
              decoration: isStrikethrough ? TextDecoration.lineThrough : null,
              decorationColor: fg,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _resolve() => switch (status) {
    MembershipStatus.active => (
      'Active',
      AppColors.success,
      AppColors.successWash,
    ),
    MembershipStatus.lapsed => ('Lapsed', AppColors.error, AppColors.errorWash),
    MembershipStatus.trial => ('Trial', AppColors.indigo, AppColors.indigoWash),
    MembershipStatus.expiringSoon => (
      'Expires soon',
      AppColors.ochre,
      AppColors.ochreWash,
    ),
    MembershipStatus.expired => ('Expired', AppColors.ink3, AppColors.paper3),
    MembershipStatus.cancelled => (
      'Cancelled',
      AppColors.ink3,
      AppColors.paper3,
    ),
  };
}

// ── RoleBadge ─────────────────────────────────────────────────────────────────
// No leading dot. Same font/size/padding/radius as MembershipBadge.

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final MemberRole role;

  @override
  Widget build(BuildContext context) {
    final (text, fg, bg) = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1 * 11,
          color: fg,
        ),
      ),
    );
  }

  (String, Color, Color) _resolve() => switch (role) {
    MemberRole.adult => ('Adult', AppColors.indigo, AppColors.indigoWash),
    MemberRole.junior => ('Junior', AppColors.tea, AppColors.teaWash),
    MemberRole.coach => ('Coach', AppColors.crimson, AppColors.crimsonWash),
    MemberRole.parent => ('Parent', AppColors.ochre, AppColors.ochreWash),
  };
}

// ── DisciplineChip ────────────────────────────────────────────────────────────
// Pill-shaped chip — 6px coloured dot + discipline name.
// Spec: padding 4/10/4/8px, r-pill, bg paper-3, 13px body text, ink-2.

class DisciplineChip extends StatelessWidget {
  const DisciplineChip({super.key, required this.discipline, this.label});

  final Discipline discipline;

  /// Override label text (e.g. for truncation or custom strings).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (name, dotColor) = _resolve();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.paper3,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label ?? name,
            style: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }

  (String, Color) _resolve() => switch (discipline) {
    Discipline.karate => ('Karate', AppColors.discKarate),
    Discipline.judo => ('Judo', AppColors.discJudo),
    Discipline.jujitsu => ('Jujitsu', AppColors.discJujitsu),
    Discipline.aikido => ('Aikido', AppColors.discAikido),
    Discipline.kendo => ('Kendo', AppColors.discKendo),
  };
}
