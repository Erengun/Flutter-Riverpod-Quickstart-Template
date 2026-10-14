import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/app/theme.dart';
import 'package:flutter_riverpod_template/features/demo/presentation/demo_area_screen.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_riverpod_template/shared/permission_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // The theme starts loading the bundled fonts, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  final ThemeData theme = buildAppTheme().light;

  Future<void> pumpScreen(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: const DemoAreaScreen(title: 'Orders', area: AppAreas.orders),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the title and names the area it is guarded by', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const Locale('en'));

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Orders')),
      findsOneWidget,
    );
    final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
    expect(find.text(en.demoAreaBody(AppAreas.orders)), findsOneWidget);
  });

  testWidgets('shows the body in the app language', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const Locale('tr'));

    final AppLocalizations tr = lookupAppLocalizations(const Locale('tr'));
    expect(find.text(tr.demoAreaBody(AppAreas.orders)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
