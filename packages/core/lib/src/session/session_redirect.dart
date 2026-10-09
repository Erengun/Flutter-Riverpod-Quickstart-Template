import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';

/// Where the router sends the user for [session], or `null` to stay on
/// [location] (the path being opened). For go_router's `redirect`.
///
/// - While the session loads at startup: [splashPath]. With [uri], the
///   location being opened goes along as `?from=`, so a deep link survives
///   the load.
/// - Signed out: [loginPath], unless [location] is the login page or in
///   [publicPaths]. A session that failed to load counts as signed out.
///   When the session [expired] (`sessionExpiredProvider`), the full
///   [uri] goes along as `?from=`, so signing in brings the user back.
/// - Signed in: from the splash, the `from` path inside the app its [uri]
///   carries, else [homePath]. While [holdOnSplash] is true (the app passes
///   "permissions not known yet"), a splash with such a `from` stays put
///   instead, so `permissionRedirect` can hold a guarded route there.
///   From the login page: [homePath], unless its [uri] carries a `from`
///   path inside the app.
///
/// [uri] is the full location being opened (go_router's `state.uri`).
String? sessionRedirect(
  AsyncValue<Session?> session,
  String location, {
  required String splashPath,
  required String loginPath,
  required String homePath,
  Set<String> publicPaths = const <String>{},
  Uri? uri,
  bool expired = false,
  bool holdOnSplash = false,
}) {
  if (!session.hasValue && !session.hasError) {
    if (location == splashPath) return null;
    return uri == null ? splashPath : splashWithFrom(splashPath, uri);
  }
  final bool signedIn = !session.hasError && session.value != null;
  if (!signedIn) {
    if (location == loginPath || publicPaths.contains(location)) return null;
    if (expired && uri != null && location != splashPath) {
      return Uri(
        path: loginPath,
        queryParameters: <String, String>{'from': uri.toString()},
      ).toString();
    }
    return loginPath;
  }
  if (location == splashPath || location == loginPath) {
    final String? from = uri?.queryParameters['from'];
    if (!_isReturnLocation(
      from,
      splashPath: splashPath,
      loginPath: loginPath,
    )) {
      return homePath;
    }
    return location == splashPath && holdOnSplash ? null : from;
  }
  return null;
}

/// [splashPath] carrying [uri] as `?from=`, unless [uri] is the splash
/// itself. `sessionRedirect` continues there once the splash is done.
String splashWithFrom(String splashPath, Uri uri) {
  if (uri.path == splashPath) return splashPath;
  return Uri(
    path: splashPath,
    queryParameters: <String, String>{'from': uri.toString()},
  ).toString();
}

// A path inside the app (not another host, not login or splash again).
// Backslashes are rejected because browsers read them as slashes, so
// `/\evil.example` would become the other-host `//evil.example`.
bool _isReturnLocation(
  String? from, {
  required String splashPath,
  required String loginPath,
}) {
  if (from == null ||
      !from.startsWith('/') ||
      from.startsWith('//') ||
      from.contains(r'\')) {
    return false;
  }
  final Uri? parsed = Uri.tryParse(from);
  if (parsed == null || parsed.hasScheme || parsed.hasAuthority) return false;
  return parsed.path != loginPath && parsed.path != splashPath;
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
