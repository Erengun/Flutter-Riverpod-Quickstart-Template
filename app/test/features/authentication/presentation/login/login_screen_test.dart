import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/fakes/fake_storage.dart';
import 'package:flutter_riverpod_template/features/authentication/data/authentication_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/fakes/fake_auth_repository.dart';
import 'package:flutter_riverpod_template/features/authentication/presentation/login/login_screen.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_riverpod_template/my_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// No store links, so force update stays off.
const AppConfig _config = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'https://example.com/',
  apiKey: '',
);

void main() {
  late FakeStorage storage;
  final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

  setUp(() async {
    storage = await FakeStorage.open();
  });

  tearDown(() => storage.close());

  /// Starts the app signed out, on the login screen.
  Future<void> startApp(
    WidgetTester tester,
    AuthenticationRepository repository,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...storage.overrides,
          appConfigProvider.overrideWithValue(_config),
          authenticationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  }

  Finder snackBarText(String text) =>
      find.descendant(of: find.byType(SnackBar), matching: find.text(text));

  group('a 401 from the login call', () {
    testWidgets("shows the backend's message", (WidgetTester tester) async {
      await startApp(
        tester,
        FakeAuthRepository(
          loginError: const ApiUnauthorizedException(
            message: 'Invalid password',
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'eve.holt@reqres.in',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.widgetWithText(TextButton, en.authLoginButton));
      await tester.pumpAndSettle();

      expect(snackBarText('Invalid password'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('without a message shows the login failure text', (
      WidgetTester tester,
    ) async {
      await startApp(
        tester,
        FakeAuthRepository(loginError: const ApiUnauthorizedException()),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'eve.holt@reqres.in',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.widgetWithText(TextButton, en.authLoginButton));
      await tester.pumpAndSettle();

      expect(snackBarText(en.authLoginFailed), findsOneWidget);
    });
  });

  group('submitting the password field with the keyboard', () {
    testWidgets('with an empty email shows a message and never calls login', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository(
        loginError: const ApiUnauthorizedException(),
      );
      await startApp(tester, repository);

      await tester.enterText(find.byType(TextFormField).at(1), 'cityslicka');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(snackBarText(en.authCredentialsRequired), findsOneWidget);
      expect(repository.logins, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with both fields filled logs in like the button', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository(
        loginError: const ApiUnauthorizedException(message: 'Invalid password'),
      );
      await startApp(tester, repository);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'eve.holt@reqres.in',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repository.logins, 1);
      expect(snackBarText('Invalid password'), findsOneWidget);
    });
  });

  testWidgets('with the language set to Turkish the form is in Turkish', (
    WidgetTester tester,
  ) async {
    final AppLocalizations tr = lookupAppLocalizations(const Locale('tr'));
    await tester.runAsync(() => storage.prefs.put('locale', 'tr'));
    await startApp(
      tester,
      FakeAuthRepository(loginError: const ApiUnauthorizedException()),
    );

    expect(find.text(tr.authWelcome), findsOneWidget);
    expect(find.text(tr.authPasswordLabel), findsOneWidget);
    expect(find.text(tr.authCreateAccount), findsOneWidget);
    expect(find.widgetWithText(TextButton, tr.authLoginButton), findsOneWidget);
    expect(find.text(en.authWelcome), findsNothing);
  });

  testWidgets('the empty-credentials check is localized', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository(
      loginError: const ApiUnauthorizedException(),
    );
    await startApp(tester, repository);

    await tester.tap(find.widgetWithText(TextButton, en.authLoginButton));
    await tester.pumpAndSettle();

    expect(snackBarText(en.authCredentialsRequired), findsOneWidget);
    expect(repository.logins, 0);
  });
}
