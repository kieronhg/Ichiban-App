import 'package:flutter/material.dart';
import 'app_colors.dart';

// ── Spacing — 4pt base grid ──────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
  static const double s20 = 80;
}

// ── Border radius ────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double xs = 2; // Chips, tags
  static const double sm = 4; // Buttons, inputs
  static const double md = 6; // Cards
  static const double lg = 10; // Bottom sheets, modals
  static const double xl = 12; // Cards, summary tiles, dialogs
  static const double pill = 999; // Avatars, pill tags

  static BorderRadius get chipRadius => BorderRadius.circular(xs);
  static BorderRadius get buttonRadius => BorderRadius.circular(sm);
  static BorderRadius get cardRadius => BorderRadius.circular(md);
  static BorderRadius get sheetRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}

// ── Elevation / shadow ───────────────────────────────────────────
// Shadow colour: ink-1 (#1C1B18). Alpha values: 0.04=0x0A, 0.06=0x0F, 0.08=0x14, 0.12=0x1F
class AppShadow {
  AppShadow._();

  // Cards at rest
  static const List<BoxShadow> sh1 = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 0, color: Color(0x0A1C1B18)),
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0F1C1B18)),
  ];

  // Hover / focus
  static const List<BoxShadow> sh2 = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x0F1C1B18)),
    BoxShadow(offset: Offset(0, 4), blurRadius: 8, color: Color(0x0F1C1B18)),
  ];

  // Bottom sheet / nav
  static const List<BoxShadow> sh3 = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 12, color: Color(0x141C1B18)),
    BoxShadow(offset: Offset(0, 12), blurRadius: 24, color: Color(0x141C1B18)),
  ];

  // Modal
  static const List<BoxShadow> sh4 = [
    BoxShadow(offset: Offset(0, 12), blurRadius: 32, color: Color(0x1F1C1B18)),
    BoxShadow(offset: Offset(0, 32), blurRadius: 64, color: Color(0x1F1C1B18)),
  ];

  // Dark-mode equivalents
  static const List<BoxShadow> sh1Dark = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 0, color: Color(0x40000000)),
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x59000000)),
  ];
  static const List<BoxShadow> sh2Dark = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x4D000000)),
    BoxShadow(offset: Offset(0, 4), blurRadius: 8, color: Color(0x4D000000)),
  ];
  static const List<BoxShadow> sh3Dark = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 12, color: Color(0x66000000)),
    BoxShadow(offset: Offset(0, 12), blurRadius: 24, color: Color(0x66000000)),
  ];
  static const List<BoxShadow> sh4Dark = [
    BoxShadow(offset: Offset(0, 12), blurRadius: 32, color: Color(0x80000000)),
    BoxShadow(offset: Offset(0, 32), blurRadius: 64, color: Color(0x80000000)),
  ];

  // Focus ring — 3px crimson at 25% opacity, outside the border
  static List<BoxShadow> focusRing({Color? color}) => [
    BoxShadow(
      offset: Offset.zero,
      blurRadius: 0,
      spreadRadius: 3,
      color: (color ?? AppColors.crimson).withValues(alpha: 0.25),
    ),
  ];
}

// ── Motion ───────────────────────────────────────────────────────
class AppMotion {
  AppMotion._();

  static const Duration snap = Duration(milliseconds: 80); // Tap feedback
  static const Duration short = Duration(
    milliseconds: 150,
  ); // Hover, focus, toggle
  static const Duration medium = Duration(
    milliseconds: 240,
  ); // Sheet in, tab switch
  static const Duration long = Duration(milliseconds: 400); // Check-in success

  static const Curve snapCurve = Cubic(0.2, 0, 0.4, 1);
  static const Curve standardCurve = Curves.easeInOut;
}
