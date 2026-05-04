import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// Type scale — Noto Serif JP (display/headings) · IBM Plex Sans (body) · IBM Plex Mono (label/mono)
class AppTextStyles {
  AppTextStyles._();

  // ── Display · Noto Serif JP ──────────────────────────────────
  // 48 / 52 · w500 — hero titles, empty state titles
  static TextStyle get displayLarge => GoogleFonts.notoSerifJp(
    fontSize: 48,
    fontWeight: FontWeight.w500,
    height: 52 / 48,
    letterSpacing: -0.96, // -0.02em
    color: AppColors.ink1,
  );

  // 32 / 40 · w500 — screen titles
  static TextStyle get displayMedium => GoogleFonts.notoSerifJp(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 40 / 32,
    color: AppColors.ink1,
  );

  // 24 / 32 · w500 — section headings, card titles
  static TextStyle get headlineLarge => GoogleFonts.notoSerifJp(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 32 / 24,
    color: AppColors.ink1,
  );

  // 19 / 28 · w600 — sub-headings, form sections (IBM Plex Sans)
  static TextStyle get headlineMedium => GoogleFonts.ibmPlexSans(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 28 / 19,
    color: AppColors.ink1,
  );

  // 15 / 22 · w600 — bold variant at body size
  static TextStyle get titleLarge => GoogleFonts.ibmPlexSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 22 / 15,
    color: AppColors.ink1,
  );

  // ── Body · IBM Plex Sans ─────────────────────────────────────
  // 15 / 22 · w400 — default reading text
  static TextStyle get bodyLarge => GoogleFonts.ibmPlexSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    color: AppColors.ink1,
  );

  // 13 / 20 · w400 — secondary info, list subtitles
  static TextStyle get bodyMedium => GoogleFonts.ibmPlexSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 20 / 13,
    color: AppColors.ink1,
  );

  // 13 / 20 · w400 · ink3 — captions
  static TextStyle get bodySmall => GoogleFonts.ibmPlexSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 20 / 13,
    color: AppColors.ink3,
  );

  // ── Label · IBM Plex Mono ────────────────────────────────────
  // 11 / 16 · w500 — form labels, eyebrow, chips, codes, prices
  static TextStyle get labelLarge => GoogleFonts.ibmPlexMono(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 16 / 11,
    letterSpacing: 1.54, // 0.14em at 11px
    color: AppColors.ink3,
  );

  // ── Convenience variants ─────────────────────────────────────

  // Body with ink2 colour (secondary)
  static TextStyle get bodySecondary => GoogleFonts.ibmPlexSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    color: AppColors.ink2,
  );

  // Mono for prices, PINs, codes
  static TextStyle get mono => GoogleFonts.ibmPlexMono(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 22 / 15,
    color: AppColors.ink1,
  );
}
