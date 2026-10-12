import 'package:core/core.dart';
import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/app/theme.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_screen.dart';
import 'package:flutter_riverpod_template/features/home/presentation/home_screen.dart';
import 'package:flutter_riverpod_template/features/home/presentation/widgets/component_rules_demo.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_catalog/catalog/catalog_addons.dart';
import 'package:widgetbook_catalog/catalog/catalog_app.dart';
import 'package:widgetbook_catalog/main.directories.g.dart';

/// Every use case in the generated catalog, by `Component/use case`.
Map<String, WidgetbookUseCase> _useCases() {
  final Map<String, WidgetbookUseCase> found = <String, WidgetbookUseCase>{};
  void visit(WidgetbookNode node, String component) {
    if (node is WidgetbookUseCase) {
      found['$component/${node.name}'] = node;
      return;
    }
    for (final WidgetbookNode child in node.children ?? <WidgetbookNode>[]) {
      visit(child, node is WidgetbookComponent ? node.name : component);
    }
  }

  for (final WidgetbookNode node in directories) {
    visit(node, '');
  }
  return found;
}

const List<String> _apiErrorKinds = <String>[
  'connection',
  'timeout',
  'cancelled',
  'unauthorized',
  'forbidden',
  'notFound',
  'server',
  'business',
  'decode',
  'unknown',
];

