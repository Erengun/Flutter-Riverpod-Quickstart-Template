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
    String? at(
      AsyncValue<Session?> session,
      String location, {
      bool? expired,
      bool holdOnSplash = false,
    }) {
      final Uri uri = Uri.parse(location);
      return sessionRedirect(
        session,
        uri.path,
        splashPath: '/splash',
        loginPath: '/login',
        homePath: '/home',
        uri: uri,
        expired: expired ?? false,
        holdOnSplash: holdOnSplash,
      );
    }

    /// The splash carrying [from], as the redirects build it.
    String splashFrom(String from) => Uri(
      path: '/splash',
      queryParameters: <String, String>{'from': from},
    ).toString();

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

    test('a deep link opened while the session loads waits on the splash', () {
      expect(
        at(loading, '/orders/7?tab=items'),
        '/splash?from=%2Forders%2F7%3Ftab%3Ditems',
      );
      expect(at(loading, splashFrom('/orders')), isNull);
      expect(at(loading, '/splash'), isNull);
    });

    test('the splash continues to from once signed in', () {
      expect(
        at(signedIn, splashFrom('/orders/7?tab=items')),
        '/orders/7?tab=items',
      );
      expect(at(signedIn, '/splash'), '/home');
    });

    test('holdOnSplash keeps a pending from on the splash', () {
      expect(at(signedIn, splashFrom('/orders'), holdOnSplash: true), isNull);
      // Without a from there is nothing to wait for.
      expect(at(signedIn, '/splash', holdOnSplash: true), '/home');
      // Only the splash holds; other pages are left to the next guard.
      expect(at(signedIn, '/orders', holdOnSplash: true), isNull);
      expect(
        at(signedIn, '/login?from=%2Forders', holdOnSplash: true),
        '/orders',
      );
    });

    test('a signed-out user on a splash with a from goes to plain login', () {
      expect(at(signedOut, splashFrom('/orders')), '/login');
      expect(at(signedOut, splashFrom('/orders'), expired: true), '/login');
    });

    test('the splash ignores a from outside the app, even while holding', () {
      for (final String from in <String>[
        'https://evil.example',
        '//evil.example/x',
        r'/\evil.example',
        r'/orders\..\x',
        'orders',
        '/login',
        '/splash',
        '',
      ]) {
        expect(at(signedIn, splashFrom(from)), '/home', reason: from);
        expect(
          at(signedIn, splashFrom(from), holdOnSplash: true),
          '/home',
          reason: from,
        );
      }
    });
  });
}
