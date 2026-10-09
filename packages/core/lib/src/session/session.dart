import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:logging/logging.dart';

import '../reporting/error_reporter.dart';
import '../storage/encrypted_box.dart';

/// The signed-in user's tokens. Core never decodes or inspects them.
@immutable
class Session {
  const Session({required this.accessToken, this.refreshToken, this.userId});

  /// Sent as `Authorization: Bearer <accessToken>` by the auth interceptor.
  final String accessToken;

  /// Kept for the auth Feature's refresh hook; `null` when the backend has
  /// none.
  final String? refreshToken;

  /// Only used for `ErrorReporter.setUser`; `null` when the login response
  /// has no id.
  final String? userId;

  @override
  bool operator ==(Object other) =>
      other is Session &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, userId);

  // Never prints the tokens: a Session may end up in a log line.
  @override
  String toString() =>
      'Session(userId: $userId, refreshToken: '
      '${refreshToken == null ? 'none' : 'set'})';
}

/// Tells the backend the user signed out. Called without waiting, while
/// [Session] is already being cleared, so the request must carry the token
/// from the [Session] it receives itself (the auth interceptor never
/// replaces an `Authorization` header that is already set).
typedef LogoutHook = Future<void> Function(Session session);

/// Trades [Session.refreshToken] for new tokens and returns the new
/// [Session]. The auth interceptor calls it on a 401, one call at a time,
/// with the current [Session] (whose `refreshToken` is set).
///
/// The request must carry `@Extra(<String, Object>{skipAuthKey: true})`.
/// Throw when it fails: a 400 or 401 (as a `DioException`,
/// `ApiUnauthorizedException` or `ApiServerException` 400) signs the user
/// out; anything else (no network, 5xx) keeps them signed in. Copy
/// `refreshToken` and `userId` over from [session] when the backend doesn't
/// send them again.
typedef RefreshHook = Future<Session> Function(Session session);

/// The backend-specific calls the auth Feature gives Core. Every hook is
/// optional.
@immutable
class SessionHooks {
  const SessionHooks({this.logout, this.refresh});

  final LogoutHook? logout;

  /// Without it, or without a refresh token, a 401 signs the user out.
  final RefreshHook? refresh;
}

/// Whether the user was signed out because the session expired (a rejected
/// refresh, or a 401 with nothing to refresh). The router then sends them to
/// `/login?from=<location>` and the login screen shows
/// `CoreLocalizations.authSessionExpired`. The next sign-in clears it.
final NotifierProvider<SessionExpiredNotifier, bool> sessionExpiredProvider =
    NotifierProvider<SessionExpiredNotifier, bool>(
      SessionExpiredNotifier.new,
      name: 'sessionExpiredProvider',
    );

class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marks the session as expired. [SessionNotifier.expire] calls it.
  void mark() => state = true;

  /// Forgets the expiry. [SessionNotifier.signIn] calls it.
  void clear() => state = false;
}

/// The auth Feature's [SessionHooks]. None by default; the app overrides it
/// through `bootstrap(overrides: ...)`.
final Provider<SessionHooks> sessionHooksProvider = Provider<SessionHooks>(
  (Ref ref) => const SessionHooks(),
  name: 'sessionHooksProvider',
);

/// Name of the encrypted Hive box holding the [Session]. Core owns it.
const String sessionBoxName = 'session';

const String _accessTokenKey = 'accessToken';
const String _refreshTokenKey = 'refreshToken';
const String _userIdKey = 'userId';

/// The encrypted session box, opened with `openEncryptedBox`. Tests
/// override it with a box of their own.
final FutureProvider<Box<String>> sessionBoxProvider =
    FutureProvider<Box<String>>(
      (Ref ref) => openEncryptedBox<String>(sessionBoxName),
      name: 'sessionBoxProvider',
    );

