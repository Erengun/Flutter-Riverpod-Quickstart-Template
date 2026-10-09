import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../config/app_config.dart';
import '../reporting/error_reporter.dart';
import '../session/auth_interceptor.dart';
import 'request_path.dart';

/// Core's Dio timeouts. Any single request can override them through its
/// `Options`. On web, Dio's browser adapter combines connect and receive
/// into one request timeout.
const Duration dioConnectTimeout = Duration(seconds: 10);
const Duration dioSendTimeout = Duration(seconds: 30);
const Duration dioReceiveTimeout = Duration(seconds: 30);

/// How many times a failed idempotent request is retried (so at most four
/// requests in total).
const int dioRetries = 3;

/// The wait before each retry.
const List<Duration> dioRetryDelays = <Duration>[
  Duration(seconds: 1),
  Duration(seconds: 3),
  Duration(seconds: 5),
];

/// The methods retried on failure. POST and PATCH are never retried: the
/// first attempt may have reached the server.
const Set<String> idempotentMethods = <String>{
  'GET',
  'HEAD',
  'PUT',
  'DELETE',
  'OPTIONS',
};

/// The request headers the logging interceptor never prints.
const Set<String> redactedHeaders = <String>{'authorization', 'x-api-key'};

/// Builds a [Dio] with Core's full setup: [baseUrl], the timeouts above and
/// these interceptors, in order:
///
/// 1. [interceptors]: the app's extras (such as a token/refresh
///    interceptor). They run before retry, so a 401 triggers a refresh, not
///    retries.
/// 2. A breadcrumb per request to [reporter]: method, path, status and
///    duration. Never headers, bodies or query values.
/// 3. Retry ([dioRetries] times) on connection errors, 408, 429 and 5xx,
///    for [idempotentMethods] only.
/// 4. When [logRequests] is set (dev and staging), a log of every request
///    to `Logger('network')` at `FINE`, with [redactedHeaders] hidden.
///
/// [headers] are sent with every request (the demo `x-api-key`). There is no
/// global `Content-Type`: Dio sets it per request.
///
/// [dioProvider] is `createDio(config.apiBaseUrl, ...)`. A client for another
/// host builds its own Dio with this function; nothing changes the shared
/// one.
Dio createDio(
  String baseUrl, {
  ErrorReporter reporter = const NoopErrorReporter(),
  List<Interceptor> interceptors = const <Interceptor>[],
  Map<String, String> headers = const <String, String>{},
  bool logRequests = false,
  @visibleForTesting List<Duration> retryDelays = dioRetryDelays,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: dioConnectTimeout,
      sendTimeout: dioSendTimeout,
      receiveTimeout: dioReceiveTimeout,
      headers: <String, Object?>{'Accept': 'application/json', ...headers},
    ),
  );
  dio.interceptors.addAll(<Interceptor>[
    ...interceptors,
    BreadcrumbInterceptor(reporter),
    RetryInterceptor(
      dio: dio,
      retryDelays: retryDelays,
      retryEvaluator: shouldRetryRequest,
    ),
    if (logRequests) const RedactedLogInterceptor(),
  ]);
  return dio;
}

/// Core's retry rule: an idempotent request that failed with a connection
/// error (including a connect timeout), 408, 429 or 5xx.
bool shouldRetryRequest(DioException error, int attempt) {
  if (!idempotentMethods.contains(error.requestOptions.method.toUpperCase())) {
    return false;
  }
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
      return true;
    case DioExceptionType.badResponse:
      final int? status = error.response?.statusCode;
      if (status == null) return false;
      return status == 408 || status == 429 || (status >= 500 && status < 600);
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return false;
  }
}

/// Extra interceptors placed first in [dioProvider]'s chain, before
/// breadcrumb and retry. Defaults to Core's auth interceptor alone
/// ([authInterceptorProvider]). An app that overrides it to add its own
/// keeps `ref.watch(authInterceptorProvider)` in the list.
final Provider<List<Interceptor>> dioInterceptorsProvider =
    Provider<List<Interceptor>>(
      (Ref ref) => <Interceptor>[ref.watch(authInterceptorProvider)],
      name: 'dioInterceptorsProvider',
    );

/// The shared [Dio], built once from `appConfigProvider` with [createDio].
/// Never changed after it is built.
final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final Dio dio = createDio(
    config.apiBaseUrl,
    reporter: ref.watch(errorReporterProvider),
    interceptors: ref.watch(dioInterceptorsProvider),
    headers: <String, String>{
      if (config.apiKey.isNotEmpty) 'x-api-key': config.apiKey,
    },
    logRequests: config.flavor != Flavor.prod,
  );
  ref.onDispose(dio.close);
  return dio;
}, name: 'dioProvider');

const String _startedAtKey = 'core.breadcrumb.startedAt';

/// Adds one breadcrumb per request: method, normalized path, status and
/// duration. A retried request leaves one per attempt.
class BreadcrumbInterceptor extends Interceptor {
  BreadcrumbInterceptor(this._reporter);

  final ErrorReporter _reporter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _add(response.requestOptions, response.statusCode, null);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _add(err.requestOptions, err.response?.statusCode, err.type);
    handler.next(err);
  }

  void _add(RequestOptions options, int? status, DioExceptionType? failure) {
    final Object? startedAt = options.extra[_startedAtKey];
    final int? durationMs = startedAt is DateTime
        ? DateTime.now().difference(startedAt).inMilliseconds
        : null;
    final String method = options.method.toUpperCase();
    final String path = normalizeRequestPath(options.uri);
    _reporter.addBreadcrumb(
      '$method $path ${status ?? failure?.name ?? '-'}',
      category: 'http',
      level: failure == null ? BreadcrumbLevel.info : BreadcrumbLevel.warning,
      data: <String, Object?>{
        'method': method,
        'path': path,
        'status': status,
        'duration_ms': durationMs,
      },
    );
  }
}

/// Logs every request and response to `Logger('network')` at `FINE`, with
/// [redactedHeaders] replaced by `<redacted>`. Bodies are logged; `FINE` is
/// below the breadcrumb floor, so they never reach the error tracker.
class RedactedLogInterceptor extends Interceptor {
  const RedactedLogInterceptor();

  static final Logger _log = Logger('network');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_log.isLoggable(Level.FINE)) {
      _log.fine(
        '--> ${options.method} ${options.uri}\n'
        'headers: ${redactHeaders(options.headers)}'
        '${options.data == null ? '' : '\nbody: ${options.data}'}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (_log.isLoggable(Level.FINE)) {
      _log.fine(
        '<-- ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}\nbody: ${response.data}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_log.isLoggable(Level.FINE)) {
      _log.fine(
        '<-- ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.method} ${err.requestOptions.uri}'
        '${err.response?.data == null ? '' : '\nbody: ${err.response?.data}'}',
      );
    }
    handler.next(err);
  }
}

/// [headers] with every [redactedHeaders] value replaced by `<redacted>`.
Map<String, Object?> redactHeaders(Map<String, Object?> headers) {
  return <String, Object?>{
    for (final MapEntry<String, Object?> entry in headers.entries)
      entry.key: redactedHeaders.contains(entry.key.toLowerCase())
          ? '<redacted>'
          : entry.value,
  };
}
