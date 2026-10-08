import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('material_ui MaterialLocalizations resolve for Turkish', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: <Locale>[Locale('en'), Locale('tr')],
        localizationsDelegates: <LocalizationsDelegate<Object?>>[
          ...GlobalMaterialLocalizations.delegates,
        ],
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
  });
}
