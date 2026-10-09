import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? redirect(
    AsyncValue<Session?> session,
    String location, {
    Set<String> publicPaths = const <String>{},
  }) => sessionRedirect(
    session,
    location,
    splashPath: '/splash',
    loginPath: '/login',
    homePath: '/home',
    publicPaths: publicPaths,
  );

  const AsyncValue<Session?> loading = AsyncLoading<Session?>();
  const AsyncValue<Session?> signedOut = AsyncData<Session?>(null);
  const AsyncValue<Session?> signedIn = AsyncData<Session?>(
    Session(accessToken: 'abc'),
  );

  test('shows the splash while the session loads', () {
    expect(redirect(loading, '/home'), '/splash');
    expect(redirect(loading, '/login'), '/splash');
    expect(redirect(loading, '/splash'), isNull);
  });

  test('sends a signed-out user to login', () {
    expect(redirect(signedOut, '/splash'), '/login');
    expect(redirect(signedOut, '/home'), '/login');
    expect(redirect(signedOut, '/login'), isNull);
  });

  test('lets a signed-out user open public paths', () {
    expect(
      redirect(signedOut, '/about', publicPaths: <String>{'/about'}),
      null,
    );
  });

  test('treats a session that failed to load as signed out', () {
    final AsyncValue<Session?> failed = AsyncError<Session?>(
      StateError('box'),
      StackTrace.empty,
    );
    expect(redirect(failed, '/home'), '/login');
    expect(redirect(failed, '/login'), isNull);
  });

  test('sends a signed-in user from login and splash to home', () {
    expect(redirect(signedIn, '/splash'), '/home');
    expect(redirect(signedIn, '/login'), '/home');
    expect(redirect(signedIn, '/home'), isNull);
    expect(redirect(signedIn, '/profile'), isNull);
  });

  group('return location', () {
    String? at(AsyncValue<Session?> session, String location, {bool? expired}) {
      final Uri uri = Uri.parse(location);
      return sessionRedirect(
        session,
        uri.path,
        splashPath: '/splash',
        loginPath: '/login',
        homePath: '/home',
        uri: uri,
        expired: expired ?? false,
      );
    }

    test('an expired session keeps where the user was', () {
      expect(
        at(signedOut, '/orders/7?tab=items', expired: true),
        '/login?from=%2Forders%2F7%3Ftab%3Ditems',
      );
      expect(at(signedOut, '/home', expired: true), '/login?from=%2Fhome');
    });

    test('a plain logout or cold start does not', () {
      expect(at(signedOut, '/orders/7'), '/login');
      expect(at(signedOut, '/splash', expired: true), '/login');
    });

    test('the login page with a from stays put while signed out', () {
      expect(at(signedOut, '/login?from=%2Forders', expired: true), isNull);
    });

    test('signing in returns to from', () {
      expect(
        at(signedIn, '/login?from=%2Forders%2F7%3Ftab%3Ditems'),
        '/orders/7?tab=items',
      );
    });

    test('signing in ignores a from outside the app', () {
      for (final String from in <String>[
        'https://evil.example',
        '//evil.example/x',
        r'/\evil.example',
        r'/\\evil.example/x',
        r'/orders\..\x',
        'orders',
        '/login',
        '/splash',
        '',
      ]) {
        final String location = Uri(
          path: '/login',
          queryParameters: <String, String>{'from': from},
        ).toString();
        expect(at(signedIn, location), '/home', reason: from);
      }
    });
  });
}
