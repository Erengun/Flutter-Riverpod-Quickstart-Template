import 'package:flutter_riverpod_template/my_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'app delegates resolve material_ui MaterialLocalizations for tr',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
          localizationsDelegates: appLocalizationsDelegates(
            const <LocalizationsDelegate<Object?>>[],
          ),
          home: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(SizedBox));
      final MaterialLocalizations localizations = MaterialLocalizations.of(
        context,
      );

      expect(localizations, isA<GlobalMaterialLocalizations>());
      expect(localizations.okButtonLabel, 'Tamam');
    },
  );
}
