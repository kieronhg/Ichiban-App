import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.crimson,
      onPrimary: AppColors.paper0,
      primaryContainer: AppColors.crimsonWash,
      onPrimaryContainer: AppColors.crimsonInk,
      secondary: AppColors.tea,
      onSecondary: AppColors.paper0,
      secondaryContainer: AppColors.teaWash,
      onSecondaryContainer: AppColors.tea,
      surface: AppColors.paper2,
      onSurface: AppColors.ink1,
      surfaceContainerHighest: AppColors.paper3,
      onSurfaceVariant: AppColors.ink2,
      outline: AppColors.hairline,
      outlineVariant: AppColors.paper4,
      error: AppColors.error,
      onError: AppColors.paper0,
      errorContainer: AppColors.errorWash,
      onErrorContainer: AppColors.error,
      scrim: Color(0x661C1B18),
    ),
    scaffoldBackgroundColor: AppColors.paper1,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper1,
      foregroundColor: AppColors.ink1,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AppTextStyles.displayMedium,
    ),
    cardTheme: CardThemeData(
      color: AppColors.paper2,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: const BorderSide(color: AppColors.hairline, width: 1),
      ),
      margin: const EdgeInsets.all(AppSpacing.s4),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.crimson,
        foregroundColor: AppColors.paper0,
        disabledBackgroundColor: AppColors.paper4,
        disabledForegroundColor: AppColors.ink4,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        textStyle: AppTextStyles.titleLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink1,
        side: const BorderSide(color: AppColors.hairline),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        textStyle: AppTextStyles.titleLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.crimson,
        textStyle: AppTextStyles.titleLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper2,
      border: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: const BorderSide(color: AppColors.crimson, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      labelStyle: AppTextStyles.bodyMedium,
      hintStyle: AppTextStyles.bodyMedium,
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      titleLarge: AppTextStyles.titleLarge,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.paper3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
      labelStyle: AppTextStyles.bodySmall,
      side: BorderSide.none,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.paper0,
      indicatorColor: AppColors.crimsonWash,
      labelTextStyle: WidgetStateProperty.all(AppTextStyles.labelLarge),
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.paper0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.paper0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetRadius),
      elevation: 0,
      titleTextStyle: AppTextStyles.headlineLarge,
      contentTextStyle: AppTextStyles.bodyLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink2,
      contentTextStyle: AppTextStyles.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
      behavior: SnackBarBehavior.floating,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: AppColors.paper2,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s2,
      ),
      titleTextStyle: AppTextStyles.bodyLarge,
      subtitleTextStyle: AppTextStyles.bodySmall,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.crimson,
      onPrimary: AppColorsDark.paper0,
      primaryContainer: AppColorsDark.crimsonWash,
      onPrimaryContainer: AppColorsDark.crimson,
      secondary: AppColorsDark.tea,
      onSecondary: AppColorsDark.paper0,
      secondaryContainer: AppColorsDark.teaWash,
      onSecondaryContainer: AppColorsDark.tea,
      surface: AppColorsDark.paper2,
      onSurface: AppColorsDark.ink1,
      surfaceContainerHighest: AppColorsDark.paper3,
      onSurfaceVariant: AppColorsDark.ink2,
      outline: AppColorsDark.hairline,
      outlineVariant: AppColorsDark.paper4,
      error: AppColors.error,
      onError: AppColors.paper0,
      errorContainer: AppColorsDark.errorWash,
      onErrorContainer: AppColorsDark.crimson,
      scrim: Color(0xCC000000),
    ),
    scaffoldBackgroundColor: AppColorsDark.paper1,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsDark.paper1,
      foregroundColor: AppColorsDark.ink1,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AppTextStyles.displayMedium.copyWith(
        color: AppColorsDark.ink1,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColorsDark.paper2,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        side: BorderSide(color: AppColorsDark.hairline),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.crimson,
        foregroundColor: AppColorsDark.paper0,
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        ),
        textStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColorsDark.paper0,
        ),
        elevation: 0,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(
        color: AppColorsDark.ink1,
      ),
      displayMedium: AppTextStyles.displayMedium.copyWith(
        color: AppColorsDark.ink1,
      ),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(
        color: AppColorsDark.ink1,
      ),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(
        color: AppColorsDark.ink1,
      ),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColorsDark.ink1),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColorsDark.ink1),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColorsDark.ink1),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColorsDark.ink3),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColorsDark.ink3),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColorsDark.hairline,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColorsDark.paper0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.paper3,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        borderSide: BorderSide(color: AppColorsDark.hairline),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        borderSide: BorderSide(color: AppColorsDark.hairline),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        borderSide: BorderSide(color: AppColorsDark.crimson, width: 1.5),
      ),
    ),
  );
}
