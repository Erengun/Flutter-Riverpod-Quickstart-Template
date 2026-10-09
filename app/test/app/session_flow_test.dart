import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/authentication/data/authentication_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_request.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_response.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/register_response.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_screen.dart';
import 'package:flutter_riverpod_template/features/home/presentation/home_screen.dart';
import 'package:flutter_riverpod_template/my_app.dart';
import 'package:flutter_riverpod_template/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
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

void main() {
  late TestStorage storage;

  setUp(() async {
    storage = await TestStorage.open();
  });

  tearDown(() => storage.close());

  /// Starts the app, as a cold start would, on the real router.
  Future<void> startApp(
    WidgetTester tester, {
    Future<Box<String>> Function()? openSession,
    bool settle = true,
  }) async {
    // Portrait (the app is locked to it), wide enough for the test font.
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    // A new key throws the previous ProviderScope away: a restart.
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: <Override>[
          ...storage.overridesWith(openSession: openSession),
          appConfigProvider.overrideWithValue(_config),
          authenticationRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    if (settle) await tester.pumpAndSettle();
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

  testWidgets('shows the splash while the session loads, then login', (
    WidgetTester tester,
  ) async {
    final Completer<Box<String>> opening = Completer<Box<String>>();
    await startApp(tester, openSession: () => opening.future, settle: false);
    await tester.pump();

    expect(find.byType(KonteynerSplash), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);

    opening.complete(storage.session);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(KonteynerSplash), findsNothing);
  });

  testWidgets('a signed-out user lands on login', (WidgetTester tester) async {
    await startApp(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(router(tester).state.uri.path, SGRoute.login.route);
  });

  testWidgets('a saved session goes straight to home', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(
      () => storage.session.put('accessToken', 'saved-token'),
    );

    await startApp(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('signing in replaces login with home and survives a restart', (
    WidgetTester tester,
  ) async {
    await startApp(tester);

    await signInThroughTheForm(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    // Login is not left underneath home.
    expect(router(tester).canPop(), isFalse);
    expect(storage.session.get('accessToken'), 'token-from-login');

    await startApp(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('logout goes to login and back cannot undo it', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(
      () => storage.session.put('accessToken', 'saved-token'),
    );
    await startApp(tester);

    await tester.tap(find.byIcon(Icons.logout_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(storage.session.isEmpty, isTrue);
    expect(router(tester).canPop(), isFalse);

    // The system back button has nothing to go back to.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);

    // Nor does opening home directly.
    router(tester).go(SGRoute.home.route);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // A restart stays signed out.
    await startApp(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('remember me pre-fills the form after logout', (
    WidgetTester tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await signInThroughTheForm(tester);

    await tester.tap(find.byIcon(Icons.logout_outlined));
    await tester.pumpAndSettle();

    expect(
      storage.credentials.get('credentials'),
      const LoginCredentials(
        email: 'eve.holt@reqres.in',
        password: 'cityslicka',
      ),
    );
    expect(find.text('eve.holt@reqres.in'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    // Pre-fill only: still signed out.
    expect(find.byType(HomeScreen), findsNothing);
  });
}
