import 'package:material_ui/material_ui.dart';

// The app's design tokens: raw values only, written by hand.
//
// Only lib/app/theme.dart may import this file (the konteyner_lints rule
// tokens_only_in_theme). The theme turns these values into light and dark
// ThemeData and theme extensions; widgets read them through
// Theme.of(context), and Core through KonteynerTokens.of(context).

/// Scheme colors, passed to FlexColorScheme. The starting values are
/// FlexColorScheme's "Deep blue sea" scheme.
abstract final class AppColors {
  static const Color lightPrimary = Color(0xFF223A5E);
  static const Color lightPrimaryContainer = Color(0xFF97BAEA);
  static const Color lightSecondary = Color(0xFF144955);
  static const Color lightSecondaryContainer = Color(0xFFA9EDFF);
  static const Color lightTertiary = Color(0xFF208399);
  static const Color lightTertiaryContainer = Color(0xFFCCF3FF);
  static const Color lightAppBar = lightTertiary;
  static const Color lightError = Color(0xFFB00020);

  static const Color darkPrimary = Color(0xFF748BAC);
  static const Color darkPrimaryContainer = Color(0xFF1B2E4B);
  static const Color darkSecondary = Color(0xFF539EAF);
  static const Color darkSecondaryContainer = Color(0xFF004E5D);
  static const Color darkTertiary = Color(0xFF219AB5);
  static const Color darkTertiaryContainer = Color(0xFF0F5B6A);
  static const Color darkAppBar = darkTertiary;
  static const Color darkError = Color(0xFFCF6679);
}

/// Status colors and their "on" colors, which ColorScheme has no slot for.
abstract final class AppStatusColors {
  static const Color lightSuccess = Color(0xFF2E7D32);
  static const Color lightOnSuccess = Color(0xFFFFFFFF);
  static const Color lightWarning = Color(0xFF8A5100);
  static const Color lightOnWarning = Color(0xFFFFFFFF);
  static const Color lightInfo = Color(0xFF1B6C80);
  static const Color lightOnInfo = Color(0xFFFFFFFF);

  static const Color darkSuccess = Color(0xFF81C784);
  static const Color darkOnSuccess = Color(0xFF003909);
  static const Color darkWarning = Color(0xFFFFB86E);
  static const Color darkOnWarning = Color(0xFF4A2800);
  static const Color darkInfo = Color(0xFF8ED0E4);
  static const Color darkOnInfo = Color(0xFF00363F);
}

/// Spacing scale, in logical pixels.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radii, in logical pixels.
abstract final class AppRadii {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
}

/// The font family and the type scale (Material 3 sizes as the starting
/// point).
///
/// The family is loaded with google_fonts from the files bundled in
/// `assets/fonts/` (`<Family>-<Weight>.ttf`, such as `Nunito-Medium.ttf`).
/// Every weight used below needs its file there, because runtime fetching is
/// off.
abstract final class AppTypography {
  static const String fontFamily = 'Nunito';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    height: 64 / 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    height: 52 / 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}
