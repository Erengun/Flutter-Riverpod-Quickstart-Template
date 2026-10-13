import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_riverpod_template/app/theme.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// `DESIGN.md` (Google Stitch format, at the repo root) starts with a YAML
/// frontmatter of design tokens that this test generates from the built
/// theme: the hand-set scheme colors, Core's status colors, spacing, radii
/// and the type scale. The prose below it is written by hand.
///
/// The test fails when the committed frontmatter differs from the theme.
/// With `--update-goldens` (`dart run melos run design:update`) it rewrites
/// the frontmatter instead and keeps the prose. Paths are relative to `app/`,
/// where `flutter test` runs.
void main() {
  // The theme starts loading the bundled fonts, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DESIGN.md frontmatter matches the theme', () {
    final File file = File('../DESIGN.md');
    final String content = file.readAsStringSync();
    final String expected = designFrontmatter(
      buildAppTheme(),
      name: lookupAppLocalizations(const Locale('en')).appTitle,
    );

    if (autoUpdateGoldenFiles) {
      file.writeAsStringSync(withFrontmatter(content, expected));
      return;
    }
    expect(
      frontmatterOf(content),
      expected,
      reason:
          'DESIGN.md is out of date with the theme. Run '
          '`dart run melos run design:update` and commit the result.',
    );
  });

  test('names the font family, not the google_fonts variant', () {
    final String frontmatter = designFrontmatter(buildAppTheme(), name: 'App');

    expect(frontmatter, contains('    fontFamily: Roboto\n'));
    expect(frontmatter, isNot(contains('Roboto_')));
  });

  group('withFrontmatter', () {
    const String frontmatter = '---\nname: New\n---\n';

    test('replaces the frontmatter and keeps the prose', () {
      expect(
        withFrontmatter(
          '---\nname: Old\n---\n\n# Design\n\nProse.\n',
          frontmatter,
        ),
        '---\nname: New\n---\n\n# Design\n\nProse.\n',
      );
    });

    test('adds a frontmatter to a file without one', () {
      expect(
        withFrontmatter('# Design\n\nProse.\n', frontmatter),
        '---\nname: New\n---\n\n# Design\n\nProse.\n',
      );
    });
  });
}

/// The frontmatter block of [content], both `---` lines included, or `null`
/// when it has none.
String? frontmatterOf(String content) {
  if (!content.startsWith('---\n')) return null;
  final int end = content.indexOf('\n---\n', 3);
  return end == -1 ? null : content.substring(0, end + 5);
}

/// [content] with its frontmatter replaced by (or prefixed with)
/// [frontmatter], followed by one blank line and the unchanged prose.
String withFrontmatter(String content, String frontmatter) {
  final String? current = frontmatterOf(content);
  final String prose = content
      .substring(current?.length ?? 0)
      .replaceFirst(RegExp(r'^\n+'), '');
  return '$frontmatter\n$prose';
}

/// The DESIGN.md frontmatter for [theme].
///
/// Light colors use the plain role names; dark ones add `-dark`. Only the
/// colors the app's tokens set by hand are listed (the scheme's primary,
/// secondary, tertiary, their containers and error, plus [CoreTokens]' status
/// colors), not the roles FlexColorScheme derives from them, which move with
/// its releases.
String designFrontmatter(CoreTheme theme, {required String name}) {
  final StringBuffer out = StringBuffer()
    ..writeln('---')
    ..writeln('version: alpha')
    ..writeln('name: ${jsonEncode(name)}')
    ..writeln('colors:');
  for (final (ThemeData data, String suffix) in <(ThemeData, String)>[
    (theme.light, ''),
    (theme.dark, '-dark'),
  ]) {
    final ColorScheme scheme = data.colorScheme;
    final CoreTokens tokens = data.extension<CoreTokens>()!;
    for (final MapEntry<String, Color> color in <String, Color>{
      'primary': scheme.primary,
      'primary-container': scheme.primaryContainer,
      'secondary': scheme.secondary,
      'secondary-container': scheme.secondaryContainer,
      'tertiary': scheme.tertiary,
      'tertiary-container': scheme.tertiaryContainer,
      'error': scheme.error,
      'success': tokens.success,
      'on-success': tokens.onSuccess,
      'warning': tokens.warning,
      'on-warning': tokens.onWarning,
      'info': tokens.info,
      'on-info': tokens.onInfo,
    }.entries) {
      out.writeln('  ${color.key}$suffix: "${_hex(color.value)}"');
    }
  }

  final TextTheme text = theme.light.textTheme;
  out.writeln('typography:');
  for (final MapEntry<String, TextStyle?> level in <String, TextStyle?>{
    'display-lg': text.displayLarge,
    'display-md': text.displayMedium,
    'display-sm': text.displaySmall,
    'headline-lg': text.headlineLarge,
    'headline-md': text.headlineMedium,
    'headline-sm': text.headlineSmall,
    'title-lg': text.titleLarge,
    'title-md': text.titleMedium,
    'title-sm': text.titleSmall,
    'body-lg': text.bodyLarge,
    'body-md': text.bodyMedium,
    'body-sm': text.bodySmall,
    'label-lg': text.labelLarge,
    'label-md': text.labelMedium,
    'label-sm': text.labelSmall,
  }.entries) {
    final TextStyle style = level.value!;
    final double size = style.fontSize!;
    out
      ..writeln('  ${level.key}:')
      ..writeln('    fontFamily: ${_familyName(style.fontFamily!)}')
      ..writeln('    fontSize: ${_px(size)}')
      ..writeln('    fontWeight: ${style.fontWeight!.value}')
      ..writeln('    lineHeight: ${_px(size * style.height!)}')
      ..writeln('    letterSpacing: ${_px(style.letterSpacing!)}');
  }

  final CoreTokens tokens = theme.light.extension<CoreTokens>()!;
  out
    ..writeln('rounded:')
    ..writeln('  sm: ${_px(tokens.radiusSm)}')
    ..writeln('  md: ${_px(tokens.radiusMd)}')
    ..writeln('  lg: ${_px(tokens.radiusLg)}')
    ..writeln('spacing:')
    ..writeln('  xs: ${_px(tokens.spaceXs)}')
    ..writeln('  sm: ${_px(tokens.spaceSm)}')
    ..writeln('  md: ${_px(tokens.spaceMd)}')
    ..writeln('  lg: ${_px(tokens.spaceLg)}')
    ..writeln('  xl: ${_px(tokens.spaceXl)}')
    ..writeln('---');
  return out.toString();
}

/// `#rrggbb`, or `#rrggbbaa` when [color] is not opaque.
String _hex(Color color) {
  final int argb = color.toARGB32();
  final String rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  final int alpha = argb >>> 24;
  return alpha == 0xFF
      ? '#$rgb'
      : '#$rgb${alpha.toRadixString(16).padLeft(2, '0')}';
}

/// [value] logical pixels as a CSS-style dimension, at most two decimals.
String _px(double value) {
  final String fixed = value.toStringAsFixed(2);
  final String trimmed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  return '${trimmed == '-0' ? '0' : trimmed}px';
}

/// The family name behind google_fonts' `<Family>_<variant>` font names
/// (`Roboto_regular`, `Roboto_500`, `Roboto_700italic`).
String _familyName(String fontFamily) {
  return fontFamily.replaceFirst(
    RegExp(r'_(regular|italic|\d+(italic)?)$'),
    '',
  );
}
