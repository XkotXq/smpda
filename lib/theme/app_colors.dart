import 'package:flutter/widgets.dart';

/// Same palette as WPS's `app/globals.css` (Tailwind `@theme` tokens) -
/// kept as plain Dart constants (not derived from oklch at runtime) so this
/// file is a direct, checkable mirror of the web app's own hex values
/// rather than a re-implementation of Tailwind's oklch->sRGB conversion.
class AppColors {
  AppColors._();

  // --color-navy-50..950
  static const navy50 = Color(0xFFEEF2FB);
  static const navy100 = Color(0xFFDDE6F7);
  static const navy200 = Color(0xFFC3D1EE);
  static const navy300 = Color(0xFFA0B8E4);
  static const navy400 = Color(0xFF7495D6);
  static const navy500 = Color(0xFF4D76C9);
  static const navy600 = Color(0xFF3960BD);
  static const navy700 = Color(0xFF22406E);
  static const navy800 = Color(0xFF1C2F56);
  static const navy900 = Color(0xFF17264A);
  static const navy950 = Color(0xFF12213F);

  // Tailwind neutral-50..950 - WPS's dark-mode surfaces/borders/text
  // (dark:bg-neutral-900, dark:border-neutral-700, dark:text-neutral-400,
  // etc. throughout components/SmMaterialsPanel.js) are all this scale.
  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral400 = Color(0xFFA3A3A3);
  static const neutral500 = Color(0xFF737373);
  static const neutral600 = Color(0xFF525252);
  static const neutral700 = Color(0xFF404040);
  static const neutral800 = Color(0xFF262626);
  static const neutral900 = Color(0xFF171717);
  static const neutral950 = Color(0xFF0A0A0A);

  // --destructive (red-600/red-400) - the same red used for required-field
  // asterisks and invalid-cell highlighting in WPS.
  static const destructiveLight = Color(0xFFDC2626);
  static const destructiveDark = Color(0xFFF87171);
}
