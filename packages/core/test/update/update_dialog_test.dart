import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final CoreLocalizations en = lookupCoreLocalizations(const Locale('en'));
  final CoreLocalizations tr = lookupCoreLocalizations(const Locale('tr'));

  late List<String> pressed;

  setUp(() => pressed = <String>[]);

  Future<void> pumpDialog(
    WidgetTester tester, {
    required bool updateRequired,
    Locale locale = const Locale('en'),
    String? title,
    String? message,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          CoreLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: CoreLocalizations.supportedLocales,
        home: Scaffold(
          body: KonteynerUpdateDialog(
            updateRequired: updateRequired,
            title: title,
            message: message,
            onUpdate: () => pressed.add('update'),
            onIgnore: () => pressed.add('ignore'),
            onLater: () => pressed.add('later'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder button(String label) => find.widgetWithText(TextButton, label);

  testWidgets('hard update: the required body and only Update', (
    WidgetTester tester,
  ) async {
    await pumpDialog(tester, updateRequired: true);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(en.updateTitle), findsOneWidget);
    expect(find.text(en.updateBodyRequired), findsOneWidget);
    expect(button(en.updateButtonIgnore), findsNothing);
    expect(button(en.updateButtonLater), findsNothing);

    await tester.tap(button(en.updateButtonUpdate));
    expect(pressed, <String>['update']);
  });

  testWidgets('soft update: the optional body, Ignore, Later and Update', (
    WidgetTester tester,
  ) async {
    await pumpDialog(tester, updateRequired: false);

    expect(find.text(en.updateBodyOptional), findsOneWidget);

    await tester.tap(button(en.updateButtonIgnore));
    await tester.tap(button(en.updateButtonLater));
    await tester.tap(button(en.updateButtonUpdate));
    expect(pressed, <String>['ignore', 'later', 'update']);
  });

  testWidgets('reads Core strings in the current locale', (
    WidgetTester tester,
  ) async {
    await pumpDialog(tester, updateRequired: false, locale: const Locale('tr'));

    expect(find.text(tr.updateTitle), findsOneWidget);
    expect(find.text(tr.updateBodyOptional), findsOneWidget);
    expect(button(tr.updateButtonLater), findsOneWidget);
  });

  testWidgets('a given title and message replace the defaults', (
    WidgetTester tester,
  ) async {
    await pumpDialog(
      tester,
      updateRequired: true,
      title: 'Custom title',
      message: 'Custom message',
    );

    expect(find.text('Custom title'), findsOneWidget);
    expect(find.text('Custom message'), findsOneWidget);
    expect(find.text(en.updateTitle), findsNothing);
  });
}
