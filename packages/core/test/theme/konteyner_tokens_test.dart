import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const KonteynerTokens _appTokens = KonteynerTokens(
  spaceXs: 2,
  spaceSm: 6,
  spaceMd: 12,
  spaceLg: 20,
  spaceXl: 40,
  radiusSm: 2,
  radiusMd: 6,
  radiusLg: 24,
  success: Color(0xFF00FF00),
  onSuccess: Color(0xFF000000),
  warning: Color(0xFFFFFF00),
  onWarning: Color(0xFF000001),
  info: Color(0xFF0000FF),
  onInfo: Color(0xFFFFFFFF),
);

Future<KonteynerTokens> _tokensIn(WidgetTester tester, ThemeData theme) async {
  late KonteynerTokens tokens;
  await tester.pumpWidget(
    Theme(
      data: theme,
      child: Builder(
        builder: (BuildContext context) {
          tokens = KonteynerTokens.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return tokens;
}

void main() {
  group('KonteynerTokens.of', () {
    testWidgets('falls back to the light defaults without the extension', (
      WidgetTester tester,
    ) async {
      final KonteynerTokens tokens = await _tokensIn(tester, ThemeData.light());

      expect(tokens, same(KonteynerTokens.fallbackLight));
    });

    testWidgets('falls back to the dark defaults in a dark theme', (
      WidgetTester tester,
    ) async {
      final KonteynerTokens tokens = await _tokensIn(tester, ThemeData.dark());

      expect(tokens, same(KonteynerTokens.fallbackDark));
    });

    testWidgets("returns the app's values when the theme sets them", (
      WidgetTester tester,
    ) async {
      final KonteynerTokens tokens = await _tokensIn(
        tester,
        ThemeData.light().copyWith(
          extensions: const <ThemeExtension<dynamic>>[_appTokens],
        ),
      );

      expect(tokens, same(_appTokens));
    });
  });

  test('the defaults differ between light and dark only in colors', () {
    const KonteynerTokens light = KonteynerTokens.fallbackLight;
    const KonteynerTokens dark = KonteynerTokens.fallbackDark;

    expect(
      <double>[
        light.spaceXs,
        light.spaceSm,
        light.spaceMd,
        light.spaceLg,
        light.spaceXl,
      ],
      <double>[4, 8, 16, 24, 32],
    );
    expect(
      <double>[light.radiusSm, light.radiusMd, light.radiusLg],
      <double>[4, 8, 16],
    );
    expect(dark.spaceMd, light.spaceMd);
    expect(dark.radiusMd, light.radiusMd);
    expect(dark.success, isNot(light.success));
  });

  test('copyWith replaces only the given values', () {
    final KonteynerTokens copy = KonteynerTokens.fallbackLight.copyWith(
      spaceMd: 18,
      info: const Color(0xFF123456),
    );

    expect(copy.spaceMd, 18);
    expect(copy.info, const Color(0xFF123456));
    expect(copy.spaceSm, KonteynerTokens.fallbackLight.spaceSm);
    expect(copy.onInfo, KonteynerTokens.fallbackLight.onInfo);
  });

  test('lerp interpolates every value', () {
    const KonteynerTokens a = KonteynerTokens.fallbackLight;
    const KonteynerTokens b = _appTokens;

    final KonteynerTokens start = a.lerp(b, 0);
    final KonteynerTokens end = a.lerp(b, 1);
    final KonteynerTokens middle = a.lerp(b, 0.5);

    expect(start.spaceXl, a.spaceXl);
    expect(start.success, a.success);
    expect(end.spaceXl, b.spaceXl);
    expect(end.radiusLg, b.radiusLg);
    expect(end.onWarning, b.onWarning);
    expect(middle.spaceXl, (a.spaceXl + b.spaceXl) / 2);
    expect(middle.radiusSm, (a.radiusSm + b.radiusSm) / 2);
    expect(middle.info, Color.lerp(a.info, b.info, 0.5));
  });

  test('lerp with another extension type returns this', () {
    expect(
      KonteynerTokens.fallbackLight.lerp(null, 0.5),
      same(KonteynerTokens.fallbackLight),
    );
  });
}
