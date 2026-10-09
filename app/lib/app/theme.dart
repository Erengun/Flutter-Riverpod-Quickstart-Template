import 'package:core/core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// The app's light and dark themes, passed to `bootstrap`.
///
/// The only reader of `tokens.dart`: it turns the raw tokens into
/// FlexColorScheme `ThemeData` and the theme extensions (Core's
/// [KonteynerTokens], plus any the app adds next to it).
///
/// It also sets up the bundled fonts first: runtime fetching is turned off
/// before any google_fonts text style starts loading, and the fonts' license
/// is registered.
KonteynerTheme buildAppTheme() {
  _setUpFonts();
  final TextTheme textTheme = _textTheme();
  return KonteynerTheme(
    light: FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: AppColors.lightPrimary,
        primaryContainer: AppColors.lightPrimaryContainer,
        primaryLightRef: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        secondaryContainer: AppColors.lightSecondaryContainer,
        secondaryLightRef: AppColors.lightSecondary,
        tertiary: AppColors.lightTertiary,
        tertiaryContainer: AppColors.lightTertiaryContainer,
        tertiaryLightRef: AppColors.lightTertiary,
        appBarColor: AppColors.lightAppBar,
        error: AppColors.lightError,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        useM2StyleDividerInM3: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      swapLegacyOnMaterial3: true,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[
        KonteynerTokens(
          spaceXs: AppSpacing.xs,
          spaceSm: AppSpacing.sm,
          spaceMd: AppSpacing.md,
          spaceLg: AppSpacing.lg,
          spaceXl: AppSpacing.xl,
          radiusSm: AppRadii.sm,
          radiusMd: AppRadii.md,
          radiusLg: AppRadii.lg,
          success: AppStatusColors.lightSuccess,
          onSuccess: AppStatusColors.lightOnSuccess,
          warning: AppStatusColors.lightWarning,
          onWarning: AppStatusColors.lightOnWarning,
          info: AppStatusColors.lightInfo,
          onInfo: AppStatusColors.lightOnInfo,
        ),
      ],
    ),
    dark: FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: AppColors.darkPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        primaryLightRef: AppColors.lightPrimary,
        secondary: AppColors.darkSecondary,
        secondaryContainer: AppColors.darkSecondaryContainer,
        secondaryLightRef: AppColors.lightSecondary,
        tertiary: AppColors.darkTertiary,
        tertiaryContainer: AppColors.darkTertiaryContainer,
        tertiaryLightRef: AppColors.lightTertiary,
        appBarColor: AppColors.darkAppBar,
        error: AppColors.darkError,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useM2StyleDividerInM3: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      swapLegacyOnMaterial3: true,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[
        KonteynerTokens(
          spaceXs: AppSpacing.xs,
          spaceSm: AppSpacing.sm,
          spaceMd: AppSpacing.md,
          spaceLg: AppSpacing.lg,
          spaceXl: AppSpacing.xl,
          radiusSm: AppRadii.sm,
          radiusMd: AppRadii.md,
          radiusLg: AppRadii.lg,
          success: AppStatusColors.darkSuccess,
          onSuccess: AppStatusColors.darkOnSuccess,
          warning: AppStatusColors.darkWarning,
          onWarning: AppStatusColors.darkOnWarning,
          info: AppStatusColors.darkInfo,
          onInfo: AppStatusColors.darkOnInfo,
        ),
      ],
    ),
  );
}

/// The type scale from the tokens in the token font family.
///
/// google_fonts 9 returns material_ui's `TextTheme`, the type FlexColorScheme
/// 9 expects, so no conversion is needed. FlexColorScheme fills in the colors.
TextTheme _textTheme() {
  return GoogleFonts.getTextTheme(
    AppTypography.fontFamily,
    const TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      displaySmall: AppTypography.displaySmall,
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      titleSmall: AppTypography.titleSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    ),
  );
}

/// Where the bundled fonts' license lives (declared under `assets:`).
const String _fontLicenseAsset = 'assets/fonts/OFL.txt';

bool _fontLicenseRegistered = false;

/// Loads fonts only from the files bundled in `assets/fonts/`, never from
/// Google's servers, and registers their license (OFL) once, as the
/// google_fonts README asks for bundled files.
void _setUpFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
  if (_fontLicenseRegistered) return;
  _fontLicenseRegistered = true;
  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString(_fontLicenseAsset);
    yield LicenseEntryWithLineBreaks(<String>[
      AppTypography.fontFamily,
    ], license);
  });
}