/// The current [Session]: `null` when signed out, loading while the box
/// opens at startup. It survives restarts.
///
/// Every provider that holds user data watches it, so it rebuilds on sign
/// out.
final AsyncNotifierProvider<SessionNotifier, Session?> sessionProvider =
    AsyncNotifierProvider<SessionNotifier, Session?>(
      SessionNotifier.new,
      name: 'sessionProvider',
    );

class SessionNotifier extends AsyncNotifier<Session?> {
  static final Logger _log = Logger('session');

  @override
  Future<Session?> build() async {
    final Box<String> box = await ref.watch(sessionBoxProvider.future);
    final String? accessToken = box.get(_accessTokenKey);
    if (accessToken == null || accessToken.isEmpty) return null;
    return Session(
      accessToken: accessToken,
      refreshToken: box.get(_refreshTokenKey),
      userId: box.get(_userIdKey),
    );
  }

  /// Saves [session] and signs in. Sets the reporter user when
  /// [Session.userId] is given.
  Future<void> signIn(Session session) async {
    await _save(session);
    state = AsyncData<Session?>(session);
    ref.read(sessionExpiredProvider.notifier).clear();
    if (session.userId case final String id) {
      ref.read(errorReporterProvider).setUser(id);
    }
    _log.info('Signed in.');
  }

  /// Replaces the tokens after a successful refresh; the auth interceptor
  /// calls it. Does nothing while signed out. A failed save is logged and
  /// the new tokens are used anyway.
  Future<void> updateTokens(Session session) async {
    if (state.value == null) return;
    state = AsyncData<Session?>(session);
    try {
      await _save(session);
    } catch (_) {
      // Never log the error itself: it may quote the tokens.
      _log.warning('The refreshed tokens could not be saved.');
    }
    _log.fine('Tokens refreshed.');
  }

  Future<void> _save(Session session) async {
    final Box<String> box = await ref.read(sessionBoxProvider.future);
    await box.putAll(<String, String>{
      _accessTokenKey: session.accessToken,
      if (session.refreshToken case final String token) _refreshTokenKey: token,
      if (session.userId case final String id) _userIdKey: id,
    });
    await box.deleteAll(<String>[
      if (session.refreshToken == null) _refreshTokenKey,
      if (session.userId == null) _userIdKey,
    ]);
  }

  /// Signs out: calls the logout hook without waiting for it, clears the
  /// tokens whatever the hook does, and clears the reporter user.
  Future<void> logout() => _signOut(callHook: true);

  /// Signs out because the session expired; the auth interceptor calls it.
  /// Marks [sessionExpiredProvider] before the session changes (so the
  /// router's redirect sees it) and skips the logout hook: the backend has
  /// already rejected the tokens. Does nothing while signed out.
  Future<void> expire() async {
    if (state.value == null) return;
    ref.read(sessionExpiredProvider.notifier).mark();
    _log.info('The session expired.');
    await _signOut(callHook: false);
  }

  Future<void> _signOut({required bool callHook}) async {
    final Session? current = state.value;
    final LogoutHook? hook = callHook
        ? ref.read(sessionHooksProvider).logout
        : null;
    if (current != null && hook != null) {
      unawaited(
        Future<void>.sync(() => hook(current)).catchError((Object _) {
          _log.info('The logout call failed; signed out locally anyway.');
        }),
      );
    }
    try {
      final Box<String> box = await ref.read(sessionBoxProvider.future);
      await box.clear();
    } catch (_) {
      // Tokens left on disk would sign the user back in after a restart.
      _log.warning('The session box could not be cleared; deleting it.');
      try {
        await Hive.deleteBoxFromDisk(sessionBoxName);
        // The provider still holds the deleted, closed box; reopen it.
        ref.invalidate(sessionBoxProvider);
      } catch (error, stackTrace) {
        // Never log the error itself: it may quote the box's contents.
        _log.severe('The session box could not be deleted.');
        ref.read(errorReporterProvider).report(error, stackTrace);
      }
    } finally {
      state = const AsyncData<Session?>(null);
      ref.read(errorReporterProvider).setUser(null);
      _log.info('Signed out.');
    }
  }
}
