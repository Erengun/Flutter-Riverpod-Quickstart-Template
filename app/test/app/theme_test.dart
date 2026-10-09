import 'package:core/core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod_template/app/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildAppTheme', () {
    late KonteynerTheme theme;

    setUpAll(() {
      theme = buildAppTheme();
    });

    test('keeps the deep blue scheme for light and dark', () {
      expect(theme.light.brightness, Brightness.light);
      expect(theme.dark.brightness, Brightness.dark);
      expect(theme.light.colorScheme.primary, FlexColor.deepBlueLightPrimary);
      expect(theme.dark.colorScheme.primary, FlexColor.deepBlueDarkPrimary);
      expect(
        theme.light.colorScheme.secondary,
        FlexColor.deepBlueLightSecondary,
      );
      expect(theme.dark.colorScheme.tertiary, FlexColor.deepBlueDarkTertiary);
    });

    test('fills KonteynerTokens for light and dark', () {
      final KonteynerTokens? light = theme.light.extension<KonteynerTokens>();
      final KonteynerTokens? dark = theme.dark.extension<KonteynerTokens>();

      expect(light, isNotNull);
      expect(dark, isNotNull);
      expect(light!.spaceMd, dark!.spaceMd);
      expect(light.success, isNot(dark.success));
      expect(light.onInfo, isNot(dark.onInfo));
    });

    test('uses the bundled font for every text style', () {
      for (final ThemeData data in <ThemeData>[theme.light, theme.dark]) {
        final TextTheme text = data.textTheme;
        for (final TextStyle? style in <TextStyle?>[
          text.displayLarge,
          text.headlineMedium,
          text.titleMedium,
          text.bodyMedium,
          text.labelSmall,
        ]) {
          // google_fonts names each loaded family `<Family>_<variant>`, unlike
          // Flutter's default plain 'Roboto'.
          expect(style?.fontFamily, startsWith('Roboto_'));
        }
      }
    });

    test('turns off runtime font fetching', () {
      expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
    });

    testWidgets('loads every font it uses from the app assets', (
      WidgetTester tester,
    ) async {
      // Builds the theme again so this test awaits the loads itself: a font
      // that failed earlier is retried. With runtime fetching off, a missing
      // bundled file makes pendingFonts throw.
      await tester.runAsync(() async {
        buildAppTheme();
        await GoogleFonts.pendingFonts();
      });
    });

    testWidgets('registers the font license', (WidgetTester tester) async {
      final List<LicenseEntry> entries = (await tester.runAsync(
        () => LicenseRegistry.licenses.toList(),
      ))!;
      final Iterable<LicenseEntry> roboto = entries.where(
        (LicenseEntry entry) => entry.packages.contains('Roboto'),
      );

      expect(roboto, hasLength(1));
      final String text = roboto.single.paragraphs
          .map((LicenseParagraph p) => p.text)
          .join();
      expect(text, contains('The Roboto Project Authors'));
      expect(text, contains('SIL Open Font License'));
    });
  });
}
