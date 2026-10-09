import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/features/home/presentation/widgets/language_tile.dart';
import 'package:flutter_riverpod_template/features/home/presentation/widgets/theme_widget.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_riverpod_template/my_app.dart';
import 'package:flutter_riverpod_template/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:ionicons/ionicons.dart';
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

  group('MyApp', () {
    late Box<String> box;

    // An in-memory box: a file-backed box's writes never finish inside the
    // widget tests' fake async zone.
    setUp(() async {
      box = await Hive.openBox<String>(prefsBoxName, bytes: Uint8List(0));
    });

    tearDown(() => box.close());

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
            prefsBoxProvider.overrideWithValue(box),
            goRouterProvider.overrideWithValue(router),
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

    testWidgets('switching the language updates the app and saves it', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(materialApp(tester).locale, const Locale('tr'));
      expect(find.text('Dili Değiştir'), findsOneWidget);
      expect(find.text('Temayı Değiştir'), findsOneWidget);
      expect(box.get('locale'), 'tr');

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(materialApp(tester).locale, const Locale('en'));
      expect(find.text('Change Language'), findsOneWidget);
      expect(box.get('locale'), 'en');
    });

    testWidgets('switching the theme mode updates the app and saves it', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      expect(materialApp(tester).themeMode, ThemeMode.system);

      await tester.tap(find.byIcon(Ionicons.moonOutline));
      await tester.pumpAndSettle();

      expect(materialApp(tester).themeMode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(LanguageTile))).brightness,
        Brightness.dark,
      );
      expect(box.get('themeMode'), 'dark');

      await tester.tap(find.byIcon(Ionicons.sunnyOutline));
      await tester.pumpAndSettle();

      expect(materialApp(tester).themeMode, ThemeMode.light);
      expect(box.get('themeMode'), 'light');
    });

    testWidgets('starts with the saved language and theme mode', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await box.put('locale', 'tr');
        await box.put('themeMode', 'dark');
      });

      await pumpApp(tester);

      expect(materialApp(tester).locale, const Locale('tr'));
      expect(materialApp(tester).themeMode, ThemeMode.dark);
      expect(find.text('Dili Değiştir'), findsOneWidget);
    });
  });
}
