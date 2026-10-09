import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';

import '../permissions/permissions_service.dart';
import '../reporting/error_reporter.dart';
import 'api_exception.dart';
import 'base_response.dart';
import 'request_path.dart';

/// The response header holding the backend's request id. Override to match
/// your backend.
final Provider<String> requestIdHeaderProvider = Provider<String>(
  (Ref ref) => 'X-Request-Id',
  name: 'requestIdHeaderProvider',
);

/// Core's wrapper around every backend call: `apiCall(() => client.login(r))`.
///
/// Read it from [apiCallProvider] and pass it to a Feature's repository.
final Provider<ApiCall> apiCallProvider = Provider<ApiCall>(
  (Ref ref) => ApiCall(
    ref.watch(errorReporterProvider),
    requestIdHeader: ref.watch(requestIdHeaderProvider),
    onForbidden: () =>
        ref.read(permissionsServiceProvider).reloadAfterForbidden(),
  ),
  name: 'apiCallProvider',
);

/// Pass to a retrofit client (`errorLogger: apiParseErrorLogger`) so a
/// decode failure keeps its method, path and status.
const ParseErrorLogger apiParseErrorLogger = _ApiParseErrorLogger();

typedef _DecodeContext = ({
  RequestOptions options,
  Response<dynamic>? response,
});

// Retrofit logs a parse error and rethrows it. The logger is the only place
// that sees the request, so it is attached to the error object here and
// looked up again by ApiCall.
final Expando<_DecodeContext> _decodeContexts = Expando<_DecodeContext>(
  'decodeContext',
);

class _ApiParseErrorLogger implements ParseErrorLogger {
  const _ApiParseErrorLogger();

  @override
  void logError(
    Object error,
    StackTrace stackTrace,
    RequestOptions options, {
    Response<dynamic>? response,
  }) {
    // Strings, numbers, booleans and records can't carry an Expando value.
    if (error is String || error is num || error is bool || error is Record) {
      return;
    }
    _decodeContexts[error] = (options: options, response: response);
  }
}

/// Maps every failure of a backend call to an [ApiException] and reports it.
///
/// - [call] runs a request whose method returns the model directly.
/// - [unwrap] runs a request returning `BaseResponse<T>` and applies the
///   envelope's unwrap rule.
///
/// Reporting happens here and only here, after mapping; retries already
/// happened inside Dio, so a 5xx retried three times is one report:
/// - `server`, `notFound`, `decode` and `unknown` are reported (non-fatal)
///   once per launch per method, normalized path and status; repeats become
///   breadcrumbs. Reports carry the group key `<method> <path> <status>`,
///   tags `http.method` / `http.path` / `http.status` and extra
///   `errorMessage` / `requestId`. Never bodies, headers or query values.
/// - Every other kind becomes a breadcrumb only.
class ApiCall {
  ApiCall(
    this._reporter, {
    this.requestIdHeader = 'X-Request-Id',
    this.onForbidden,
  });

  final ErrorReporter _reporter;

  /// The response header holding the backend's request id.
  final String requestIdHeader;

  /// Called for each [ApiForbiddenException]. [apiCallProvider] passes the
  /// permission service's reload (at most once per launch).
  final void Function()? onForbidden;

  final Set<String> _reported = <String>{};
  final Expando<bool> _handled = Expando<bool>('handled');

  /// Runs [request], turning any failure into an [ApiException].
  Future<T> call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (error, stackTrace) {
      final ApiException mapped = map(error);
      if (_handled[mapped] == null) {
        _handled[mapped] = true;
        _record(mapped, stackTrace);
        if (mapped is ApiForbiddenException) onForbidden?.call();
      }
      Error.throwWithStackTrace(mapped, stackTrace);
    }
  }

  /// Runs [request] and returns its envelope's data, or throws
  /// [ApiBusinessException] when the envelope says it failed.
  Future<T> unwrap<T>(Future<BaseResponse<T>> Function() request) {
    return call<T>(() async => (await request()).unwrap());
  }

  /// Maps [error] to its [ApiException] kind.
  ApiException map(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return _mapDio(error);
    final _DecodeContext? context = _decodeContexts[error];
    if (context != null) {
      return ApiDecodeException(
        request: _info(context.options, context.response),
        cause: error,
      );
    }
    if (error is FormatException ||
        error is TypeError ||
        error is CheckedFromJsonException) {
      return ApiDecodeException(cause: error);
    }
    return ApiUnknownException(cause: error);
  }

  ApiException _mapDio(DioException error) {
    final Response<dynamic>? response = error.response;
    final ApiRequestInfo request = _info(error.requestOptions, response);
    switch (error.type) {
      case DioExceptionType.cancel:
        return ApiCancelledException(request: request, cause: error);
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiTimeoutException(request: request, cause: error);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return ApiConnectionException(request: request, cause: error);
      case DioExceptionType.badResponse:
        final int? status = response?.statusCode;
        final String? message = envelopeErrorMessage(response?.data);
        return switch (status) {
          401 => ApiUnauthorizedException(
            message: message,
            request: request,
            cause: error,
          ),
          403 => ApiForbiddenException(
            message: message,
            request: request,
            cause: error,
          ),
          404 => ApiNotFoundException(
            message: message,
            request: request,
            cause: error,
          ),
          final int code => ApiServerException(
            code,
            message: message,
            request: request,
            cause: error,
          ),
          null => ApiUnknownException(request: request, cause: error),
        };
      case DioExceptionType.unknown:
        // Already mapped, for example a failed token refresh made through
        // apiCall and passed on to the requests waiting for it.
        if (error.error case final ApiException mapped) return mapped;
        if (error.error is FormatException) {
          return ApiDecodeException(request: request, cause: error);
        }
        return ApiUnknownException(request: request, cause: error);
    }
  }

  ApiRequestInfo _info(RequestOptions options, Response<dynamic>? response) {
    return ApiRequestInfo(
      method: options.method.toUpperCase(),
      path: normalizeRequestPath(options.uri),
      statusCode: response?.statusCode,
      requestId: response?.headers.value(requestIdHeader),
    );
  }

  void _record(ApiException error, StackTrace stackTrace) {
    final ApiRequestInfo request =
        error.request ?? const ApiRequestInfo(method: '?', path: '?');
    final String groupKey = request.toString();
    final String status = request.statusCode?.toString() ?? '-';
    if (error.isReported && _reported.add(groupKey)) {
      _reporter.report(
        error,
        stackTrace,
        groupKey: groupKey,
        tags: <String, String>{
          'http.method': request.method,
          'http.path': request.path,
          'http.status': status,
        },
        extra: <String, Object?>{
          'errorMessage': error.message,
          'requestId': request.requestId,
        },
      );
      return;
    }
    _reporter.addBreadcrumb(
      'API error ${error.kind}: $groupKey',
      category: 'http',
      level: BreadcrumbLevel.warning,
      data: <String, Object?>{
        'kind': error.kind,
        'method': request.method,
        'path': request.path,
        'status': request.statusCode,
      },
    );
  }
}
