import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/fakes/fake_storage.dart';
import 'package:flutter_riverpod_template/features/authentication/data/demo_permissions.dart';
import 'package:flutter_riverpod_template/features/home/presentation/home_screen.dart';
import 'package:flutter_riverpod_template/features/home/presentation/widgets/component_rules_demo.dart';
import 'package:flutter_riverpod_template/features/home/presentation/widgets/language_tile.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_riverpod_template/my_app.dart';
import 'package:flutter_riverpod_template/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late FakeStorage storage;
  final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

  setUp(() async {
    storage = await FakeStorage.open();
    await storage.signIn();
  });

  tearDown(() => storage.close());

  /// Opens [HomeScreen] inside [MyApp], signed in with the demo
  /// permissions, so the theme and language switches reach `MaterialApp`.
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final GoRouter router = GoRouter(
      routes: <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...storage.overrides,
          goRouterProvider.overrideWithValue(router),
          sessionHooksProvider.overrideWithValue(
            const SessionHooks(loadPermissions: loadDemoPermissions),
          ),
          // No store links, so force update stays off.
          appConfigProvider.overrideWithValue(
            const AppConfig(
              flavor: Flavor.dev,
              apiBaseUrl: 'https://example.com/',
              apiKey: '',
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  MaterialApp materialApp(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp));

  testWidgets('shows the intro and the demo component rules', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    expect(find.text(en.homeIntro), findsOneWidget);
    expect(find.byType(ComponentRulesDemo), findsOneWidget);
    // The demo permissions: email is shown (readonly), delete account is
    // hidden.
    expect(find.text(en.demoEmailReadonly), findsOneWidget);
    expect(find.text(en.demoDeleteAccountHidden), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching the language updates the app and saves it', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(materialApp(tester).locale, const Locale('tr'));
    expect(find.text('Dili Değiştir'), findsOneWidget);
    expect(find.text('Temayı Değiştir'), findsOneWidget);
    expect(storage.prefs.get('locale'), 'tr');

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(materialApp(tester).locale, const Locale('en'));
    expect(find.text('Change Language'), findsOneWidget);
    expect(storage.prefs.get('locale'), 'en');
  });

  testWidgets('switching the theme mode updates the app and saves it', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    expect(materialApp(tester).themeMode, ThemeMode.system);

    await tester.tap(find.byIcon(Ionicons.moonOutline));
    await tester.pumpAndSettle();

    expect(materialApp(tester).themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(LanguageTile))).brightness,
      Brightness.dark,
    );
    expect(storage.prefs.get('themeMode'), 'dark');

    await tester.tap(find.byIcon(Ionicons.sunnyOutline));
    await tester.pumpAndSettle();

    expect(materialApp(tester).themeMode, ThemeMode.light);
    expect(storage.prefs.get('themeMode'), 'light');
  });

  testWidgets('the logout button signs out', (WidgetTester tester) async {
    await pumpHome(tester);
    expect(storage.session.get('accessToken'), FakeStorage.token);

    await tester.tap(find.byIcon(Icons.logout_outlined));
    await tester.pumpAndSettle();

    expect(storage.session.get('accessToken'), isNull);
  });
}
