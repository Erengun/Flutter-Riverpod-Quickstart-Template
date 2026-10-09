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
}
