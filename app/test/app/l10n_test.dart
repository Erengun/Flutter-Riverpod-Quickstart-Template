import 'package:core/core.dart';
import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('every delegate supports every app locale', () {
    for (final LocalizationsDelegate<Object?> delegate
        in appLocalizationsDelegates) {
      for (final Locale locale in AppLocalizations.supportedLocales) {
        expect(
          delegate.isSupported(locale),
          isTrue,
          reason: '${delegate.runtimeType} does not support $locale',
        );
      }
    }
  });

  test('English is the first (fallback) app locale', () {
    expect(AppLocalizations.supportedLocales.first, const Locale('en'));
  });

  testWidgets(
    'app delegates resolve material_ui MaterialLocalizations for tr',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(SizedBox));
      final MaterialLocalizations localizations = MaterialLocalizations.of(
        context,
      );

      expect(localizations, isA<GlobalMaterialLocalizations>());
      expect(localizations.okButtonLabel, 'Tamam');
      expect(CoreLocalizations.of(context).errorNoPermission, isNotEmpty);
    },
  );
}
