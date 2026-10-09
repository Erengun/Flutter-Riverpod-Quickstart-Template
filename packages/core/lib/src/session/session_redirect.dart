import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';

/// Where the router sends the user for [session], or `null` to stay on
/// [location] (the path being opened). For go_router's `redirect`.
///
/// - While the session loads at startup: [splashPath].
/// - Signed out: [loginPath], unless [location] is the login page or in
///   [publicPaths]. A session that failed to load counts as signed out.
/// - Signed in: [homePath] from the login page and the splash.
String? sessionRedirect(
  AsyncValue<Session?> session,
  String location, {
  required String splashPath,
  required String loginPath,
  required String homePath,
  Set<String> publicPaths = const <String>{},
}) {
  if (!session.hasValue && !session.hasError) {
    return location == splashPath ? null : splashPath;
  }
  final bool signedIn = !session.hasError && session.value != null;
  if (!signedIn) {
    if (location == loginPath || publicPaths.contains(location)) return null;
    return loginPath;
  }
  if (location == loginPath || location == splashPath) return homePath;
  return null;
}

/// [sessionProvider]'s current value as a [Listenable], for go_router's
/// `refreshListenable`: the router re-runs its redirect whenever the
/// session changes (sign in, logout, startup load).
final Provider<ValueListenable<AsyncValue<Session?>>>
sessionListenableProvider = Provider<ValueListenable<AsyncValue<Session?>>>((
  Ref ref,
) {
  final ValueNotifier<AsyncValue<Session?>> notifier =
      ValueNotifier<AsyncValue<Session?>>(ref.read(sessionProvider));
  ref
    ..listen<AsyncValue<Session?>>(
      sessionProvider,
      (AsyncValue<Session?>? previous, AsyncValue<Session?> next) =>
          notifier.value = next,
    )
    ..onDispose(notifier.dispose);
  return notifier;
}, name: 'sessionListenableProvider');
