import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/fakes/fake_remote_flags.dart';
import 'package:flutter_riverpod_template/fakes/fake_storage.dart';
import 'package:flutter_riverpod_template/my_app.dart';
import 'package:flutter_riverpod_template/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const AppConfig _listedConfig = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'https://example.com/',
  apiKey: '',
  storeLinks: StoreLinks(appStoreId: '123456'),
);

const AppConfig _unlistedConfig = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'https://example.com/',
  apiKey: '',
);

const String _home = 'home page';
const String _splash = 'splash page';

/// Every test runs as iOS with the installed version 1.0.0.
final TargetPlatformVariant _ios = TargetPlatformVariant.only(
  TargetPlatform.iOS,
);

void main() {
  late FakeStorage storage;
  late FakeRemoteFlags flags;
  final CoreLocalizations en = lookupCoreLocalizations(const Locale('en'));

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PackageInfo.setMockInitialValues(
      appName: 'Template',
      packageName: 'com.example.template',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    storage = await FakeStorage.open();
    flags = FakeRemoteFlags();
  });

  tearDown(() async {
    await flags.close();
    await storage.close();
  });

  /// upgrader opens the dialog from a zero-delay timer, which
  /// `pumpAndSettle` alone does not wait for.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    AppConfig config = _listedConfig,
    GoRouter? router,
    List<Override> overrides = const <Override>[],
  }) async {
    final GoRouter appRouter =
        router ??
        GoRouter(
          routes: <GoRoute>[
            GoRoute(
              path: '/',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(body: Text(_home)),
            ),
          ],
        );
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...storage.overrides,
          goRouterProvider.overrideWithValue(appRouter),
          appConfigProvider.overrideWithValue(config),
          remoteFlagsProvider.overrideWithValue(flags),
          ...overrides,
        ],
        child: const MyApp(),
      ),
    );
    await settle(tester);
  }

  Finder button(String label) => find.widgetWithText(TextButton, label);

  /// A router that starts on a splash page and replaces it with home once
  /// [ready] is true, like the app's session redirect.
  GoRouter splashRouter(ValueNotifier<bool> ready) => GoRouter(
    initialLocation: '/splash',
    refreshListenable: ready,
    redirect: (BuildContext context, GoRouterState state) {
      if (!ready.value) return '/splash';
      return state.matchedLocation == '/splash' ? '/home' : null;
    },
    routes: <GoRoute>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text(_splash)),
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text(_home)),
      ),
    ],
  );

  /// Sends the app to the background and back.
  void backgroundAndResume(WidgetTester tester) {
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  testWidgets('hard update: only Update, and the dialog cannot be dismissed', (
    WidgetTester tester,
  ) async {
    flags.values['app_min_version_ios'] = '1.1.0';

    await pumpApp(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(en.updateTitle), findsOneWidget);
    expect(find.text(en.updateBodyRequired), findsOneWidget);
    expect(button(en.updateButtonUpdate), findsOneWidget);
    expect(button(en.updateButtonIgnore), findsNothing);
    expect(button(en.updateButtonLater), findsNothing);

    // An outside tap and the back button do nothing.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  }, variant: _ios);

  testWidgets(
    'hard update: the dialog stays when a redirect replaces the page below it',
    (WidgetTester tester) async {
      flags.values['app_min_version_ios'] = '1.1.0';
      final ValueNotifier<bool> ready = ValueNotifier<bool>(false);
      addTearDown(ready.dispose);

      await pumpApp(tester, router: splashRouter(ready));
      expect(find.text(_splash), findsOneWidget);
      expect(find.text(en.updateBodyRequired), findsOneWidget);

      ready.value = true;
      await settle(tester);

      expect(find.text(_home), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(en.updateBodyRequired), findsOneWidget);

      // A later check finds the dialog already open and adds no second one.
      flags.change(<String, String>{'app_min_version_ios': '1.2.0'});
      await settle(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
    },
    variant: _ios,
  );

  testWidgets(
    'resume refreshes RemoteFlags and applies a newly fetched minimum',
    (WidgetTester tester) async {
      await pumpApp(tester);
      expect(flags.refreshCount, 1);
      expect(find.byType(AlertDialog), findsNothing);

      flags.nextFetch = <String, String>{'app_min_version_ios': '1.1.0'};
      backgroundAndResume(tester);
      await settle(tester);

      expect(flags.refreshCount, 2);
      expect(find.text(en.updateBodyRequired), findsOneWidget);
    },
    variant: _ios,
  );

  testWidgets(
    "a slow lookup from before a resume refresh can't overwrite the newer one",
    (WidgetTester tester) async {
      // Reads the flags when called, like the default source, but answers only
      // when the test releases it while [hold] is set.
      final AppVersionSource cached = remoteFlagsAppVersionSource(flags);
      final List<Completer<void>> gates = <Completer<void>>[];
      bool hold = false;
      Future<AppVersionConstraints> source(CorePlatform platform) async {
        final AppVersionConstraints read = await cached(platform);
        if (hold) {
          final Completer<void> gate = Completer<void>();
          gates.add(gate);
          await gate.future;
        }
        return read;
      }

      await pumpApp(
        tester,
        overrides: <Override>[
          appVersionSourceProvider.overrideWithValue(source),
        ],
      );
      expect(find.byType(AlertDialog), findsNothing);

      hold = true;
      flags
        ..nextFetch = <String, String>{'app_min_version_ios': '1.1.0'}
        ..refreshGate = Completer<void>();
      backgroundAndResume(tester);
      await tester.pump();
      // The resume check has read the old cached values; now the fetch lands.
      flags.refreshGate!.complete();
      await tester.pump();
      // Answer the newest lookup first and the older cached one last, as a
      // slow first lookup would, until none is waiting.
      while (gates.isNotEmpty) {
        final List<Completer<void>> waiting = gates.reversed.toList();
        gates.clear();
        for (final Completer<void> gate in waiting) {
          gate.complete();
        }
        await tester.pump();
      }
      await settle(tester);

      expect(find.text(en.updateBodyRequired), findsOneWidget);
    },
    variant: _ios,
  );

  testWidgets('soft update: Update, Ignore and Later; Later closes it', (
    WidgetTester tester,
  ) async {
    flags.values['app_recommended_version_ios'] = '1.0.1';

    await pumpApp(tester);

    expect(find.text(en.updateBodyOptional), findsOneWidget);
    expect(button(en.updateButtonUpdate), findsOneWidget);
    expect(button(en.updateButtonIgnore), findsOneWidget);
    expect(button(en.updateButtonLater), findsOneWidget);

    await tester.tap(button(en.updateButtonLater));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(_home), findsOneWidget);
  }, variant: _ios);

  testWidgets('soft update: Ignore silences that version', (
    WidgetTester tester,
  ) async {
    flags.values['app_recommended_version_ios'] = '1.0.1';
    await pumpApp(tester);

    await tester.tap(button(en.updateButtonIgnore));
    await tester.pumpAndSettle();
    flags.change(<String, String>{'app_recommended_version_ios': '1.0.1'});
    await settle(tester);

    expect(find.byType(AlertDialog), findsNothing);
  }, variant: _ios);

  testWidgets('no constraint: no dialog, and a background refresh starts', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(_home), findsOneWidget);
    expect(flags.refreshCount, 1);
  }, variant: _ios);

  testWidgets('installed version at the minimum and recommended: no dialog', (
    WidgetTester tester,
  ) async {
    flags.values
      ..['app_min_version_ios'] = '1.0.0'
      ..['app_recommended_version_ios'] = '1.0.0';

    await pumpApp(tester);

    expect(find.byType(AlertDialog), findsNothing);
  }, variant: _ios);

  testWidgets("only the running platform's keys count", (
    WidgetTester tester,
  ) async {
    flags.values['app_min_version_android'] = '9.0.0';

    await pumpApp(tester);

    expect(find.byType(AlertDialog), findsNothing);
  }, variant: _ios);

  testWidgets('an empty store link means no check', (
    WidgetTester tester,
  ) async {
    flags.values['app_min_version_ios'] = '9.0.0';

    await pumpApp(tester, config: _unlistedConfig);

    expect(find.byType(AlertDialog), findsNothing);
    expect(flags.refreshCount, 0);
  }, variant: _ios);

  testWidgets('a minimum raised mid-session applies on onChanged', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(AlertDialog), findsNothing);

    flags.change(<String, String>{'app_min_version_ios': '2.0.0'});
    await settle(tester);

    expect(find.text(en.updateBodyRequired), findsOneWidget);
    expect(button(en.updateButtonLater), findsNothing);
  }, variant: _ios);

  testWidgets("the dialog follows the app's language", (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => storage.prefs.put('locale', 'tr'));
    flags.values['app_recommended_version_ios'] = '1.0.1';

    await pumpApp(tester);

    final CoreLocalizations tr = lookupCoreLocalizations(const Locale('tr'));
    expect(find.text(tr.updateTitle), findsOneWidget);
    expect(button(tr.updateButtonUpdate), findsOneWidget);
  }, variant: _ios);

  testWidgets("the dialog follows the app's theme", (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => storage.prefs.put('themeMode', 'dark'));
    flags.values['app_recommended_version_ios'] = '1.0.1';

    await pumpApp(tester);

    final BuildContext dialog = tester.element(find.byType(AlertDialog));
    expect(Theme.of(dialog).brightness, Brightness.dark);
  }, variant: _ios);
}
