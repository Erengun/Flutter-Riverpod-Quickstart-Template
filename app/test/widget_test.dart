import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/fakes/fake_storage.dart';
import 'package:flutter_riverpod_template/features/home/presentation/widgets/language_tile.dart';
import 'package:flutter_riverpod_template/features/home/presentation/widgets/theme_widget.dart';
import 'package:flutter_riverpod_template/my_app.dart';
import 'package:flutter_riverpod_template/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('MyApp', () {
    late FakeStorage storage;

    setUp(() async {
      storage = await FakeStorage.open();
    });

    tearDown(() => storage.close());

    Future<void> pumpApp(WidgetTester tester) async {
      final GoRouter router = GoRouter(
        routes: <GoRoute>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(
                  body: Column(children: <Widget>[ThemeWidget(), LanguageTile()]),
                ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            ...storage.overrides,
            goRouterProvider.overrideWithValue(router),
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

    testWidgets('follows the device until the user picks a language', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      expect(materialApp(tester).locale, isNull);
      expect(materialApp(tester).supportedLocales, <Locale>[
        const Locale('en'),
        const Locale('tr'),
      ]);
      expect(find.text('Change Language'), findsOneWidget);
    });

    testWidgets('starts with the saved language and theme mode', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await storage.prefs.put('locale', 'tr');
        await storage.prefs.put('themeMode', 'dark');
      });

      await pumpApp(tester);

      expect(materialApp(tester).locale, const Locale('tr'));
      expect(materialApp(tester).themeMode, ThemeMode.dark);
      expect(find.text('Dili Değiştir'), findsOneWidget);
    });
  });
}
