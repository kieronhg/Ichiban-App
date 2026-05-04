import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Surfaces — washi paper ───────────────────────────────────
  static const Color paper0 = Color(0xFFFAF4E7); // Modal / elevated
  static const Color paper1 = Color(0xFFF3EBDD); // App background
  static const Color paper2 = Color(0xFFECE2D0); // Card background
  static const Color paper3 = Color(0xFFE2D6BF); // Hover fill
  static const Color paper4 = Color(0xFFD4C5A8); // Muted divider

  // ── Ink — sumi text ──────────────────────────────────────────
  static const Color ink1 = Color(0xFF1C1B18); // Primary text
  static const Color ink2 = Color(0xFF3B3A36); // Secondary
  static const Color ink3 = Color(0xFF6B6860); // Tertiary / caption
  static const Color ink4 = Color(0xFF928E83); // Disabled
  static const Color hairline = Color(0xFFBEB29B); // Borders / rules

  // ── Brand accents — woodblock pigment ────────────────────────
  static const Color crimson = Color(0xFF8B2A1F); // Primary action · hanko red
  static const Color crimsonInk = Color(0xFF6E1F17); // Pressed
  static const Color crimsonWash = Color(0xFFF0D9D2); // Tinted surface

  static const Color tea = Color(0xFF5C6E4F); // Secondary · matcha
  static const Color teaWash = Color(0xFFDCE1D2);

  static const Color ochre = Color(0xFFB8873A); // Warning
  static const Color ochreWash = Color(0xFFEFE0C1);

  static const Color indigo = Color(0xFF2F4562); // Info
  static const Color indigoWash = Color(0xFFD5DCE5);

  // ── Status ───────────────────────────────────────────────────
  static const Color success = Color(0xFF4F6B3E); // Active · confirmed
  static const Color successWash = Color(0xFFDDE3CF);
  static const Color error = Color(0xFF9A2E20); // Lapsed · failed
  static const Color errorWash = Color(0xFFF1D4CE);
  static const Color warning = Color(0xFFB8873A); // Expires soon · attention
  static const Color warningWash = Color(0xFFEFE0C1);
  static const Color info = Color(0xFF2F4562); // Trial · neutral
  static const Color infoWash = Color(0xFFD5DCE5);

  // ── Discipline accents (tag dots, rails — not primary fills) ─
  static const Color discKarate = Color(0xFF8B2A1F);
  static const Color discJudo = Color(0xFF2F4562);
  static const Color discJujitsu = Color(0xFF5C6E4F);
  static const Color discAikido = Color(0xFFB8873A);
  static const Color discKendo = Color(0xFF3B3A36);

  // ── Belt colours — fixed ─────────────────────────────────────
  static const Color beltWhite = Color(0xFFFFFFFF);
  static const Color beltRed = Color(0xFFC43A2E);
  static const Color beltYellow = Color(0xFFE8C547);
  static const Color beltOrange = Color(0xFFE08A3C);
  static const Color beltGreen = Color(0xFF3F7A3A);
  static const Color beltBlue = Color(0xFF2E5AA6);
  static const Color beltPurple = Color(0xFF6E3B8C);
  static const Color beltLightBlue = Color(0xFF8FB4D9);
  static const Color beltDarkBlue = Color(0xFF1E2C5A);
  static const Color beltBrown = Color(0xFF7A4A22);
  static const Color beltBrownDark = Color(0xFF4F2E15);
  static const Color beltBlack = Color(0xFF15120E);

  // ── Legacy aliases ───────────────────────────────────────────
  static const Color primary = crimson;
  static const Color primaryVariant = crimsonInk;
  static const Color accent = tea;
  static const Color accentVariant = tea;
  static const Color background = paper1;
  static const Color surface = paper2;
  static const Color surfaceVariant = paper3;
  static const Color textPrimary = ink1;
  static const Color textSecondary = ink3;
  static const Color textOnPrimary = paper0;
  static const Color textOnAccent = paper0;
  static const Color brandSurface = ink1;
  static const Color warmPaper = paper0;
  static const Color warmField = paper1;
  static const Color white = Color(0xFFFFFFFF);
}

class AppColorsDark {
  AppColorsDark._();

  // ── Surfaces ─────────────────────────────────────────────────
  static const Color paper0 = Color(0xFF23201B);
  static const Color paper1 = Color(0xFF1A1815);
  static const Color paper2 = Color(0xFF23201B);
  static const Color paper3 = Color(0xFF2C2823);
  static const Color paper4 = Color(0xFF3A352E);

  // ── Ink ──────────────────────────────────────────────────────
  static const Color ink1 = Color(0xFFF0E8D8);
  static const Color ink2 = Color(0xFFC8C0AF);
  static const Color ink3 = Color(0xFF8F897B);
  static const Color ink4 = Color(0xFF635F55);
  static const Color hairline = Color(0xFF3A352E);

  // ── Accents (brightened for dark contrast) ───────────────────
  static const Color crimson = Color(0xFFC74A3B);
  static const Color crimsonWash = Color(0xFF3A1F1A);
  static const Color tea = Color(0xFF8FA379);
  static const Color teaWash = Color(0xFF243022);
  static const Color ochre = Color(0xFFD9A65C);
  static const Color ochreWash = Color(0xFF3A2E1A);
  static const Color indigo = Color(0xFF8FA8CA);
  static const Color indigoWash = Color(0xFF1E2838);

  // ── Status washes ────────────────────────────────────────────
  static const Color errorWash = Color(0xFF3A1F1A);
  static const Color successWash = Color(0xFF243022);
}
