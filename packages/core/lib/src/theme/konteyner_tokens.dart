import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// Design tokens Core's screens need that `ThemeData` has no slot for: a
/// spacing scale, radii, and status colors with their "on" colors.
///
/// The app fills light and dark values in `lib/app/theme.dart` and adds them
/// to its `ThemeData.extensions`. Core reads them only through [of], which
/// falls back to [fallbackLight] / [fallbackDark] when the app hasn't set
/// them, so Core never hardcodes a size or color.
class KonteynerTokens extends ThemeExtension<KonteynerTokens> {
  const KonteynerTokens({
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
  });

  /// Core's defaults for a light theme.
  static const KonteynerTokens fallbackLight = KonteynerTokens(
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 16,
    spaceLg: 24,
    spaceXl: 32,
    radiusSm: 4,
    radiusMd: 8,
    radiusLg: 16,
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF8A5100),
    onWarning: Color(0xFFFFFFFF),
    info: Color(0xFF0061A4),
    onInfo: Color(0xFFFFFFFF),
  );

  /// Core's defaults for a dark theme. Same sizes as [fallbackLight].
  static const KonteynerTokens fallbackDark = KonteynerTokens(
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 16,
    spaceLg: 24,
    spaceXl: 32,
    radiusSm: 4,
    radiusMd: 8,
    radiusLg: 16,
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF003909),
    warning: Color(0xFFFFB86E),
    onWarning: Color(0xFF4A2800),
    info: Color(0xFF9ECAFF),
    onInfo: Color(0xFF003258),
  );

  /// The tokens of the nearest `Theme`, or Core's defaults for its
  /// brightness when the app hasn't added a [KonteynerTokens] extension.
  static KonteynerTokens of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.extension<KonteynerTokens>() ??
        (theme.brightness == Brightness.dark ? fallbackDark : fallbackLight);
  }

  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;

  @override
  KonteynerTokens copyWith({
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
  }) {
    return KonteynerTokens(
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
    );
  }

  @override
  KonteynerTokens lerp(ThemeExtension<KonteynerTokens>? other, double t) {
    if (other is! KonteynerTokens) return this;
    return KonteynerTokens(
      spaceXs: lerpDouble(spaceXs, other.spaceXs, t)!,
      spaceSm: lerpDouble(spaceSm, other.spaceSm, t)!,
      spaceMd: lerpDouble(spaceMd, other.spaceMd, t)!,
      spaceLg: lerpDouble(spaceLg, other.spaceLg, t)!,
      spaceXl: lerpDouble(spaceXl, other.spaceXl, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}