void main() {
  // The theme starts loading the bundled fonts, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  final KonteynerTheme theme = buildAppTheme();
  final Map<String, WidgetbookUseCase> useCases = _useCases();
  final CoreLocalizations en = lookupCoreLocalizations(const Locale('en'));

  /// Builds a use case the way the catalog does: the locale addon's
  /// `Localizations` above [CatalogApp], which the theme addon adds.
  Future<void> pumpUseCase(
    WidgetTester tester,
    String name, {
    ThemeData? themeData,
    Locale locale = const Locale('en'),
  }) async {
    final WidgetbookUseCase? useCase = useCases[name];
    expect(useCase, isNotNull, reason: '$name is not in the catalog');
    // The catalog opens on a phone frame (iPhone 13).
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Localizations(
        locale: locale,
        delegates: appLocalizationsDelegates,
        child: CatalogApp(
          theme: themeData ?? theme.light,
          child: Builder(builder: useCase!.builder),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('catalog', () {
    test('has the required use cases', () {
      expect(
        useCases.keys,
        containsAll(<String>[
          'NoPermissionPage/Default',
          'UnderConstructionPage/Default',
          'KonteynerUpdateDialog/Blocking',
          'KonteynerUpdateDialog/Dismissible',
          for (final String kind in _apiErrorKinds) 'ApiErrorView/$kind',
          'PermissionGate/No rule',
          'PermissionGate/Hidden',
          'PermissionGate/Readonly',
          'PermissionGate/Disabled',
          'LoginScreen/Signed out',
          'LoginScreen/Remembered credentials',
          'LoginScreen/Login fails',
          'HomeScreen/Demo permissions',
        ]),
      );
    });

    test('addons: viewport, locale, text scale, accessibility, theme', () {
      final List<WidgetbookAddon<dynamic>> addons = catalogAddons(theme);

      final ViewportAddon viewport = addons.whereType<ViewportAddon>().single;
      expect(viewport.viewports.length, greaterThanOrEqualTo(3));

      final LocalizationAddon locale = addons
          .whereType<LocalizationAddon>()
          .single;
      expect(locale.locales, <Locale>[const Locale('en'), const Locale('tr')]);
      expect(locale.localizationsDelegates, appLocalizationsDelegates);

      expect(addons.whereType<TextScaleAddon>(), hasLength(1));
      expect(
        addons.whereType<BuilderAddon>().map(
          (BuilderAddon addon) => addon.name,
        ),
        contains('Accessibility'),
      );

      final ThemeAddon<ThemeData> themes = addons
          .whereType<ThemeAddon<ThemeData>>()
          .single;
      expect(
        themes.themes.map((WidgetbookTheme<ThemeData> t) => t.name),
        <String>['Light', 'Dark'],
      );
      expect(themes.themes.first.data, same(theme.light));
      expect(themes.themes.last.data, same(theme.dark));
      // The theme addon wraps the use case in CatalogApp, which reads the
      // locale addon's Localizations, so it must come after it.
      expect(addons.last, same(themes));
    });
  });

  group('every use case builds', () {
    for (final String name in _useCases().keys) {
      for (final Brightness brightness in Brightness.values) {
        for (final Locale locale in AppLocalizations.supportedLocales) {
          testWidgets('$name, ${brightness.name}, $locale', (
            WidgetTester tester,
          ) async {
            await pumpUseCase(
              tester,
              name,
              themeData: brightness == Brightness.light
                  ? theme.light
                  : theme.dark,
              locale: locale,
            );

            expect(tester.takeException(), isNull);
            expect(
              Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
              brightness,
            );
          });
        }
      }
    }
  });

  group('use cases', () {
    testWidgets('no-permission page shows Core strings', (
      WidgetTester tester,
    ) async {
      await pumpUseCase(tester, 'NoPermissionPage/Default');

      expect(find.text(en.noPermissionTitle), findsOneWidget);
    });

    testWidgets('blocking update dialog has only Update', (
      WidgetTester tester,
    ) async {
      await pumpUseCase(tester, 'KonteynerUpdateDialog/Blocking');

      expect(find.text(en.updateBodyRequired), findsOneWidget);
      expect(find.text(en.updateButtonUpdate), findsOneWidget);
      expect(find.text(en.updateButtonLater), findsNothing);
    });

    testWidgets('dismissible update dialog has Ignore and Later', (
      WidgetTester tester,
    ) async {
      await pumpUseCase(tester, 'KonteynerUpdateDialog/Dismissible');

      expect(find.text(en.updateBodyOptional), findsOneWidget);
      expect(find.text(en.updateButtonIgnore), findsOneWidget);
      expect(find.text(en.updateButtonLater), findsOneWidget);
    });

    testWidgets('an error kind shows its snackbar and error view', (
      WidgetTester tester,
    ) async {
      await pumpUseCase(tester, 'ApiErrorView/connection');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(en.errorConnection),
        ),
        findsOneWidget,
      );
      expect(find.byType(ApiErrorView), findsOneWidget);

      // Retry sends the failing request again: the snackbar comes back.
      await tester.tap(find.text(en.errorRetry));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('unauthorized and cancelled show no snackbar', (
      WidgetTester tester,
    ) async {
      await pumpUseCase(tester, 'ApiErrorView/unauthorized');
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(ApiErrorView), findsOneWidget);

      await pumpUseCase(tester, 'ApiErrorView/cancelled');
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('PermissionGate states', (WidgetTester tester) async {
      Finder control() => find.byKey(const ValueKey<String>('gated-control'));
      Finder absorbing() => find.ancestor(
        of: control(),
        matching: find.byType(AbsorbPointer),
      );

      await pumpUseCase(tester, 'PermissionGate/No rule');
      expect(control(), findsOneWidget);

      await pumpUseCase(tester, 'PermissionGate/Hidden');
      expect(control(), findsNothing);

      await pumpUseCase(tester, 'PermissionGate/Readonly');
      expect(control(), findsOneWidget);
      expect(
        find.ancestor(of: control(), matching: find.byType(ColorFiltered)),
        findsNothing,
      );
      expect(
        tester.widgetList<AbsorbPointer>(absorbing()).any(
          (AbsorbPointer a) => a.absorbing,
        ),
        isTrue,
      );

      await pumpUseCase(tester, 'PermissionGate/Disabled');
      expect(
        find.ancestor(of: control(), matching: find.byType(ColorFiltered)),
        findsOneWidget,
      );
    });

    testWidgets('login screen: signed out shows an empty form', (
      WidgetTester tester,
    ) async {
      await pumpUseCase(tester, 'LoginScreen/Signed out');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('eve.holt@reqres.in'), findsNothing);
    });

    testWidgets('login screen: remembered credentials pre-fill the form', (
      WidgetTester tester,
    ) async {
      await pumpUseCase(tester, 'LoginScreen/Remembered credentials');

      expect(find.text('eve.holt@reqres.in'), findsOneWidget);
    });

    testWidgets('login screen: a failed login shows the error snackbar', (
      WidgetTester tester,
    ) async {
      await pumpUseCase(tester, 'LoginScreen/Login fails');

      await tester.tap(find.widgetWithText(TextButton, 'Login'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('user not found'),
        ),
        findsOneWidget,
      );
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('home screen shows the demo component rules', (
      WidgetTester tester,
    ) async {
      await pumpUseCase(tester, 'HomeScreen/Demo permissions');

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ComponentRulesDemo), findsOneWidget);
      // The saved demo permissions apply: email is shown (readonly) and
      // delete account is hidden.
      final AppLocalizations l10n = lookupAppLocalizations(
        const Locale('en'),
      );
      expect(find.text(l10n.demoEmailReadonly), findsOneWidget);
      expect(find.text(l10n.demoDeleteAccountHidden), findsNothing);
    });
  });
}
