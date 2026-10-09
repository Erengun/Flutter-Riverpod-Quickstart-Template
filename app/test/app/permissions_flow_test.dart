import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/authentication/data/authentication_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/data/demo_permissions.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_response.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/register_response.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_screen.dart';
import 'package:flutter_riverpod_template/features/demo/presentation/demo_area_screen.dart';
import 'package:flutter_riverpod_template/features/home/presentation/home_screen.dart';
import 'package:flutter_riverpod_template/my_app.dart';
import 'package:flutter_riverpod_template/router/app_router.dart';
import 'package:flutter_riverpod_template/shared/permission_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../support/storage.dart';

class _FakeAuthRepository implements AuthenticationRepository {
  @override
  Future<LoginResponse> login(String email, String password) async =>
      const LoginResponse(token: 'token-from-login');

  @override
  Future<RegisterResponse> register(String email, String password) async =>
      const RegisterResponse(id: 4, token: 'token-from-register');
}

/// No store links, so force update stays off.
const AppConfig _config = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'https://example.com/',
  apiKey: '',
);

final CoreLocalizations _core = lookupCoreLocalizations(const Locale('en'));

void main() {
  late TestStorage storage;
  late List<Session> loads;

  setUp(() async {
    storage = await TestStorage.open();
    loads = <Session>[];
  });

  tearDown(() => storage.close());

  /// The demo loader, counting its calls.
  Future<Permissions> demoLoader(Session session) {
    loads.add(session);
    return loadDemoPermissions(session);
  }

  /// Starts the app, as a cold start would, on the real router.
  Future<void> startApp(
    WidgetTester tester, {
    LoadPermissionsHook? loadPermissions,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: <Override>[
          ...storage.overrides,
          appConfigProvider.overrideWithValue(_config),
          authenticationRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(),
          ),
          sessionHooksProvider.overrideWithValue(
            SessionHooks(loadPermissions: loadPermissions ?? demoLoader),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  GoRouter router(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
          .read(goRouterProvider);

  Future<void> signInThroughTheForm(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'eve.holt@reqres.in',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'cityslicka');
    await tester.tap(find.widgetWithText(TextButton, 'Login'));
    await tester.pumpAndSettle();
  }

  Future<void> saveSignedIn(WidgetTester tester) => tester.runAsync(
    () => storage.session.putAll(<String, String>{
      'accessToken': 'saved-token',
      permissionsKey: const Permissions(
        areas: <String>{AppAreas.profile},
      ).encode(),
    }),
  );

  testWidgets('login fails with a message when permissions cannot load', (
    WidgetTester tester,
  ) async {
    await startApp(
      tester,
      loadPermissions: (Session session) async =>
          throw const ApiConnectionException(),
    );

    await signInThroughTheForm(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text(_core.errorConnection), findsOneWidget);
    expect(storage.session.get('accessToken'), isNull);
  });

  testWidgets('login loads the demo permissions; reports is left out', (
    WidgetTester tester,
  ) async {
    await startApp(tester);
    await signInThroughTheForm(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(loads, hasLength(1));

    await tester.tap(find.widgetWithText(ActionChip, 'Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(DemoAreaScreen), findsOneWidget);

    router(tester).go(SGRoute.home.route);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Reports'));
    await tester.pumpAndSettle();
    expect(find.byType(NoPermissionPage), findsOneWidget);
    expect(find.byType(DemoAreaScreen), findsNothing);

    await tester.tap(find.text(_core.pageBackHome));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    // Login was this launch's load.
    expect(loads, hasLength(1));
  });

  testWidgets('a direct link outside the areas opens the no-permission page', (
    WidgetTester tester,
  ) async {
    await saveSignedIn(tester);
    final Completer<Permissions> reload = Completer<Permissions>();
    await startApp(
      tester,
      loadPermissions: (Session session) {
        loads.add(session);
        return reload.future;
      },
    );

    // The saved list is used at once; one reload runs in the background.
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(loads, <Session>[const Session(accessToken: 'saved-token')]);

    router(tester).go(SGRoute.profile.route);
    await tester.pumpAndSettle();
    expect(find.byType(DemoAreaScreen), findsOneWidget);

    router(tester).go(SGRoute.settings.route);
    await tester.pumpAndSettle();
    expect(find.byType(NoPermissionPage), findsOneWidget);

    // The reload grants settings; the guard lets it through from now on.
    reload.complete(
      const Permissions(areas: <String>{AppAreas.profile, AppAreas.settings}),
    );
    await tester.pumpAndSettle();
    router(tester).go(SGRoute.settings.route);
    await tester.pumpAndSettle();
    expect(find.byType(DemoAreaScreen), findsOneWidget);

    router(tester).go(SGRoute.reports.route);
    await tester.pumpAndSettle();
    expect(find.byType(NoPermissionPage), findsOneWidget);
    expect(loads, hasLength(1));
  });

  testWidgets('logout deletes the saved permissions', (
    WidgetTester tester,
  ) async {
    await saveSignedIn(tester);
    await startApp(tester);

    await tester.tap(find.byIcon(Icons.logout_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(storage.session.get(permissionsKey), isNull);
  });
}
