import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows Core strings and leaves through the button', (
    WidgetTester tester,
  ) async {
    final CoreLocalizations en = lookupCoreLocalizations(const Locale('en'));
    int backHome = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          CoreLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: CoreLocalizations.supportedLocales,
        home: NoPermissionPage(onBackHome: () => backHome++),
      ),
    );

    expect(find.text(en.noPermissionTitle), findsOneWidget);
    expect(find.text(en.noPermissionBody), findsOneWidget);

    await tester.tap(find.text(en.pageBackHome));
    expect(backHome, 1);
  });
}
