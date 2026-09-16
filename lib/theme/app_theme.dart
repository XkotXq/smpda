import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'app_colors.dart';

/// Mirrors WPS's `app/globals.css` `:root` / `.dark` tokens field-for-field
/// (see AppColors for where each hex comes from) so this app's ShadThemeData
/// reads the same as the web dashboard's Tailwind theme - same navy accent,
/// same neutral surfaces, same 10px-ish base radius (`--radius: 0.625rem`).
class AppTheme {
  AppTheme._();

  static final light = ShadThemeData(
    brightness: Brightness.light,
    radius: const BorderRadius.all(Radius.circular(10)),
    colorScheme: const ShadColorScheme(
      background: Color(0xFFFFFFFF),
      foreground: AppColors.neutral950,
      card: Color(0xFFFFFFFF),
      cardForeground: AppColors.neutral950,
      popover: Color(0xFFFFFFFF),
      popoverForeground: AppColors.neutral950,
      primary: AppColors.navy950,
      primaryForeground: AppColors.neutral50,
      secondary: AppColors.neutral100,
      secondaryForeground: AppColors.neutral900,
      muted: AppColors.neutral100,
      mutedForeground: AppColors.neutral500,
      accent: AppColors.navy50,
      accentForeground: AppColors.navy950,
      destructive: AppColors.destructiveLight,
      destructiveForeground: AppColors.neutral50,
      border: AppColors.neutral200,
      input: AppColors.neutral200,
      ring: AppColors.navy700,
      selection: AppColors.navy300,
    ),
  );

  static final dark = ShadThemeData(
    brightness: Brightness.dark,
    radius: const BorderRadius.all(Radius.circular(10)),
    colorScheme: const ShadColorScheme(
      background: AppColors.neutral950,
      foreground: AppColors.neutral50,
      card: AppColors.neutral900,
      cardForeground: AppColors.neutral50,
      popover: AppColors.neutral900,
      popoverForeground: AppColors.neutral50,
      primary: AppColors.navy500,
      primaryForeground: AppColors.neutral50,
      secondary: AppColors.neutral800,
      secondaryForeground: AppColors.neutral50,
      muted: AppColors.neutral800,
      mutedForeground: AppColors.neutral400,
      accent: AppColors.neutral800,
      accentForeground: AppColors.neutral50,
      destructive: AppColors.destructiveDark,
      destructiveForeground: AppColors.neutral950,
      border: Color(0x1AFFFFFF), // white 10% - matches oklch(1 0 0 / 10%)
      input: Color(0x26FFFFFF), // white 15% - matches oklch(1 0 0 / 15%)
      ring: AppColors.navy500,
      selection: AppColors.navy700,
    ),
  );
}
