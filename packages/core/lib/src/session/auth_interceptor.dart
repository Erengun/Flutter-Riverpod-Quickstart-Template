import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../network/api_exception.dart';
import '../network/request_path.dart';
import '../reporting/error_reporter.dart';
import 'session.dart';

/// The `options.extra` flag that keeps the auth interceptor away from a
/// request: login, register and refresh set it through retrofit's
/// `@Extra(<String, Object>{skipAuthKey: true})`.
const String skipAuthKey = 'skipAuth';

// The access token the interceptor attached; only these requests are
// refreshed on a 401.
const String _sentTokenKey = 'core.auth.sentToken';

// Set on a replayed request, so its own 401 never refreshes again.
const String _replayedKey = 'core.auth.replayed';

/// Reported (non-fatal) when a request still gets a 401 with the access
/// token a refresh has just returned: a backend or configuration bug. The
/// user is then signed out.
class UnauthorizedAfterRefreshException implements Exception {
  const UnauthorizedAfterRefreshException(this.method, this.path);

  /// The HTTP method, upper case.
  final String method;

  /// The normalized request path.
  final String path;

  @override
  String toString() =>
      'UnauthorizedAfterRefreshException: 401 after a refresh '
      '($method $path)';
}

/// Adds `Authorization: Bearer <token>` to every request while signed in,
/// and refreshes the token on a 401.
///
/// The token is read per request, so the shared Dio never changes. Skips
/// requests marked with [skipAuthKey] and never replaces an
/// `Authorization` header the request already has.
///
/// On a 401 for a request it added the token to:
/// - When the request went out with an older token than the current one,
///   it is replayed with the current token, without a refresh.
/// - Otherwise one refresh runs (all failing requests share it) through the
///   hook `refreshHook` returns; on success `onRefreshed` saves the new
///   [Session] and each request is replayed once with the new token.
/// - No refresh hook, no refresh token, or a refresh rejected with 400 or
///   401: `onExpired` signs the user out once and the requests fail with
///   their 401 (`ApiException.unauthorized`).
/// - Any other refresh failure (no network, 5xx): the user stays signed in
///   and the requests fail with that error.
/// - A replayed request that still gets a 401 is reported once (non-fatal)
///   to `reporter`, then `onExpired` signs the user out.
///
/// Requests are replayed through the Dio it was last [attach]ed to;
/// `createDio` attaches it.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._session,
    this._refreshHook,
    this._onRefreshed,
    this._onExpired,
    this._reporter = const NoopErrorReporter(),
  });

  static final Logger _log = Logger('session');

  final Session? Function() _session;
  final RefreshHook? Function()? _refreshHook;
  final Future<void> Function(Session session)? _onRefreshed;
  final Future<void> Function()? _onExpired;
  final ErrorReporter _reporter;

  Dio? _dio;

  /// Replays requests through [dio] from now on.
  // ignore: use_setters_to_change_properties, it is not a property.
  void attach(Dio dio) => _dio = dio;

  Future<_RefreshOutcome>? _inFlight;
  Future<void>? _expiring;
  String? _reportedToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final bool hasHeader = options.headers.keys.any(
      (String name) => name.toLowerCase() == 'authorization',
    );
    if (options.extra[skipAuthKey] != true && !hasHeader) {
      final String? token = _session()?.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra[_sentTokenKey] = token;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions request = err.requestOptions;
    final Object? sent = request.extra[_sentTokenKey];
    // Only requests this interceptor authenticated: never the refresh call
    // itself (skipAuth) or a request with its own header (logout hook).
    if (err.response?.statusCode != 401 || sent is! String) {
      handler.next(err);
      return;
    }
    if (request.extra[_replayedKey] == true) {
      await _unauthorizedAfterReplay(request, sent);
      handler.next(err);
      return;
    }
    final Session? current = _session();
    if (current == null) {
      handler.next(err);
      return;
    }
    if (current.accessToken != sent) {
      // Someone else already refreshed (or signed in again).
      await _replay(request, current, handler);
      return;
    }
    final _RefreshOutcome outcome = await _refreshOnce(current);
    switch (outcome) {
      case _Refreshed(:final Session session):
        await _replay(request, session, handler);
      case _Rejected():
        handler.next(err);
      case _Failed(:final Object error, :final StackTrace stackTrace):
        // reject, not next: retry must not resend the stale token.
        handler.reject(_failure(error, stackTrace, request));
    }
  }

  Future<_RefreshOutcome> _refreshOnce(Session from) {
    final Future<_RefreshOutcome>? running = _inFlight;
    if (running != null) return running;
    final Future<_RefreshOutcome> started = _runRefresh(from);
    _inFlight = started;
    unawaited(
      started.whenComplete(() {
        if (identical(_inFlight, started)) _inFlight = null;
      }),
    );
    return started;
  }

  // Never throws: every waiter gets the same outcome.
  Future<_RefreshOutcome> _runRefresh(Session from) async {
    final RefreshHook? hook = _refreshHook?.call();
    final String? refreshToken = from.refreshToken;
    if (hook == null || refreshToken == null || refreshToken.isEmpty) {
      _log.info('401 with nothing to refresh; signing out.');
      await _expire(from);
      return const _Rejected();
    }
    final Session refreshed;
    try {
      refreshed = await hook(from);
    } catch (error, stackTrace) {
      if (_isRejection(error)) {
        _log.info('The refresh was rejected; signing out.');
        await _expire(from);
        return const _Rejected();
      }
      _log.info('The refresh failed; staying signed in.');
      return _Failed(error, stackTrace);
    }
    final Session? current = _session();
    if (current == null) return const _Rejected();
    if (current.accessToken != from.accessToken) {
      // Signed out and in again meanwhile: keep the newer session.
      return _Refreshed(current);
    }
    try {
      await _onRefreshed?.call(refreshed);
    } catch (error, stackTrace) {
      return _Failed(error, stackTrace);
    }
    return _Refreshed(refreshed);
  }

  Future<void> _replay(
    RequestOptions request,
    Session session,
    ErrorInterceptorHandler handler,
  ) async {
    final Dio? dio = _dio;
    if (dio == null) {
      handler.reject(
        DioException(
          requestOptions: request,
          error: StateError('AuthInterceptor has no Dio to replay with.'),
        ),
      );
      return;
    }
    final Object? data = request.data;
    final RequestOptions replay = request.copyWith(
      data: data is FormData ? data.clone() : data,
      headers: <String, dynamic>{
        for (final MapEntry<String, dynamic> header in request.headers.entries)
          if (header.key.toLowerCase() != 'authorization')
            header.key: header.value,
        'Authorization': 'Bearer ${session.accessToken}',
      },
      extra: <String, dynamic>{
        ...request.extra,
        _sentTokenKey: session.accessToken,
        _replayedKey: true,
      },
    );
    try {
      handler.resolve(await dio.fetch<dynamic>(replay));
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  Future<void> _unauthorizedAfterReplay(
    RequestOptions request,
    String sent,
  ) async {
    final Session? current = _session();
    if (current == null || current.accessToken != sent) return;
    if (_reportedToken != sent) {
      _reportedToken = sent;
      final String method = request.method.toUpperCase();
      final String path = normalizeRequestPath(request.uri);
      _reporter.report(
        UnauthorizedAfterRefreshException(method, path),
        StackTrace.current,
        groupKey: 'auth 401 after refresh',
        tags: <String, String>{'http.method': method, 'http.path': path},
      );
    }
    await _expire(current);
  }

  // Signs out once, and only if [from] is still the current session.
  Future<void> _expire(Session from) {
    final Future<void>? running = _expiring;
    if (running != null) return running;
    if (_session()?.accessToken != from.accessToken) {
      return Future<void>.value();
    }
    final Future<void> started = _runExpire();
    _expiring = started;
    unawaited(
      started.whenComplete(() {
        if (identical(_expiring, started)) _expiring = null;
      }),
    );
    return started;
  }

  Future<void> _runExpire() async {
    try {
      await _onExpired?.call();
    } catch (_) {
      _log.warning('Signing out after the session expired failed.');
    }
  }

  static bool _isRejection(Object error) {
    return switch (error) {
      ApiUnauthorizedException() => true,
      ApiServerException(:final int statusCode) => statusCode == 400,
      DioException(
        type: DioExceptionType.badResponse,
        :final Response<dynamic>? response,
      ) =>
        response?.statusCode == 400 || response?.statusCode == 401,
      _ => false,
    };
  }

  // The refresh's failure, reported against the waiting request.
  static DioException _failure(
    Object error,
    StackTrace stackTrace,
    RequestOptions request,
  ) {
    if (error is DioException) return error.copyWith(requestOptions: request);
    return DioException(
      requestOptions: request,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

sealed class _RefreshOutcome {
  const _RefreshOutcome();
}

final class _Refreshed extends _RefreshOutcome {
  const _Refreshed(this.session);

  final Session session;
}

final class _Rejected extends _RefreshOutcome {
  const _Rejected();
}

final class _Failed extends _RefreshOutcome {
  const _Failed(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// Core's [AuthInterceptor] over [sessionProvider] and the auth Feature's
/// [SessionHooks.refresh]. It is in `dioInterceptorsProvider`'s default
/// list, so it replays through `dioProvider`.
final Provider<AuthInterceptor> authInterceptorProvider =
    Provider<AuthInterceptor>((Ref ref) {
      return AuthInterceptor(
        session: () => ref.read(sessionProvider).value,
        // Read on a 401: the hook itself usually calls through dioProvider,
        // which is built from this interceptor.
        refreshHook: () => ref.read(sessionHooksProvider).refresh,
        onRefreshed: (Session session) =>
            ref.read(sessionProvider.notifier).updateTokens(session),
        onExpired: () => ref.read(sessionProvider.notifier).expire(),
        reporter: ref.watch(errorReporterProvider),
      );
    }, name: 'authInterceptorProvider');
